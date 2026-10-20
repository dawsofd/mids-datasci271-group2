# Run from the team repository root, or source from the contribution QMD.
source("R/01_data.R")
source("R/02_harness.R")
source("R/03_models_odysseus.R")

q <- load_quarterly()
output_dir <- "contributions/odysseus_oct19/outputs"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

models <- list(direct_ar = direct_ar_model, phillips = phillips_model)
own_forecasts <- run_harness(q, models)
check_counts(own_forecasts)
stopifnot(check_no_lookahead(q, direct_ar_model),
          check_no_lookahead(q, phillips_model))

lag_choices <- lapply(unique(own_forecasts$origin), function(origin) {
  train <- q |> filter(qtr <= origin)
  expand_grid(model = names(models), h = c(1L, 4L, 8L)) |>
    rowwise() |>
    mutate(p = fit_direct(train, h, unemployment = model == "phillips")$p) |>
    ungroup() |>
    mutate(origin = origin, target = origin + h) |>
    filter(target <= yearquarter("2019 Q4"))
}) |> bind_rows()

save_csv <- function(x, name) {
  # Keep quarter labels readable and portable when read back from CSV.
  x <- as_tibble(x)
  for (column in names(x)) {
    if (inherits(x[[column]], "yearquarter")) x[[column]] <- format(x[[column]])
  }
  write.csv(x, file.path(output_dir, name), row.names = FALSE)
}
save_csv(own_forecasts, "odysseus_forecasts.csv")
save_csv(lag_choices, "selected_lags.csv")
