# 02_harness.R
# Evaluation harness for the expanding-window forecast experiment
# (project guide Stage 2, Step 2).
#
# A model is a function of one argument:
#   model_fn(train) -> tibble(h, forecast)
# where `train` holds every quarter from 1960 Q1 through the forecast origin
# (columns qtr, infl, unrate, tbill) and the result has forecasts for at
# least h = 1, 4, 8. The model must use only `train`.

HORIZONS <- c(1, 4, 8)

# stop with a clear message if a model's output is malformed
check_forecast <- function(fc, model, origin) {
  where <- paste0("model '", model, "' at origin ", format(origin))
  if (!all(c("h", "forecast") %in% names(fc)))
    stop(where, ": must return columns h and forecast")
  if (!all(HORIZONS %in% fc$h))
    stop(where, ": must return forecasts for h = 1, 4, 8")
  if (any(!is.finite(fc$forecast[fc$h %in% HORIZONS])))
    stop(where, ": returned a missing or infinite forecast")
}

# run every model at every origin; return forecasts, actuals, and errors
run_harness <- function(data, models, horizons = HORIZONS,
                        first_origin = "1999 Q4", last_target = "2019 Q4") {
  d <- data |> as_tibble() |> select(qtr, infl, unrate, tbill)
  first_origin <- yearquarter(first_origin)
  last_target  <- yearquarter(last_target)

  # every origin x horizon whose target is on or before the last target
  design <- d |>
    filter(qtr >= first_origin, qtr < last_target) |>
    select(origin = qtr) |>
    tidyr::crossing(h = horizons) |>
    mutate(target = origin + h) |>
    filter(target <= last_target)

  # at each origin, each model sees only data through that origin
  forecasts <- lapply(unique(design$origin), function(T0) {
    train <- d |> filter(qtr <= T0)
    lapply(names(models), function(m) {
      fc <- models[[m]](train)
      check_forecast(fc, m, T0)
      fc |> mutate(origin = T0, model = m)
    }) |> bind_rows()
  }) |> bind_rows()

  # attach realized inflation after forecasting; error = actual - forecast
  design |>
    left_join(forecasts, by = c("origin", "h")) |>
    left_join(d |> select(target = qtr, actual = infl), by = "target") |>
    mutate(error = actual - forecast) |>
    select(model, origin, h, target, forecast, actual, error)
}

# check 1: 80 / 77 / 73 errors per model at h = 1 / 4 / 8
check_counts <- function(results) {
  counts <- results |> count(model, h)
  expected <- c(`1` = 80L, `4` = 77L, `8` = 73L)
  stopifnot(all(counts$n == expected[as.character(counts$h)]))
  counts
}

# check 2: a model's forecasts do not change when data after the origin
# are scrambled, so it cannot be using future information
check_no_lookahead <- function(data, model, cutoff = "2009 Q4") {
  cutoff <- yearquarter(cutoff)
  d <- data |> as_tibble() |> select(qtr, infl, unrate, tbill)
  scrambled <- d |> mutate(across(c(infl, unrate, tbill),
                                  \(x) if_else(qtr > cutoff, 999, x)))
  original  <- run_harness(d,         list(m = model), last_target = format(cutoff))
  perturbed <- run_harness(scrambled, list(m = model), last_target = format(cutoff))
  all(original$forecast == perturbed$forecast)
}
