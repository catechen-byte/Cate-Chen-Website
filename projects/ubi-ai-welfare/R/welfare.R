`%||%` <- function(x, y) if (is.null(x)) y else x

#' CRRA utility function
#' @param c Consumption (numeric vector)
#' @param rho Risk aversion parameter
#' @return Utility values
crra_utility <- function(c, rho = 2) {
  c <- pmax(c, 1e-6)
  if (abs(rho - 1) < 1e-10) {
    return(log(c))
  }
  (c^(1 - rho) - 1) / (1 - rho)
}

#' Compute poverty threshold for household
#' @param adults Number of adults
#' @param children Number of children
#' @param config Project config list
poverty_threshold <- function(adults, children, config) {
  w <- config$welfare
  w$poverty_threshold_single +
    (pmax(adults - 1, 0) + children) * w$poverty_threshold_per_additional
}

#' Apply AI labor-market shock to household income and employment
#' @param data Household tibble
#' @param scenario Named AI scenario from config
#' @param shock_intensity Scalar 0-1 multiplier on scenario parameters
#' @param config Full config list
#' @return Tibble with shocked income and employment
apply_ai_shock <- function(data, scenario, shock_intensity = NULL, config = load_config()) {
  s <- config$ai_scenarios[[scenario]]
  if (is.null(shock_intensity)) {
    shock_intensity <- s$ai_job_security_shock
  }
  shock_intensity <- pmin(pmax(shock_intensity, 0), 1)

  d <- data |>
    dplyr::mutate(
      shock_intensity = shock_intensity,
      displacement_prob = pmin(
        automation_prone * s$displacement_rate * shock_intensity * ai_exposure,
        0.95
      ),
      augmentation_boost = augmentation_prone * s$productivity_gain * shock_intensity * ai_exposure,
      wage_loss = market_income * displacement_prob * 0.6,
      volatility_penalty = market_income * s$wage_volatility_increase * shock_intensity * ai_exposure * 0.1,
      productivity_gain_income = market_income * augmentation_boost,
      ai_shocked_income = pmax(
        market_income - wage_loss - volatility_penalty + productivity_gain_income,
        config$welfare$min_consumption_floor
      ),
      ai_employment = pmax(
        employed - displacement_prob * (1 - employed * 0),
        0
      ),
      ai_unemployment_risk = s$unemployment_spike * shock_intensity * automation_prone
    )

  d
}

#' Simulate UBI transfer and financing
#' @param data Household tibble (optionally after AI shock)
#' @param ubi_monthly Monthly UBI per adult
#' @param funding Funding mechanism name
#' @param config Config list
#' @param income_col Column name for baseline/shocked income
simulate_ubi <- function(
    data,
    ubi_monthly,
    funding = "deficit_financed",
    config = load_config(),
    income_col = "ai_shocked_income"
) {
  fund <- config$funding[[funding]]
  ls <- config$labor_supply$default_elasticity
  ref <- ls$reference_amount_monthly

  # Scale labor response with UBI amount
  scale_factor <- ubi_monthly / ref
  participation_effect <- ls$participation_pp_at_reference * scale_factor
  earned_elasticity <- ls$earned_income_elasticity * scale_factor

  d <- data |>
    dplyr::mutate(
      ubi_annual = ubi_monthly * 12 * adults,
      gross_income = .data[[income_col]],
      earned_after_ubi = gross_income * (1 + earned_elasticity),
      tax_flat = if (fund$tax_rate_flat > 0) earned_after_ubi * fund$tax_rate_flat else 0,
      tax_progressive = if (!is.null(fund$tax_rate_progressive_top) && fund$tax_rate_progressive_top > 0) {
        threshold <- if (!is.null(fund$progressive_threshold)) fund$progressive_threshold else 100000
        pmax(earned_after_ubi - threshold, 0) * fund$tax_rate_progressive_top
      } else {
        0
      },
      total_tax = tax_flat + tax_progressive,
      net_resources = earned_after_ubi + ubi_annual - total_tax,
      net_resources = pmax(net_resources, config$welfare$min_consumption_floor),
      poverty_line = poverty_threshold(adults, children, config),
      in_poverty = as.integer(net_resources < poverty_line),
      ubi_monthly = ubi_monthly,
      funding = funding
    )

  d
}

