# setup.R
# Installs any packages the project needs that are missing. Run once:
#   source("setup.R")

pkgs <- c(
  # tsibble, feasts, fable, dplyr, tidyr, ggplot2, lubridate
  "fpp3",
  # read the CSVs in data/
  "readr",
  # trailing (one-sided) windows
  "slider",
  # combine plots
  "patchwork",
  # ADF and KPSS tests (Step 1)
  "urca",
  # PELT (Stage 1 break dates)
  "changepoint",
  # structural-change tests
  "strucchange",
  "knitr",
  "kableExtra"
)

missing <- setdiff(pkgs, rownames(installed.packages()))
if (length(missing) > 0) install.packages(missing)

cat("R", R.version$major, ".", R.version$minor, "\n", sep = "")
for (p in pkgs) cat(sprintf("%-12s %s\n", p, as.character(packageVersion(p))))
