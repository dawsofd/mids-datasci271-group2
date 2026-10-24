
# Model 1: Random Walk (without drift)
model_rw <- function(train) {
  stopifnot(nrow(train) > 0, all(is.finite(train$infl)))

  # Extract the most recent observed inflation value (origin T)
  last_infl <- tail(train$infl, 1)

  # Return point forecasts for key horizons
  tibble::tibble(
    h = c(1L, 4L, 8L),
    forecast = rep(last_infl, 3)
  )
}

# Model 2: Four-Quarter-Average Benchmark
model_4q <- function(train) {
  stopifnot(nrow(train) >= 4, all(is.finite(train$infl)))

  # Extract the 4 most recently observed inflation values
  mean_4q <- mean(tail(train$infl, 4))

  # Return point forecasts for key horizons
  tibble::tibble(
    h = c(1L, 4L, 8L),
    forecast = rep(mean_4q, 3)
  )
}
