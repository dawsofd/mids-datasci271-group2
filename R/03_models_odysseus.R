# Stage 2 models 4 and 7: direct AR and direct Phillips curve.
# Each function receives only the expanding training sample from the harness.

fit_direct <- function(train, h, unemployment = FALSE) {
  n <- nrow(train)
  stopifnot(n > h + 8, all(is.finite(train$infl)))
  if (unemployment) stopifnot(all(is.finite(train$unrate)))

  # A row dated t predicts inflation at t+h, which must already be observed.
  t <- seq_len(n - h)
  d <- data.frame(y = train$infl[t + h])
  for (j in 0:3) {
    d[[paste0("infl", j)]] <- c(rep(NA_real_, j), train$infl)[t]
  }
  if (unemployment) d$unrate <- train$unrate[t]

  formulas <- lapply(1:4, function(p) {
    terms <- paste0("infl", 0:(p - 1))
    if (unemployment) terms <- c(terms, "unrate")
    reformulate(terms, response = "y")
  })
  # All four BIC candidates use the same response rows (t = 4,...,n-h).
  common <- d[4:nrow(d), , drop = FALSE]
  candidates <- lapply(formulas, function(f) lm(f, data = common))
  bic <- vapply(candidates, BIC, numeric(1))
  p <- which.min(bic)

  # Refit the chosen order using every row available for that order.
  fit <- lm(formulas[[p]], data = d[p:nrow(d), , drop = FALSE])
  latest <- as.data.frame(as.list(setNames(train$infl[n - 0:3],
                                          paste0("infl", 0:3))))
  if (unemployment) latest$unrate <- train$unrate[n]
  list(forecast = as.numeric(predict(fit, newdata = latest)),
       p = p, bic = bic, fit = fit)
}

direct_ar_model <- function(train) {
  h <- c(1L, 4L, 8L)
  tibble::tibble(h = h, forecast = vapply(h, function(k) {
    fit_direct(train, k)$forecast
  }, numeric(1)))
}

phillips_model <- function(train) {
  h <- c(1L, 4L, 8L)
  tibble::tibble(h = h, forecast = vapply(h, function(k) {
    fit_direct(train, k, unemployment = TRUE)$forecast
  }, numeric(1)))
}
