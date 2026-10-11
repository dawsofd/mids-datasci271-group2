# models_direct.R
# Owner: Odysseus. Models 4 and 7 (project guide Stage 2, Step 3).
# Interface: see 02_harness.R. Each model_* function takes `train` (data through
# origin T) and returns tibble(h, forecast) for h = 1, 4, 8.
# Estimated models also export fit_*(train, h) for Step 5; see 02_harness.R for its return value.
#
# Direct models estimate a separate equation for each horizon. Only h = 1, 4, 8
# are needed, so these functions can return a 3-row tibble(h = c(1, 4, 8), forecast).

# Model 4: direct AR. pi_{t+h} = c_h + sum_{j=0}^{p_h-1} phi_{h,j} pi_{t-j} + e.
# Rows used at origin T: only those with t + h <= T. p_h in 1:4 by BIC.
fit_direct_ar <- function(train, h) {
  stop("TODO (Odysseus): implement fit_direct_ar")
}
model_direct_ar <- function(train) {
  stop("TODO (Odysseus): implement model_direct_ar")
}

# Model 7: direct Phillips curve. Same as Model 4 plus lambda_h * u_t (UNRATE at t).
fit_phillips <- function(train, h) {
  stop("TODO (Odysseus): implement fit_phillips")
}
model_phillips <- function(train) {
  stop("TODO (Odysseus): implement model_phillips")
}