#' Compute aggregate welfare metrics
#' @param data Household tibble with net_resources
#' @param baseline_data Baseline (no UBI) for CEV comparison
#' @param config Config list
compute_welfare <- function(data, baseline_data = NULL, config = load_config()) {
  rho <- config$welfare$crra_rho
  w <- data$weight
  if (is.null(w)) w <- rep(1, nrow(data))

  consumption <- data$net_resources
  util <- crra_utility(consumption, rho)
  swf <- sum(w * util) / sum(w)

  poverty_rate <- weighted.mean(data$in_poverty, w)
  gini <- compute_gini(consumption, w)
  mean_consumption <- weighted.mean(consumption, w)
  total_ubi_cost <- sum(w * data$ubi_annual, na.rm = TRUE)
  total_tax_revenue <- sum(w * data$total_tax, na.rm = TRUE)
  net_fiscal_cost <- total_ubi_cost - total_tax_revenue

  out <- list(
    social_welfare = swf,
    poverty_rate = poverty_rate,
    gini = gini,
    mean_consumption = mean_consumption,
    total_ubi_cost = total_ubi_cost,
    total_tax_revenue = total_tax_revenue,
    net_fiscal_cost = net_fiscal_cost
  )

  if (!is.null(baseline_data)) {
    base_cons <- if ("ai_shocked_income" %in% names(baseline_data)) {
      baseline_data$ai_shocked_income
    } else {
      baseline_data$market_income
    }
    base_util <- crra_utility(pmax(base_cons, config$welfare$min_consumption_floor), rho)
    base_swf <- sum(w * base_util) / sum(w)
    out$welfare_change <- swf - base_swf
    out$welfare_change_pct <- (swf - base_swf) / abs(base_swf) * 100
    out$cev <- compute_cev(base_cons, consumption, rho, w)
  }

  out
}

#' Consumption equivalent variation
#' @param c0 Baseline consumption
#' @param c1 Policy consumption
#' @param rho CRRA parameter
#' @param w Weights
compute_cev <- function(c0, c1, rho = 2, w = NULL) {
  if (is.null(w)) w <- rep(1, length(c0))
  u0 <- crra_utility(c0, rho)
  u1 <- crra_utility(c1, rho)
  delta_u <- sum(w * (u1 - u0)) / sum(w)

  # Find lambda such that u(c0*(1+lambda)) = u0 + delta_u (approximate aggregate CEV)
  if (abs(rho - 1) < 1e-10) {
    lambda <- exp(delta_u / weighted.mean(log(pmax(c0, 1e-6)), w)) - 1
  } else {
    u_target <- weighted.mean(u0, w) + delta_u
    cbar0 <- weighted.mean(c0, w)
    if (u_target <= crra_utility(1e-6, rho)) {
      lambda <- -0.99
    } else {
      lambda <- (u_target * (1 - rho) + 1)^(1 / (1 - rho)) / cbar0 - 1
    }
  }
  lambda
}

#' Weighted Gini coefficient (Lorenz curve, O(n log n))
compute_gini <- function(x, w = NULL) {
  if (is.null(w)) w <- rep(1, length(x))
  n <- length(x)
  if (n < 2) return(0)
  idx <- order(x)
  x <- x[idx]
  w <- w[idx] / sum(w)
  mu <- sum(w * x)
  if (mu <= 0) return(0)
  cw <- cumsum(w)
  lc <- cumsum(w * x) / mu
  lc_prev <- c(0, lc[-n])
  cw_prev <- c(0, cw[-n])
  area <- sum((lc + lc_prev) / 2 * (cw - cw_prev))
  1 - 2 * area
}

