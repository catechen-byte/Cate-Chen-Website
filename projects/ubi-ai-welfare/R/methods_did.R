#' Difference-in-differences / event study (Economics 50 style template)
#' @param panel Occupation-month panel with employment_rate, treated, post_chatgpt
#' @return List with DiD estimate and event-study coefficients
run_did_analysis <- function(panel = load_did_panel()) {
  if (!requireNamespace("fixest", quietly = TRUE)) {
    install.packages("fixest", repos = "https://cloud.r-project.org")
  }

  panel <- panel |>
    dplyr::mutate(
      month_id = as.integer(factor(month)),
      rel_month = as.numeric(difftime(month, as.Date("2022-11-01"), units = "days")) / 30
    )

  # Two-way fixed effects DiD
  did_model <- fixest::feols(
    employment_rate ~ treated + ai_exposure + automation_prone | occupation_group + month_id,
    data = panel,
    cluster = ~occupation_group
  )

  # Event study: high vs low exposure after ChatGPT
  panel <- panel |>
    dplyr::mutate(
      rel_period = pmin(pmax(round(rel_month), -12), 12),
      treat_high = high_exposure * as.integer(rel_period >= 0)
    )

  event_coefs <- tryCatch({
    es_model <- fixest::feols(
      employment_rate ~ i(rel_period, high_exposure, ref = -1) | occupation_group + month_id,
      data = panel,
      cluster = ~occupation_group
    )
    broom::tidy(es_model, conf.int = TRUE)
  }, error = function(e) {
    NULL
  })

  list(
    did_model = did_model,
    did_estimate = coef(did_model)["treated"],
    event_study = event_coefs,
    summary = summary(did_model)
  )
}

#' Synthetic control template (Alaska Permanent Fund style)
#' @param panel State-year panel
#' @param treated_state Treated unit
#' @param treat_year Treatment year
#' @param outcome Outcome variable name
run_synthetic_control <- function(
    panel = load_sc_panel(),
    treated_state = "AK",
    treat_year = 1982,
    outcome = "employment_rate"
) {
  pre_data <- panel |>
    dplyr::filter(year < treat_year, state != treated_state)

  treated_pre <- panel |>
    dplyr::filter(state == treated_state, year < treat_year)

  post_data <- panel |>
    dplyr::filter(year >= treat_year)

  # Simple synthetic control: weighted average of donor states matching pre-treatment trend
  donor_states <- setdiff(unique(panel$state), treated_state)
  n_pre <- length(unique(treated_pre$year))

  treated_vec <- treated_pre[[outcome]]
  donor_mat <- sapply(donor_states, function(s) {
    pre_data |> dplyr::filter(state == s) |> dplyr::arrange(year) |> dplyr::pull(!!outcome)
  })

  if (ncol(donor_mat) == 0 || length(treated_vec) == 0) {
    return(list(weights = NULL, gap = NULL, att = NA_real_))
  }

  # OLS weights (simple approach)
  fit <- tryCatch(lm(treated_vec ~ donor_mat), error = function(e) NULL)
  if (is.null(fit)) {
    weights <- rep(1 / length(donor_states), length(donor_states))
  } else {
    weights <- coef(fit)[-1]
    weights[is.na(weights)] <- 0
    weights[weights < 0] <- 0
    if (sum(weights, na.rm = TRUE) > 0) {
      weights <- weights / sum(weights, na.rm = TRUE)
    } else {
      weights <- rep(1 / length(donor_states), length(donor_states))
    }
  }

  synthetic_pre <- as.vector(donor_mat %*% weights)
  gap_pre <- treated_vec - synthetic_pre

  treated_post <- post_data |>
    dplyr::filter(state == treated_state) |>
    dplyr::arrange(year)

  synth_post <- sapply(treated_post$year, function(y) {
    donor_vals <- sapply(donor_states, function(s) {
      post_data |> dplyr::filter(state == s, year == y) |> dplyr::pull(!!outcome)
    })
    sum(donor_vals * weights, na.rm = TRUE)
  })

  att <- mean(treated_post[[outcome]] - synth_post, na.rm = TRUE)

  list(
    weights = stats::setNames(weights, donor_states),
    treated_pre = treated_vec,
    synthetic_pre = synthetic_pre,
    pre_rmspe = sqrt(mean(gap_pre^2)),
    att = att,
    treated_post = treated_post[[outcome]],
    synthetic_post = synth_post,
    years_post = treated_post$year
  )
}
