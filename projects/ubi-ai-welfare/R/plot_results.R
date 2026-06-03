#' Plotting utilities for UBI-AI welfare analysis
source_if_missing <- function() {
  if (!exists("theme_econ", mode = "function")) {
    root <- Sys.getenv("UBI_AI_ROOT", unset = ".")
    path <- file.path(root, "R/theme_econ.R")
    if (file.exists(path)) source(path)
  }
}

plot_scenario_heatmap <- function(results, output_dir = "output/figures") {
  source_if_missing()
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  p <- results |>
    dplyr::filter(funding == "deficit_financed") |>
    ggplot2::ggplot(ggplot2::aes(x = factor(ubi_monthly), y = ai_scenario_label, fill = welfare_change_pct)) +
    ggplot2::geom_tile(color = "white", linewidth = 0.4) +
    scale_econ_diverging("Welfare\nchange (%)") +
    ggplot2::labs(
      title = "Higher UBI raises welfare most when AI threatens job security",
      subtitle = "Social welfare change (%) by AI scenario and monthly benefit level",
      x = "UBI per adult ($/month)",
      y = NULL,
      caption = "Source: U.S. household microsimulation. Deficit-financed UBI."
    )

  path <- file.path(output_dir, "welfare_heatmap.png")
  ggplot2::ggsave(path, style_econ_plot(p), width = 8, height = 5, dpi = 300, bg = "white")
  path
}

plot_poverty_by_scenario <- function(results, output_dir = "output/figures") {
  source_if_missing()
  cols <- econ_colors()
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  p <- results |>
    dplyr::filter(funding == "deficit_financed", ubi_monthly == 1000) |>
    ggplot2::ggplot(ggplot2::aes(x = reorder(ai_scenario_label, -poverty_rate), y = poverty_rate * 100)) +
    ggplot2::geom_col(fill = cols$primary, width = 0.65) +
    ggplot2::geom_text(
      ggplot2::aes(label = sprintf("%.1f%%", poverty_rate * 100)),
      vjust = -0.4, size = 3.5, color = cols$neutral
    ) +
    ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0, 0.12))) +
    ggplot2::labs(
      title = "A $1,000/month UBI cuts poverty in all AI scenarios",
      subtitle = "Simulated poverty rate after policy (deficit-financed)",
      x = NULL, y = "Poverty rate (%)",
      caption = "Source: U.S. household microsimulation."
    )

  path <- file.path(output_dir, "poverty_by_scenario.png")
  ggplot2::ggsave(path, style_econ_plot(p), width = 8, height = 5, dpi = 300, bg = "white")
  path
}

plot_decile_gains <- function(
    data, ubi_monthly = 1000, scenario = "misaligned_automation",
    config = load_config(), output_dir = "output/figures"
) {
  source_if_missing()
  cols <- econ_colors()
  shocked <- apply_ai_shock(data, scenario, config = config)
  sim <- simulate_ubi(shocked, ubi_monthly, config = config)

  dec <- welfare_by_decile(sim, config = config)
  base_dec <- welfare_by_decile(
    shocked |> dplyr::mutate(net_resources = ai_shocked_income),
    config = config
  )

  plot_df <- dec |>
    dplyr::left_join(base_dec |> dplyr::select(decile, base_consumption = mean_consumption), by = "decile") |>
    dplyr::mutate(gain = mean_consumption - base_consumption, fill_pos = gain > 0)

  p <- ggplot2::ggplot(plot_df, ggplot2::aes(x = factor(decile), y = gain, fill = fill_pos)) +
    ggplot2::geom_col(width = 0.7) +
    ggplot2::scale_fill_manual(values = c("TRUE" = cols$positive, "FALSE" = cols$negative), guide = "none") +
    ggplot2::scale_y_continuous(labels = scales::label_dollar()) +
    ggplot2::labs(
      title = "UBI gains concentrate in lower income deciles",
      subtitle = paste0("Annual consumption change under $", ubi_monthly, "/mo UBI (", scenario, ")"),
      x = "Pre-policy income decile (1 = lowest)",
      y = "Annual consumption gain",
      caption = "Source: U.S. household microsimulation."
    )

  path <- file.path(output_dir, "decile_gains.png")
  ggplot2::ggsave(path, style_econ_plot(p), width = 8, height = 5, dpi = 300, bg = "white")
  path
}

