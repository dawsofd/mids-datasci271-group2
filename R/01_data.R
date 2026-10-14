# 01_data.R
# Builds the shared quarterly dataset used by every Stage 2 model.
# Owner: Dawson. Do not change these rules without group agreement.
#
# Rules (project guide Stage 1 Step 3, plus Stage 1 decisions):
#   - Raw data: course repo CSVs in data/, unchanged (FRED monthly).
#   - Monthly to quarterly: keep the quarter-end month (Mar, Jun, Sep, Dec).
#   - A quarter is dropped only if its quarter-end value is missing.
#     A missing non-end month (October 2025) does not affect any quarter.
#   - No interpolation or infill.
#   - Inflation: pi_t = 400 * log(P_t / P_{t-1}), P_t = end-of-quarter CPI.
#   - December 1959 CPI is the base for 1960Q1 inflation; 1959Q4 is then dropped.
#   - UNRATE and TB3MS are end-of-quarter levels in percent.

library(fpp3)
library(readr)

read_fred_csv <- function(code, data_dir = "data") {
  raw <- read_csv(file.path(data_dir, paste0(code, ".csv")),
                  col_types = cols(.default = col_character()))
  names(raw) <- c("date", "value")
  raw |>
    mutate(date = as.Date(date),
           # blank or "." -> NA
           value = suppressWarnings(as.numeric(value)),
           code = code)
}

load_quarterly <- function(data_dir = "data") {
  monthly <- lapply(c("CPIAUCSL", "UNRATE", "TB3MS"), read_fred_csv, data_dir = data_dir) |>
    bind_rows() |>
    filter(date >= as.Date("1959-12-01"))

  quarterly <- monthly |>
    # quarter-end months only
    filter(as.integer(format(date, "%m")) %in% c(3, 6, 9, 12)) |>
    mutate(qtr = yearquarter(date)) |>
    select(qtr, code, value) |>
    pivot_wider(names_from = code, values_from = value) |>
    rename(cpi = CPIAUCSL, unrate = UNRATE, tbill = TB3MS) |>
    # drop incomplete quarters
    filter(!is.na(cpi), !is.na(unrate), !is.na(tbill)) |>
    as_tsibble(index = qtr)

  # lag() uses the previous row, which is the previous quarter only if there are no gaps
  stopifnot(!has_gaps(quarterly)$.gaps)

  quarterly <- quarterly |>
    mutate(infl = 400 * log(cpi / lag(cpi))) |>
    # 1959Q4 was the base only
    filter(qtr >= yearquarter("1960 Q1")) |>
    mutate(period = case_when(
      qtr <= yearquarter("1999 Q4") ~ "estimation",
      qtr <= yearquarter("2019 Q4") ~ "selection",
      TRUE ~ "evaluation")) |>
    select(qtr, infl, unrate, tbill, cpi, period)

  # sanity checks against Stage 1
  stopifnot(
    # 1960Q1 to 1999Q4
    sum(quarterly$period == "estimation") == 160,
    # 2000Q1 to 2019Q4
    sum(quarterly$period == "selection") == 80,
    # Dec 1959 = Mar 1960 = 29.41
    quarterly$infl[1] == 0,
    # 1960Q2 hand check
    abs(quarterly$infl[2] - 400 * log(29.61 / 29.41)) < 1e-10,
    !anyNA(quarterly$infl)
  )
  quarterly
}
