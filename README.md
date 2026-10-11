# W271 Final Project: Stage 2

Group: Chandra, Dawson, Jana, Odysseus. Due Oct. 26, 2026.

## Layout

| Path | What | Owner |
|---|---|---|
| `data/` | Course repo CSVs (FRED monthly, through June 2026). Do not edit. | |
| `R/01_data.R` | Builds the shared quarterly series (`load_quarterly()`) | Dawson |
| `R/02_harness.R` | Expanding-window harness and the model interface | Dawson |
| `R/models_benchmarks.R` | Model 1 random walk, Model 2 4Q average | Chandra |
| `R/models_ar_gap.R` | Model 3 AR(p), local mean, Model 5 gap AR, Model 6 fixed gap | Jana |
| `R/models_direct.R` | Model 4 direct AR, Model 7 Phillips curve | Odysseus |
| `R/03_evaluate.R` | Step 4 metrics table | Odysseus |
| `R/04_diagnostics.R` | Step 5 residual diagnostics | Dawson |
| `stage2.qmd` | The report. Edit only your own sections. | all |
| `tests/test_harness.R` | Harness checks with toy models | Dawson / Chandra |
| `results/forecasts.csv` | Saved forecasts, written when the report renders | |

## Model interface

Every model is a function of one argument:

```r
model_fn(train)  # -> tibble(h, forecast), with at least h = 1, 4, 8
```

- `train` holds every quarter from 1960Q1 through the forecast origin T, sorted, with columns `qtr, infl, unrate, tbill`. The last row is T.
- Use **only** `train`. Build the local mean, gaps, lags, and BIC choices inside the function, so nothing after T can leak in.
- Estimated models (3, 4, 5, 7) also provide `fit_<name>(train)` (direct models: `fit_<name>(train, h)`) returning `list(fit = <lm>, p = <chosen lag>, resid = tibble(qtr, resid))`. Step 5 uses this to refit the best h = 1 model through 2019Q4.

Add your function to the `models` list in the `harness` chunk of `stage2.qmd` (already listed). Models that still `stop("TODO")` are skipped automatically, so the report renders at every stage.

## Workflow

1. `git pull` before you start, and work only in your own R file and report sections.
2. Test your model on one origin first:
   ```r
   source("R/01_data.R"); source("R/02_harness.R"); source("R/models_ar_gap.R")
   q <- load_quarterly()
   train <- q |> as_tibble() |> filter(qtr <= yearquarter("1999 Q4")) |> select(qtr, infl, unrate, tbill)
   model_ar(train)
   ```
3. Run `Rscript tests/test_harness.R` from the repo root after any harness change.
4. Render `stage2.qmd` before pushing to make sure it still builds.

## Data decisions (see the group alignment doc)

End-of-quarter month for all series, inflation = 400 log(P_t / P_{t-1}), December 1959 as the base, drop a quarter only if its quarter-end value is missing, no infill. Estimation 1960Q1-1999Q4, selection 2000Q1-2019Q4.

## Key dates

| Date | Milestone |
|---|---|
| Oct. 13 | Data decisions agreed in the alignment doc |
| Oct. 14 | Step 1 (Chandra), Step 2 harness (Dawson) |
| Oct. 19 | Step 3 models in; check-in meeting 5:30 PM PT |
| Oct. 22 | Step 4 (Odysseus), Step 5 (Dawson), Step 6 (Chandra) |
| Oct. 25 | Final meeting 2 PM PT |
| Oct. 26 | Submit (Chandra) |