plot_did_event_study <- function(did_result, output_dir = "output/figures") {
  source_if_missing()
  if (is.null(did_result$event_study)) return(invisible(NULL))

  es <- did_result$event_study
  es <- es[grepl("rel_period", es$term), , drop = FALSE]
  if (nrow(es) == 0) return(invisible(NULL))

  es$period <- as.numeric(gsub(".*::(-?[0-9]+).*", "\\1", es$term))
  cols <- econ_colors()

  p <- ggplot2::ggplot(es, ggplot2::aes(x = period, y = estimate)) +
    ggplot2::geom_hline(yintercept = 0, linetype = "dashed", color = cols$mid) +
    ggplot2::geom_vline(xintercept = -0.5, linetype = "dotted", color = cols$negative, linewidth = 0.6) +
    ggplot2::geom_point(color = cols$primary, size = 2) +
    ggplot2::geom_errorbar(ggplot2::aes(ymin = conf.low, ymax = conf.high), width = 0.2, color = cols$primary) +
    ggplot2::labs(
      title = "High-AI-exposure occupations show no clear post-ChatGPT break",
      subtitle = "Event-study coefficients on employment (template panel)",
      x = "Months relative to ChatGPT release (Nov 2022)",
      y = "Estimated effect",
      caption = "Note: Illustrative template; not causal identification. Source: occupation-month panel."
    )

  path <- file.path(output_dir, "did_event_study.png")
  ggplot2::ggsave(path, style_econ_plot(p), width = 8, height = 5, dpi = 300, bg = "white")
  path
}

plot_synthetic_control <- function(sc_result, output_dir = "output/figures") {
  source_if_missing()
  if (is.null(sc_result$treated_post)) return(invisible(NULL))
  cols <- econ_colors()

  df <- data.frame(
    year = sc_result$years_post,
    treated = sc_result$treated_post,
    synthetic = sc_result$synthetic_post
  ) |>
    tidyr::pivot_longer(c(treated, synthetic), names_to = "series", values_to = "employment_rate") |>
    dplyr::mutate(series = ifelse(series == "treated", "Alaska (treated)", "Synthetic control"))

  p <- ggplot2::ggplot(df, ggplot2::aes(x = year, y = employment_rate, color = series)) +
    ggplot2::geom_line(linewidth = 1) +
    ggplot2::geom_vline(xintercept = 1981.5, linetype = "dotted", color = cols$mid) +
    ggplot2::scale_color_manual(values = c("Alaska (treated)" = cols$primary, "Synthetic control" = cols$mid)) +
    ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
    ggplot2::labs(
      title = "Universal cash transfers did not reduce aggregate employment",
      subtitle = paste0("Alaska Permanent Fund template (ATT = ", round(sc_result$att, 4), ")"),
      x = "Year", y = "Employment rate", color = NULL,
      caption = "Source: State-year template calibrated to Jones & Marinescu (2022)."
    )

  path <- file.path(output_dir, "synthetic_control.png")
  ggplot2::ggsave(path, style_econ_plot(p), width = 8, height = 5, dpi = 300, bg = "white")
  path
}

plot_ml_importance <- function(ml_result, output_dir = "output/figures") {
  source_if_missing()
  cols <- econ_colors()
  imp <- ml_result$feature_importance
  df <- data.frame(feature = names(imp), importance = as.numeric(imp)) |>
    dplyr::arrange(dplyr::desc(importance))

  p <- ggplot2::ggplot(df, ggplot2::aes(x = reorder(feature, importance), y = importance)) +
    ggplot2::geom_col(fill = cols$primary, width = 0.7) +
    ggplot2::coord_flip() +
    ggplot2::labs(
      title = "Income and AI exposure predict who gains most from UBI",
      subtitle = "Random forest feature importance for household welfare gains",
      x = NULL, y = "Impurity importance",
      caption = "Source: ML template on simulated households."
    )

  path <- file.path(output_dir, "ml_importance.png")
  ggplot2::ggsave(path, style_econ_plot(p), width = 8, height = 5, dpi = 300, bg = "white")
  path
}

plot_sensitivity_heatmap <- function(sensitivity, output_dir = "output/figures") {
  source_if_missing()
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  p <- ggplot2::ggplot(
    sensitivity,
    ggplot2::aes(x = factor(ubi_monthly), y = ai_job_security_shock, fill = welfare_change_pct)
  ) +
    ggplot2::geom_tile(color = "white", linewidth = 0.4) +
    scale_econ_diverging("Welfare\nchange (%)") +
    ggplot2::labs(
      title = "Welfare gains rise with both UBI generosity and AI disruption",
      subtitle = "Sensitivity to continuous AI job-security shock intensity",
      x = "UBI per adult ($/month)",
      y = "AI job-security shock (0 = none, 1 = max)",
      caption = "Source: U.S. household microsimulation."
    )

  path <- file.path(output_dir, "sensitivity_heatmap.png")
  ggplot2::ggsave(path, style_econ_plot(p), width = 8, height = 5, dpi = 300, bg = "white")
  path
}
