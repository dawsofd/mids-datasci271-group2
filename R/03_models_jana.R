# R/02_harness.R:
#   model_fn(train) -> tibble(h, forecast)
# where `train` has columns (qtr, infl, unrate, tbill) through forecast origin T.

library(dplyr)
library(tibble)


### Helper Function: Fit different orders of AR models and select the best candidate based on mid BIC
# Estimates y_t = c + sum_{j=1}^p phi_j y_{t-j} + eps_t for p in 1:max_p.
# Candidate orders p in 1:4 are compared via BIC on a common sample (starting at
# t = max_p + 1), then the selected order is refit on all rows available for that p.
fit_ar_ols <- function(y, qtr, max_p = 4) {
  n <- length(y)
  stopifnot(n > max_p + 4, all(is.finite(y))) # check for enough data in series and data is valid

  # Reformats the data to allow for common sample evaluation for valid BIC model selection
  # accounts for the difference in lags needed for each model
  idx_common <- (max_p + 1):n
  d_common <- data.frame(y = y[idx_common])
  for (j in 1:max_p) {
    d_common[[paste0("lag", j)]] <- y[idx_common - j]
  }

  bics <- numeric(max_p)
  models_common <- list()
  for (p in 1:max_p) {
    terms <- paste0("lag", 1:p)
    m <- lm(reformulate(terms, response = "y"), data = d_common)
    bics[p] <- BIC(m)
    models_common[[p]] <- m
  }
  best_p <- which.min(bics)

  # Refit selected order using all available historical rows for that p
  # before only used common data to allow for fair comparison
  idx_fit <- (best_p + 1):n
  d_fit <- data.frame(y = y[idx_fit])
  for (j in 1:best_p) {
    d_fit[[paste0("lag", j)]] <- y[idx_fit - j]
  }
  final_model <- lm(reformulate(paste0("lag", 1:best_p), response = "y"), data = d_fit)

  resid_df <- tibble(
    qtr = qtr[idx_fit],
    resid = as.numeric(residuals(final_model))
  )

  list(
    fit = final_model,
    p = best_p,
    bics = bics,
    resid = resid_df
  )
}

### Helper Function: Multi-step iterated point forecast
# y_hat_{T+k|T} = c + sum_{j=1}^p phi_j * y_{T+k-j|T}
# where y_{T+k-j|T} uses actual data if (k - j <= 0) and previous forecasts if (k - j > 0).
forecast_iterative_ar <- function(y, fit, p, h_max = 8) {
  coefs <- coef(fit)
  c_const <- coefs[1]
  phi <- coefs[-1]

  fc <- numeric(h_max)
  y_ext <- y

  # calculate the forecast for all horizons up to h_max
  for (k in 1:h_max) {
    lags <- rev(tail(y_ext, p))
    y_next <- c_const + sum(phi * lags)
    fc[k] <- y_next
    y_ext <- c(y_ext, y_next)
  }
  fc
}


### 4.4.3 Model 3: AR(p) Model
# Equation: pi_t = c + sum_{j=1}^p phi_j * pi_{t-j} + eps_t
# Order p in {1, 2, 3, 4} selected by BIC at each origin.
# Forecasts generated iteratively through 8 quarters.

# Function to fit the best model with order p for Model 3
fit_ar <- function(train) {
  fit_ar_ols(train$infl, train$qtr, max_p = 4)
}

# Create optimal model object for model 3
model_ar <- function(train) {
  fit_obj <- fit_ar(train)
  fc <- forecast_iterative_ar(train$infl, fit_obj$fit, fit_obj$p, h_max = 8)
  tibble(h = 1:8, forecast = fc)
}


### 4.4.5 Local Mean via Simple Exponential Smoothing (SES)
# Weights: 95% previous local mean, 5% current inflation (alpha = 0.05).
# Strictly one-sided: tau_T uses no inflation observation after origin T.
# Gap: g_t = pi_t - tau_t.
calc_local_mean <- function(infl, alpha = 0.05) {
  n <- length(infl)
  tau <- numeric(n)
  tau[1] <- infl[1]
  for (t in 2:n) {
    tau[t] <- (1 - alpha) * tau[t - 1] + alpha * infl[t]
  }
  tau
}



### 4.4.6 Model 5: Gap AR Model
# Local mean: tau_t = 0.95 * tau_{t-1} + 0.05 * pi_t
# Inflation gap: g_t = pi_t - tau_t
# Model: g_t = a + sum_{j=1}^p rho_j * g_{t-j} + v_t, p in {1,2,3,4} by BIC.
# Forecast: pi_hat_{T+h|T} = tau_T + g_hat_{T+h|T}

# Function to fit the best model with order p for Model 4 using the smoothing of the local mean to calculate the gap
fit_gap_ar <- function(train) {
  tau <- calc_local_mean(train$infl, alpha = 0.05)
  gap <- train$infl - tau
  fit_ar_ols(gap, train$qtr, max_p = 4)
}

model_gap_ar <- function(train) {
  tau <- calc_local_mean(train$infl, alpha = 0.05)
  gap <- train$infl - tau
  tau_T <- tail(tau, 1)

  fit_obj <- fit_ar_ols(gap, train$qtr, max_p = 4)
  fc_gap <- forecast_iterative_ar(gap, fit_obj$fit, fit_obj$p, h_max = 8)
  tibble(h = 1:8, forecast = tau_T + fc_gap)
}


### 4.4.7 Model 6: Fixed-Persistence Gap Forecast
# Restricted specification with fixed persistence = 0.46 (not estimated):
# pi_hat_{T+h|T} = tau_T + (0.46^h) * g_T

model_gap_fixed <- function(train) {
  tau <- calc_local_mean(train$infl, alpha = 0.05)
  tau_T <- tail(tau, 1)
  g_T <- tail(train$infl, 1) - tau_T

  h <- 1:8
  fc <- tau_T + (0.46^h) * g_T
  tibble(h = h, forecast = fc)
}
