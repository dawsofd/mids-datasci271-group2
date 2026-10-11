# 04_diagnostics.R
# Owner: Dawson. Step 5 (project guide Stage 2): diagnose the leading one-step model.
#
# Among the estimated core models (AR(p), direct AR, gap AR, Phillips curve), pick
# the lowest h = 1 RMSE, refit it on data through 2019Q4, and examine its residual
# time plot, residual ACF, Ljung-Box test, and residual variability.

library(slider)
library(patchwork)

ESTIMATED_MODELS <- c("AR(p)", "Direct AR", "Gap AR", "Phillips curve")

# lowest h = 1 RMSE among the estimated models
# eval_table: output of evaluate_forecasts(), with columns model, h, rmse
select_best_h1 <- function(eval_table, candidates = ESTIMATED_MODELS) {
  eval_table |>
    filter(h == 1, model %in% candidates) |>
    slice_min(rmse, n = 1, with_ties = FALSE) |>
    pull(model)
}

# refit through 2019Q4 using the owner's fit function
# fit_fns: named list, model name -> function(train) returning list(fit, p, resid)
refit_through_2019 <- function(data, model, fit_fns) {
  train <- as_tibble(data) |>
    filter(qtr <= yearquarter("2019 Q4")) |>
    select(qtr, infl, unrate, tbill)
  out <- fit_fns[[model]](train)
  stopifnot(all(c("fit", "p", "resid") %in% names(out)),
            all(c("qtr", "resid") %in% names(out$resid)))
  out
}

# residual checks; resid is tibble(qtr, resid), p is the number of AR lags
diagnose_residuals <- function(resid, p, label = "", lb_lag = 8, window = 20) {
  r <- resid |>
    as_tsibble(index = qtr) |>
    mutate(roll_sd = slide_dbl(resid, sd, .before = window - 1, .complete = TRUE))

  # 1. residual time plot with trailing SD band
  p_time <- ggplot(r, aes(x = as.Date(qtr), y = resid)) +
    geom_hline(yintercept = 0, color = "gray50") +
    geom_line(color = "gray30") +
    geom_line(aes(y =  2 * roll_sd), color = "#b3452c", linetype = "dashed", na.rm = TRUE) +
    geom_line(aes(y = -2 * roll_sd), color = "#b3452c", linetype = "dashed", na.rm = TRUE) +
    labs(x = NULL, y = "Residual (pp)",
         subtitle = paste0(label, " residuals with trailing ", window,
                           "-quarter +/- 2 SD (red)"))

  # 2. residual ACF
  p_acf <- r |> ACF(resid, lag_max = 20) |> autoplot() +
    labs(subtitle = "Residual ACF")

  # 3. Ljung-Box, degrees of freedom reduced by the p estimated AR coefficients
  lb <- r |> features(resid, ljung_box, lag = lb_lag, dof = p)

  # 4. variability: residual SD by decade and the largest residuals
  by_decade <- r |> as_tibble() |>
    mutate(decade = paste0(floor(as.integer(format(as.Date(qtr), "%Y")) / 10) * 10, "s")) |>
    group_by(decade) |>
    summarize(quarters = n(), sd = sd(resid), max_abs = max(abs(resid)), .groups = "drop")

  largest <- r |> as_tibble() |>
    slice_max(abs(resid), n = 5) |>
    transmute(qtr = format(qtr), resid = round(resid, 2))

  list(plot = p_time / p_acf, ljung_box = lb, by_decade = by_decade,
       largest = largest, overall_sd = sd(r$resid))
}
