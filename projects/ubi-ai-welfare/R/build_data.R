# Build cached datasets for UBI-AI welfare analysis
# Run: Rscript R/build_data.R  (from project root)

required_pkgs <- c("readr", "dplyr", "yaml")
for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

library(readr)
library(dplyr)
library(yaml)

root <- if (file.exists("scenarios.yml")) {
  normalizePath(".")
} else if (file.exists("../scenarios.yml")) {
  normalizePath("..")
} else {
  stop("Cannot find scenarios.yml. Run from the project root.")
}
setwd(root)

dir.create("data", showWarnings = FALSE, recursive = TRUE)
dir.create("output/figures", showWarnings = FALSE, recursive = TRUE)

set.seed(20240602)

config <- yaml::read_yaml("scenarios.yml")
occ_exposure <- read_csv("data/occupation_ai_exposure.csv", show_col_types = FALSE)

n_households <- 5000
occ_groups <- occ_exposure$occupation_group
occ_shares <- occ_exposure$employment_share
occ_shares <- occ_shares / sum(occ_shares)

synthetic <- tibble(
  household_id = seq_len(n_households),
  adults = sample(1:4, n_households, replace = TRUE, prob = c(0.30, 0.35, 0.25, 0.10)),
  children = sample(0:3, n_households, replace = TRUE, prob = c(0.45, 0.30, 0.15, 0.10)),
  state = sample(state.abb, n_households, replace = TRUE),
  occupation_group = sample(occ_groups, n_households, replace = TRUE, prob = occ_shares),
  market_income = round(rlnorm(n_households, meanlog = log(55000), sdlog = 0.9)),
  weight = runif(n_households, 0.5, 2.0)
) |>
  mutate(
    market_income = pmin(pmax(market_income, 5000), 500000),
    employed = rbinom(n_households, 1, prob = 0.62 + 0.15 * (market_income > 40000)),
    age_head = sample(22:75, n_households, replace = TRUE)
  ) |>
  left_join(
    occ_exposure |> select(occupation_group, ai_exposure, automation_prone, augmentation_prone),
    by = "occupation_group"
  )

write_csv(synthetic, "data/synthetic_households.csv")
saveRDS(synthetic, "data/synthetic_households.rds")
saveRDS(occ_exposure, "data/occupation_ai_exposure.rds")
saveRDS(config, "data/config.rds")

months <- seq(as.Date("2021-01-01"), as.Date("2024-12-01"), by = "month")
did_panel <- expand.grid(
  occupation_group = occ_groups,
  month = months,
  stringsAsFactors = FALSE
) |>
  as_tibble() |>
  left_join(occ_exposure, by = "occupation_group") |>
  mutate(
    post_chatgpt = as.integer(month >= as.Date("2022-11-01")),
    high_exposure = as.integer(ai_exposure >= 0.5),
    treated = high_exposure * post_chatgpt,
    base_employment = 0.60 + 0.10 * augmentation_prone - 0.08 * automation_prone,
    employment_rate = pmin(pmax(
      base_employment
        - 0.02 * treated * automation_prone
        + 0.015 * treated * augmentation_prone
        + rnorm(n(), 0, 0.02),
      0.30
    ), 0.95),
    log_wage = log(45000) + 0.15 * ai_exposure - 0.10 * treated * automation_prone + rnorm(n(), 0, 0.05)
  )

write_csv(did_panel, "data/did_template_panel.csv")
saveRDS(did_panel, "data/did_template_panel.rds")

states <- state.abb
state_years <- expand.grid(state = states, year = 1975:1990, stringsAsFactors = FALSE) |>
  as_tibble() |>
  mutate(
    treated = as.integer(state == "AK" & year >= 1982),
    employment_rate = 0.58 + 0.02 * (state != "AK") + 0.005 * (year - 1975)
      + 0.008 * treated * (year >= 1982)
      + rnorm(n(), 0, 0.015),
    part_time_rate = 0.12 + 0.018 * treated * (year >= 1982) + rnorm(n(), 0, 0.01)
  )

write_csv(state_years, "data/synthetic_control_panel.csv")
saveRDS(state_years, "data/synthetic_control_panel.rds")

message("Data build complete.")
message("  - data/synthetic_households.rds (", nrow(synthetic), " households)")
message("  - data/did_template_panel.rds")
message("  - data/synthetic_control_panel.rds")
