#' Get project root directory
project_root <- function() {
  candidates <- c(
    Sys.getenv("UBI_AI_ROOT"),
    if (file.exists("scenarios.yml")) normalizePath("."),
    if (file.exists("../scenarios.yml")) normalizePath(".."),
    if (file.exists("../../scenarios.yml")) normalizePath("../..")
  )
  candidates <- candidates[nzchar(candidates) & dir.exists(candidates)]
  for (c in candidates) {
    if (file.exists(file.path(c, "scenarios.yml"))) return(c)
  }
  normalizePath(".")
}

#' Load project configuration
#' @param path Path to scenarios.yml
#' @return Named list of configuration
load_config <- function(path = NULL) {
  if (is.null(path)) path <- file.path(project_root(), "scenarios.yml")
  if (!requireNamespace("yaml", quietly = TRUE)) {
    install.packages("yaml", repos = "https://cloud.r-project.org")
  }
  yaml::read_yaml(path)
}

#' Load household microdata (synthetic fallback or RDS cache)
#' @param use_synthetic Force synthetic data
#' @return Tibble with household-level variables
load_household_data <- function(use_synthetic = TRUE) {
  root <- project_root()
  rds_path <- file.path(root, "data/synthetic_households.rds")
  if (file.exists(rds_path)) {
    return(readRDS(rds_path))
  }
  csv_path <- file.path(root, "data/synthetic_households.csv")
  if (file.exists(csv_path)) {
    return(readr::read_csv(csv_path, show_col_types = FALSE))
  }
  if (use_synthetic) {
    build_script <- file.path(root, "R/build_data.R")
    if (file.exists(build_script)) {
      old_wd <- getwd()
      on.exit(setwd(old_wd), add = TRUE)
      setwd(root)
      source(build_script, local = TRUE)
    }
    return(readRDS(rds_path))
  }
  stop("No household data found. Run: make data")
}

#' Load occupation AI exposure data
load_occupation_exposure <- function() {
  root <- project_root()
  rds_path <- file.path(root, "data/occupation_ai_exposure.rds")
  if (file.exists(rds_path)) return(readRDS(rds_path))
  readr::read_csv(file.path(root, "data/occupation_ai_exposure.csv"), show_col_types = FALSE)
}

#' Load DiD template panel
load_did_panel <- function() {
  root <- project_root()
  rds_path <- file.path(root, "data/did_template_panel.rds")
  if (file.exists(rds_path)) return(readRDS(rds_path))
  readr::read_csv(file.path(root, "data/did_template_panel.csv"), show_col_types = FALSE)
}

#' Load synthetic control template panel
load_sc_panel <- function() {
  root <- project_root()
  rds_path <- file.path(root, "data/synthetic_control_panel.rds")
  if (file.exists(rds_path)) return(readRDS(rds_path))
  readr::read_csv(file.path(root, "data/synthetic_control_panel.csv"), show_col_types = FALSE)
}
