# test_harness.R
# Checks the harness with two toy models before any real model plugs in.
# Run from the repo root:  Rscript tests/test_harness.R

source("R/01_data.R")
source("R/02_harness.R")

q <- load_quarterly()
d <- as_tibble(q)

toy <- list(
  last_value = function(train) tibble(h = 1:8, forecast = tail(train$infl, 1)),
  train_size = function(train) tibble(h = c(1, 4, 8), forecast = nrow(train))   # direct-style output
)
res <- run_harness(q, toy)

# 1. error counts and target ranges match the guide (80 / 77 / 73)
print(check_error_counts(res))

# 2. origins run 1999Q4 to 2019Q3, and each target is h quarters after its origin
idx <- function(x) match(format(x), format(d$qtr))
stopifnot(format(min(res$origin)) == "1999 Q4",
          format(max(res$origin)) == "2019 Q3",
          all(idx(res$target) - idx(res$origin) == res$h))

# 3. the model sees data through the origin and nothing after it:
#    train ends exactly at the origin row
ts_rows <- res |> filter(model == "train_size")
stopifnot(all(ts_rows$forecast == idx(ts_rows$origin)))
lv <- res |> filter(model == "last_value")
stopifnot(all(lv$forecast == d$infl[idx(lv$origin)]))

# 4. actuals are attached by target and error = actual - forecast
stopifnot(all(res$actual == d$infl[idx(res$target)]),
          all(abs(res$error - (res$actual - res$forecast)) < 1e-12))

# 5. bad model output is rejected with a clear message
bad <- list(missing_h8 = function(train) tibble(h = 1:7, forecast = 0))
msg <- tryCatch({ run_harness(q, bad); "no error" }, error = conditionMessage)
stopifnot(grepl("must return one forecast", msg))

cat("\nAll harness checks passed:", nrow(res), "rows,",
    length(unique(res$origin)), "origins\n")
