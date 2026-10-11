# models_benchmarks.R
# Owner: Chandra. Models 1-2 (project guide Stage 2, Step 3).
# Interface: see 02_harness.R. Each function takes `train` (data through origin T)
# and returns tibble(h = 1:8, forecast = ...).
# Only h = 1, 4, 8 are kept, but iterated models naturally produce all eight.

# Model 1: random walk without drift. Forecast = pi_T at every horizon.
model_rw <- function(train) {
  stop("TODO (Chandra): implement model_rw")
}

# Model 2: four-quarter-average benchmark (used for relative RMSE).
# Forecast = mean of pi_T, pi_{T-1}, pi_{T-2}, pi_{T-3} at every horizon.
model_4q <- function(train) {
  stop("TODO (Chandra): implement model_4q")
}
