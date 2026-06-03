#' Run full analysis pipeline
#' @param config_path Path to scenarios.yml
#' @return List with results, models, and figure paths
run_full_analysis <- function(config_path = NULL) {
  # Resolve root before sourcing (project_root lives in load_data.R)
  root <- Sys.getenv("UBI_AI_ROOT", unset = NA)
  if (is.na(root) || !dir.exists(root)) {
    root <- if (file.exists("scenarios.yml")) normalizePath(".") else normalizePath("..")
  }
  Sys.setenv(UBI_AI_ROOT = root)

  source(file.path(root, "R/load_data.R"))
  root <- project_root()
  source(file.path(root, "R/welfare.R"))
  source(file.path(root, "R/methods_did.R"))
  source(file.path(root, "R/methods_ml.R"))
  source(file.path(root, "R/plot_results.R"))
  source(file.path(root, "R/theme_econ.R"))

  dir.create(file.path(root, "output"), showWarnings = FALSE)
  dir.create(file.path(root, "output/figures"), showWarnings = FALSE)

  if (!file.exists(file.path(root, "data/synthetic_households.rds"))) {
    message("Building data...")
    old_wd <- getwd()
    setwd(root)
    source("R/build_data.R")
    setwd(old_wd)
  }

  config <- if (is.null(config_path)) load_config() else load_config(config_path)
  data <- load_household_data()

  message("Running scenario grid...")
  results <- run_scenario_grid(config = config, data = data)

  message("Running DiD template...")
  did <- run_did_analysis()

  message("Running synthetic control template...")
  sc <- run_synthetic_control()

  message("Running ML welfare prediction...")
  ml <- run_ml_welfare_prediction(data, ubi_monthly = 1000, scenario = "misaligned_automation", config = config)

  message("Running sensitivity grid...")
  sensitivity <- run_sensitivity_grid(config = config, data = data)

  message("Generating figures...")
  fig_dir <- file.path(root, "output/figures")
  figs <- list(
    heatmap = plot_scenario_heatmap(results, output_dir = fig_dir),
    poverty = plot_poverty_by_scenario(results, output_dir = fig_dir),
    decile = plot_decile_gains(data, config = config, output_dir = fig_dir),
    did = plot_did_event_study(did, output_dir = fig_dir),
    sc = plot_synthetic_control(sc, output_dir = fig_dir),
    ml = plot_ml_importance(ml, output_dir = fig_dir),
    sensitivity = plot_sensitivity_heatmap(sensitivity, output_dir = fig_dir)
  )

  saveRDS(results, file.path(root, "output/scenario_results.rds"))
  saveRDS(sensitivity, file.path(root, "output/sensitivity_results.rds"))
  saveRDS(list(did = did, sc = sc, ml = ml), file.path(root, "output/methods_results.rds"))
  readr::write_csv(results, file.path(root, "output/scenario_results.csv"))
  readr::write_csv(sensitivity, file.path(root, "output/sensitivity_results.csv"))

  message("Analysis complete.")
  list(
    config = config,
    data = data,
    results = results,
    sensitivity = sensitivity,
    did = did,
    sc = sc,
    ml = ml,
    figures = figs
  )
}
