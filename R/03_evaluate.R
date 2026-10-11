# 03_evaluate.R
# Owner: Odysseus. Step 4 (project guide Stage 2).
# Input: `results` from run_harness() with columns
#   origin, target, h, model, forecast, actual, error  (error = actual - forecast)
# Output: one table, one row per model and horizon, with
#   n_h, RMSE, relative RMSE (vs. the 4Q benchmark, model name "4Q average"), MAE, ME.

evaluate_forecasts <- function(results, benchmark = "4Q average") {
  stop("TODO (Odysseus): implement evaluate_forecasts")
}