#' Run full scenario grid
#' @param config Config list
#' @param data Household data
#' @return Tibble of scenario results
run_scenario_grid <- function(config = load_config(), data = load_household_data()) {
  scenarios <- names(config$ai_scenarios)
  ubi_amounts <- config$ubi_amounts_monthly
  funding_modes <- names(config$funding)

  results <- list()
  idx <- 1

  for (sc in scenarios) {
    shocked <- apply_ai_shock(data, sc, config = config)
    baseline_metrics <- compute_welfare(
      shocked |> dplyr::mutate(net_resources = ai_shocked_income, in_poverty = as.integer(ai_shocked_income < poverty_threshold(adults, children, config)), ubi_annual = 0, total_tax = 0),
      config = config
    )

    for (ubi in ubi_amounts) {
      for (fund in funding_modes) {
        sim <- simulate_ubi(shocked, ubi, funding = fund, config = config)
        metrics <- compute_welfare(sim, baseline_data = shocked, config = config)
        results[[idx]] <- tibble::tibble(
          ai_scenario = sc,
          ai_scenario_label = config$ai_scenarios[[sc]]$label,
          ubi_monthly = ubi,
          funding = fund,
          funding_label = config$funding[[fund]]$label,
          social_welfare = metrics$social_welfare,
          welfare_change = metrics$welfare_change %||% NA_real_,
          welfare_change_pct = metrics$welfare_change_pct %||% NA_real_,
          cev = metrics$cev %||% NA_real_,
          poverty_rate = metrics$poverty_rate,
          gini = metrics$gini,
          mean_consumption = metrics$mean_consumption,
          net_fiscal_cost = metrics$net_fiscal_cost
        )
        idx <- idx + 1
      }
    }
  }

  dplyr::bind_rows(results)
}

#' Sensitivity grid over continuous AI job-security shock intensity
#' @param config Config list
#' @param data Household data
#' @param scenario AI scenario name
#' @param ubi_monthly UBI amount
#' @param shock_values Vector of shock intensities 0-1
run_sensitivity_grid <- function(
    config = load_config(),
    data = load_household_data(),
    scenario = "misaligned_automation",
    ubi_amounts = NULL,
    funding = "deficit_financed",
    shock_values = seq(0, 1, by = 0.1)
) {
  if (is.null(ubi_amounts)) ubi_amounts <- config$ubi_amounts_monthly
  rows <- list()
  idx <- 1
  for (ubi in ubi_amounts) {
    for (shock in shock_values) {
      shocked <- apply_ai_shock(data, scenario, shock_intensity = shock, config = config)
      sim <- simulate_ubi(shocked, ubi, funding = funding, config = config)
      metrics <- compute_welfare(sim, baseline_data = shocked, config = config)
      rows[[idx]] <- tibble::tibble(
        ai_scenario = scenario,
        ai_job_security_shock = shock,
        ubi_monthly = ubi,
        funding = funding,
        welfare_change_pct = metrics$welfare_change_pct,
        poverty_rate = metrics$poverty_rate,
        gini = metrics$gini,
        cev = metrics$cev,
        net_fiscal_cost = metrics$net_fiscal_cost
      )
      idx <- idx + 1
    }
  }
  dplyr::bind_rows(rows)
}

#' Welfare by income decile
welfare_by_decile <- function(data, config = load_config(), n_deciles = 10) {
  w <- data$weight
  income <- if ("net_resources" %in% names(data)) data$net_resources else data$market_income
  decile <- dplyr::ntile(income, n_deciles)
  rho <- config$welfare$crra_rho

  tibble::tibble(
    decile = decile,
    weight = w,
    consumption = data$net_resources %||% income,
    utility = crra_utility(data$net_resources %||% income, rho)
  ) |>
    dplyr::group_by(decile) |>
    dplyr::summarise(
      mean_consumption = weighted.mean(consumption, weight),
      mean_utility = weighted.mean(utility, weight),
      n = dplyr::n(),
      .groups = "drop"
    )
}
