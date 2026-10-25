# Stage 2 Step 4: evaluate the standard table returned by run_harness().
# Works for the complete team output or an explicitly labelled subset.

evaluate_forecasts <- function(results, benchmark = NULL) {
  required <- c("model", "origin", "h", "target", "forecast", "actual", "error")
  stopifnot(all(required %in% names(results)), nrow(results) > 0)
  d <- tibble::as_tibble(results)
  d$origin <- tsibble::yearquarter(d$origin)
  d$target <- tsibble::yearquarter(d$target)
  stopifnot(!anyNA(d[required]),
            all(is.finite(d$forecast)), all(is.finite(d$actual)),
            all(is.finite(d$error)),
            max(abs(d$error - (d$actual - d$forecast))) < 1e-10,
            !anyDuplicated(d[c("model", "origin", "h")]))

  # Require the full course schedule for every included model, not just counts.
  schedule <- tidyr::crossing(
    origin = seq(tsibble::yearquarter("1999 Q4"),
                 tsibble::yearquarter("2019 Q3"), by = 1),
    h = c(1L, 4L, 8L)) |>
    dplyr::mutate(target = origin + h) |>
    dplyr::filter(target <= tsibble::yearquarter("2019 Q4"))
  for (m in unique(d$model)) {
    x <- d[d$model == m, c("origin", "h", "target")]
    if (nrow(x) != nrow(schedule) ||
        nrow(dplyr::anti_join(schedule, x,
                             by = c("origin", "h", "target"))) > 0) {
      stop("Incomplete or mismatched forecast schedule for model: ", m)
    }
  }
  actuals <- d |>
    dplyr::group_by(target) |>
    dplyr::summarise(spread = max(actual) - min(actual), .groups = "drop")
  stopifnot(all(actuals$spread < 1e-10))

  scores <- d |>
    dplyr::group_by(model, h) |>
    dplyr::summarise(n = dplyr::n(), RMSE = sqrt(mean(error^2)),
                     MAE = mean(abs(error)), ME = mean(error), .groups = "drop")
  # A provisional subset has no relative score without the required benchmark.
  scores$relative_RMSE <- NA_real_
  if (!is.null(benchmark)) {
    stopifnot(length(benchmark) == 1L, benchmark %in% d$model)
    reference <- scores |>
      dplyr::filter(model == benchmark) |>
      dplyr::select(h, benchmark_RMSE = RMSE)
    stopifnot(all(reference$benchmark_RMSE > 0))
    scores <- scores |>
      dplyr::left_join(reference, by = "h") |>
      dplyr::mutate(relative_RMSE = RMSE / benchmark_RMSE)
  }
  scores |>
    dplyr::select(model, h, n, RMSE, relative_RMSE, MAE, ME) |>
    dplyr::arrange(h, RMSE)
}

# Command-line mode is for the complete seven-model table.
if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) != 3L) {
    stop("Usage: Rscript R/04_evaluation_odysseus.R forecasts.csv benchmark_label scores.csv")
  }
  forecasts <- read.csv(args[1])
  if (length(unique(forecasts$model)) != 7L) {
    stop("The final Stage 2 table requires all seven core models.")
  }
  scores <- evaluate_forecasts(forecasts, benchmark = args[2])
  write.csv(scores, args[3], row.names = FALSE)
  print(scores)
}
