# Run ensembling methods
# 
# Used to create a single ensemble forecast.
#  Takes a forecast date and loads all forecasts for the preceding week, then:
#  Filters models according to criteria
#  Ensembles forecasts according to given method
#  Formats ensemble forecast
#  Returns ensemble forecast and optionally the criteria for inclusion
# 
# Params:
# method : character L1 : name of an ensembling method
# forecast_date : date or character
# exclude models : character : names of team-models to exclude by forecast_date
# return_criteria : logical : whether to return a model/inclusion criteria grid
#  as well as the ensemble forecast (default TRUE)
# 
# Returns a list or a tibble
# return_criteria = TRUE:
#   "ensemble" : tibble : a single ensemble forecast
#   "criteria": tibble : all candidate models against criteria 
#     for inclusion in ensemble (all locations and horizons)
#   "forecast_date" : date : latest date 
# return_criteria = FALSE:
#   a tibble of a single ensemble forecast

library(here)
library(vroom)
library(lubridate)
library(covidHubUtils)
source(here("code", "ensemble", "utils", "use-ensemble-criteria.R"))
source(here("code", "ensemble", "utils", "format-ensemble.R"))

run_ensemble <- function(method,
                         forecast_date,
                         exclude_models = NULL,
                         return_criteria = TRUE) {

  # determine forecast dates matching the forecast date
  forecast_dates <- seq.Date(from = forecast_date,
                             by = -1,
                             length.out = 6)

  # Load forecasts and save criteria --------------------------------------------
  # Get all forecasts
  all_forecasts <- load_forecasts(source = "local_hub_repo",
                              hub_repo_path = here(),
                              hub = "ECDC",
                              forecast_dates = forecast_dates)
  
  # Filter by inclusion criteria
  forecasts <- use_ensemble_criteria(forecasts = all_forecasts,
                                     exclude_models = exclude_models,
                                     return_criteria = return_criteria)
  
  if (return_criteria) {
    criteria <- forecasts$criteria
    forecasts <- forecasts$forecasts
  }
  
  # Run  ensembles ---------------------------------------------------
  # Averages
  if (method %in% c("mean", "median")) {
    source(here("code", "ensemble", "methods", "create-ensemble-average.R"))
    ensemble <- create_ensemble_average(method = method,
                                        forecasts = forecasts)
  }
  
  # Add other ensemble methods here as:
  #   if (method == "method") {
  #     ensemble <- method_function_call()
  #   } 

# Format and return -----------------------------------------------------------
  ensemble <- format_ensemble(ensemble = ensemble,
                              forecast_date = max(forecast_dates))
  
  if (return_criteria) {
    return(list("ensemble" = ensemble,
                "criteria" = criteria,
                "forecast_date" = max(forecast_dates)))
  }
  
  return(ensemble)

}
