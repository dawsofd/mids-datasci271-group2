Odysseus Kaloidas - October 19 team contribution

Contents
- Stage 1 recap and Stage 2 stationarity/setup summary (earlier team deadline).
- Model 4: direct AR, and Model 7: direct Phillips curve.
- Saved forecasts and selected lag orders for the shared expanding-window setup.

This contribution is for the October 19 check-in. It contains no Step 4 accuracy comparison,
benchmark implementation, or other members' model code. It is not the combined
Stage 2 submission.

The model code is in R/03_models_odysseus.R; the report, runner, and saved outputs
are in contributions/odysseus_oct19. The existing R/01_data.R, R/02_harness.R and
instructor data files stay unchanged.

From the team repository root:

  Rscript contributions/odysseus_oct19/run_contribution.R
  quarto render contributions/odysseus_oct19/stage2_oct19_contribution.qmd

Rendering the QMD also runs the model script and reproduces all five output CSVs.
Use the team's setup.R packages, Quarto and a working PDF engine. No downloads
or API keys are needed. Tested against team repository commit d7f346d.

Model integration
After sourcing the shared data loader, harness and R/03_models_odysseus.R:

  q <- load_quarterly()
  models <- list(direct_ar = direct_ar_model, phillips = phillips_model)
  out <- run_harness(q, models)

Each model takes train only and returns h and forecast for h = 1, 4, 8.
Both use separate direct regressions by horizon, an intercept, and BIC lag
selection from 1-4 on common response rows. The selected order is refitted on
all available rows for that order. Phillips adds unemployment at regressor
time t, never at future time t+h.

Outputs
- odysseus_forecasts.csv: 460 rows, 230 per model; standard harness columns
  model, origin, h, target, forecast, actual, error.
- selected_lags.csv: selected inflation lag order for each forecast.
- stationarity_tests.csv: initial-sample tests and first-difference tests.
- forecast_schedule.csv: required origin/target/horizon schedule.
- quarterly_panel_1960_2019.csv: historical panel including outcomes; models
  must use only their training prefix, not this whole panel at each origin.

Both models pass the shared count and no-lookahead checks. There are 80, 77
and 73 forecasts per model at h = 1, 4 and 8, respectively.
