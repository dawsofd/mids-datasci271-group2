# Constant-coefficient VAR(p) model for y_t = (infl, unrate, tbill)'

fit_var <- function(train) {
  y <- as.matrix(train[, c("infl", "unrate", "tbill")])
  n <- nrow(y)
  stopifnot(n >= 10, !anyNA(y))

  # Helper to construct lagged design matrix X and response Y for lag order p
  build_var_matrices <- function(mat, p) {
    T_eff <- nrow(mat) - p
    Y <- mat[(p + 1):nrow(mat), , drop = FALSE]
    X <- matrix(1, nrow = T_eff, ncol = 1 + 3 * p)
    for (j in seq_len(p)) {
      cols <- (2 + 3 * (j - 1)):(1 + 3 * j)
      X[, cols] <- mat[(p + 1 - j):(nrow(mat) - j), , drop = FALSE]
    }
    list(Y = Y, X = X)
  }

  # Evaluate p in 1:4 by multivariate BIC on a common sample (t = 5, ..., T)
  common_idx <- 5:n
  T_common <- length(common_idx)

  bics <- vapply(1:4, function(p) {
    mats <- build_var_matrices(y, p)
    # Restrict to common response rows (t = 5, ..., n)
    keep <- (nrow(mats$Y) - T_common + 1):nrow(mats$Y)
    Y_c <- mats$Y[keep, , drop = FALSE]
    X_c <- mats$X[keep, , drop = FALSE]

    B_hat <- qr.solve(X_c, Y_c)
    E_hat <- Y_c - X_c %*% B_hat
    Sigma_hat <- crossprod(E_hat) / T_common

    # Multivariate Gaussian BIC: log|Sigma| + (log(T) / T) * (number of free parameters)
    k_params <- ncol(X_c) * ncol(Y_c)
    as.numeric(determinant(Sigma_hat, logarithm = TRUE)$modulus) +
      (log(T_common) / T_common) * k_params
  }, numeric(1))

  p_opt <- which.min(bics)

  # Refit selected lag order p_opt on all available rows for that p
  full_mats <- build_var_matrices(y, p_opt)
  B_opt <- qr.solve(full_mats$X, full_mats$Y)
  resid <- full_mats$Y - full_mats$X %*% B_opt

  list(
    p = p_opt,
    B = B_opt,
    y_hist = y,
    resid = resid
  )
}

model_var <- function(train) {
  fit <- fit_var(train)
  p <- fit$p
  B <- fit$B
  y_hist <- fit$y_hist
  n <- nrow(y_hist)

  # Generate iterative forecasts through h = 8
  max_h <- 8
  y_ext <- rbind(y_hist, matrix(NA_real_, nrow = max_h, ncol = 3))

  for (h in seq_len(max_h)) {
    t_idx <- n + h
    x_new <- numeric(1 + 3 * p)
    x_new[1] <- 1
    for (j in seq_len(p)) {
      cols <- (2 + 3 * (j - 1)):(1 + 3 * j)
      x_new[cols] <- y_ext[t_idx - j, ]
    }
    y_ext[t_idx, ] <- as.numeric(x_new %*% B)
  }

  # Retain inflation (column 1) forecasts at horizons h = 1, 4, 8
  horizons <- c(1L, 4L, 8L)
  tibble::tibble(
    h = horizons,
    forecast = y_ext[n + horizons, 1]
  )
}
