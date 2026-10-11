# models_ar_gap.R
# Owner: Jana. Model 3, the local mean, Models 5-6 (project guide Stage 2, Step 3).
# Interface: see 02_harness.R. Each model_* function takes `train` (data through
# origin T) and returns tibble(h = 1:8, forecast = ...).
# Only h = 1, 4, 8 are kept, but iterated models naturally produce all eight.
# Estimated models also export fit_*(train) for Step 5; see 02_harness.R for its return value.

# Model 3: AR(p), p in 1:4 chosen by BIC at each origin, iterated forecasts.
fit_ar <- function(train) {
  stop("TODO (Jana): implement fit_ar")
}
model_ar <- function(train) {
  stop("TODO (Jana): implement model_ar")
}

# Local mean by simple exponential smoothing, alpha = 0.05 (fixed, not estimated).
# tau_1960Q1 = pi_1960Q1; tau_t = 0.95 * tau_{t-1} + 0.05 * pi_t; g_t = pi_t - tau_t.
# Compute from `train` only, so tau_T uses nothing after T.
local_mean <- function(infl, alpha = 0.05) {
  stop("TODO (Jana): implement local_mean")
}

# Model 5: gap AR. AR(p) on g_t, p in 1:4 by BIC, iterated; forecast = tau_T + g_hat.
fit_gap_ar <- function(train) {
  stop("TODO (Jana): implement fit_gap_ar")
}
model_gap_ar <- function(train) {
  stop("TODO (Jana): implement model_gap_ar")
}

# Model 6: fixed-persistence gap. Forecast = tau_T + 0.46^h * g_T (nothing estimated).
model_gap_fixed <- function(train) {
  stop("TODO (Jana): implement model_gap_fixed")
}
