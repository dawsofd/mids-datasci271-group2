# setup.R
# Installs any packages the project needs that are missing. Run once:
#   source("setup.R")

pkgs <- c(
  "fpp3",         # tsibble, feasts, fable, dplyr, tidyr, ggplot2, lubridate
  "readr",        # read the CSVs in data/
  "slider",       # trailing (one-sided) windows
  "patchwork",    # combine plots
  "urca",         # ADF and KPSS tests (Step 1)
  "changepoint",  # PELT (Stage 1 break dates)
  "strucchange",  # structural-change tests
  "knitr",
  "kableExtra"
)

missing <- setdiff(pkgs, rownames(installed.packages()))
if (length(missing) > 0) install.packages(missing)

cat("R", R.version$major, ".", R.version$minor, "\n", sep = "")
for (p in pkgs) cat(sprintf("%-12s %s\n", p, as.character(packageVersion(p))))
