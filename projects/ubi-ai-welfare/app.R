# UBI, AI, and Social Welfare — Interactive Policy Dashboard
# Run: shiny::runApp(".")  ->  http://127.0.0.1:3838

library(shiny)
library(ggplot2)
library(scales)
library(dplyr)
library(tidyr)

root <- if (file.exists("scenarios.yml")) normalizePath(".") else normalizePath("..")
setwd(root)
Sys.setenv(UBI_AI_ROOT = root)

shiny_icon <- function(name) {
  if (requireNamespace("bsicons", quietly = TRUE)) {
    return(bsicons::bs_icon(name))
  }
  icon(name)
}
source(file.path(root, "R/load_data.R"))
source(file.path(root, "R/welfare.R"))
source(file.path(root, "R/methods_did.R"))
source(file.path(root, "R/methods_ml.R"))
source(file.path(root, "R/plot_results.R"))
source(file.path(root, "R/theme_econ.R"))

if (!file.exists(file.path(root, "data/synthetic_households.rds"))) {
  source(file.path(root, "R/build_data.R"))
}

config <- load_config()
household_data <- load_household_data()
has_bslib <- requireNamespace("bslib", quietly = TRUE)

ui <- if (has_bslib) {
  bslib::page_navbar(
    title = "UBI & AI: Social Welfare Explorer",
    theme = shiny_econ_theme(),
    bslib::nav_panel(
      "Overview",
      bslib::layout_sidebar(
        sidebar = bslib::sidebar(
          title = "Policy levers",
          width = 320,
          bslib::accordion(
            open = TRUE,
            bslib::accordion_panel(
              "AI labor market",
              selectInput(
                "ai_scenario", "Scenario",
                choices = setNames(names(config$ai_scenarios), vapply(config$ai_scenarios, `[[`, "", "label")),
                selected = "misaligned_automation"
              ),
              sliderInput("ai_shock", "Job-security shock", 0, 1, 0.5, 0.05),
              tags$p(class = "text-muted small", "0 = minimal disruption, 1 = maximum automation risk.")
            ),
            bslib::accordion_panel(
              "UBI design",
              selectInput("ubi_amount", "Monthly benefit ($/adult)", config$ubi_amounts_monthly, 1000),
              selectInput(
                "funding", "Funding",
                choices = setNames(names(config$funding), vapply(config$funding, `[[`, "", "label")),
                selected = "deficit_financed"
              ),
              sliderInput("crra_rho", "Risk aversion (CRRA ρ)", 0.5, 4, 2, 0.5)
            )
          )
        ),
        bslib::layout_column_wrap(
          width = 1/4, fill = FALSE, heights_equal = "row",
          bslib::value_box(
            title = "Welfare change",
            value = textOutput("vb_welfare", inline = TRUE),
            showcase = shiny_icon("graph-up-arrow"),
            theme = "primary"
          ),
          bslib::value_box(
            title = "Poverty rate",
            value = textOutput("vb_poverty", inline = TRUE),
            showcase = shiny_icon("people"),
            theme = "success"
          ),
          bslib::value_box(
            title = "Net fiscal cost",
            value = textOutput("vb_fiscal", inline = TRUE),
            showcase = shiny_icon("cash-stack"),
            theme = "secondary"
          ),
          bslib::value_box(
            title = "Gini coefficient",
            value = textOutput("vb_gini", inline = TRUE),
            showcase = shiny_icon("bar-chart"),
            theme = "info"
          )
        ),
        bslib::card(
          full_screen = TRUE,
          bslib::card_header("Key metrics under selected policy"),
          bslib::card_body(plotOutput("welfare_plot", height = "320px"))
        ),
        bslib::card(
          full_screen = TRUE,
          bslib::card_header("Who benefits? Consumption gains by income decile"),
          bslib::card_body(plotOutput("decile_plot", height = "320px"))
        )
      )
    ),
    bslib::nav_panel(
      "Scenarios",
      bslib::layout_column_wrap(
        width = 1,
        bslib::card(
          full_screen = TRUE,
          bslib::card_header("Scenario comparison table (deficit-financed)"),
          bslib::card_body(tableOutput("grid_table"))
        ),
        bslib::card(
          full_screen = TRUE,
          bslib::card_header("Welfare change by AI scenario and UBI level"),
          bslib::card_body(plotOutput("heatmap_plot", height = "380px"))
        )
      )
    ),
    bslib::nav_panel(
      "Sensitivity",
      bslib::card(
        full_screen = TRUE,
        bslib::card_header("How welfare responds to AI shock intensity × UBI generosity"),
        bslib::card_body(
          plotOutput("sensitivity_plot", height = "420px"),
          tags$p(class = "text-muted small mt-2",
                 "Continuous shock parameter from 0 (no disruption) to 1 (maximum).")
        )
      )
    ),
    bslib::nav_panel(
      "Methods",
      bslib::layout_column_wrap(
        width = 1/2,
        bslib::card(
          bslib::card_header("Difference-in-differences (template)"),
          bslib::card_body(
            verbatimTextOutput("did_text"),
            plotOutput("did_plot", height = "260px")
          )
        ),
        bslib::card(
          bslib::card_header("Synthetic control (template)"),
          bslib::card_body(
            verbatimTextOutput("sc_text"),
            plotOutput("sc_plot", height = "260px")
          )
        ),
        bslib::card(
          full_screen = TRUE,
          bslib::card_header("Machine learning: who gains most from UBI?"),
          bslib::card_body(plotOutput("ml_plot", height = "280px"))
        )
      )
    ),
    bslib::nav_panel(
      "About",
      bslib::card(
        bslib::card_header("About this tool"),
        bslib::card_body(
          tags$p("This dashboard simulates how Universal Basic Income affects social welfare under alternative AI labor-market paths for the United States."),
          tags$h5("Design approach"),
          tags$ul(
            tags$li("Takeaway-first chart titles (J-PAL / PolicyViz)"),
            tags$li("Modular, glanceable layout (Opportunity Insights tracker style)"),
            tags$li("Non-partisan, colorblind-safe palette"),
            tags$li("Evidence-calibrated assumptions from peer-reviewed sources")
          ),
          tags$h5("Key sources"),
          tags$ul(
            tags$li("IMF (2024): AI exposure and complementarity"),
            tags$li("Eloundou et al. (2023): GPT occupational exposure"),
            tags$li("OpenResearch/NBER (2024): $1,000/month labor supply"),
            tags$li("Jones & Marinescu (2022): Alaska Permanent Fund"),
            tags$li("Raj Chetty Economics 50: quasi-experimental methods")
          ),
          tags$p(class = "text-muted", "Full report: ", tags$code("output/ubi_ai_welfare.pdf"))
        )
      )
    ),
    bslib::nav_spacer(),
    bslib::nav_item(tags$span(class = "navbar-text text-white-50 small", "U.S. baseline"))
  )
} else {
  fluidPage(
    titlePanel("UBI & AI: Social Welfare Explorer"),
    sidebarLayout(
      sidebarPanel(
        selectInput("ai_scenario", "AI Scenario",
          choices = setNames(names(config$ai_scenarios), vapply(config$ai_scenarios, `[[`, "", "label"))),
        sliderInput("ai_shock", "AI Shock", 0, 1, 0.5, 0.05),
        selectInput("ubi_amount", "UBI $/mo", config$ubi_amounts_monthly, 1000),
        selectInput(
          "funding", "Funding",
          choices = setNames(names(config$funding), vapply(config$funding, `[[`, "", "label"))
        ),
        sliderInput("crra_rho", "CRRA rho", 0.5, 4, 2, 0.5)
      ),
      mainPanel(
        textOutput("vb_welfare"), plotOutput("welfare_plot"),
        plotOutput("decile_plot"), plotOutput("heatmap_plot"),
        plotOutput("sensitivity_plot")
      )
    )
  )
}

server <- function(input, output, session) {
  if (requireNamespace("thematic", quietly = TRUE)) {
    thematic::thematic_shiny(font = "auto")
  }

  config_r <- reactive({
    cfg <- config
    cfg$welfare$crra_rho <- input$crra_rho
    cfg
  })

  shocked_data <- reactive({
    apply_ai_shock(household_data, input$ai_scenario, shock_intensity = input$ai_shock, config = config_r())
  })

  sim_data <- reactive({
    simulate_ubi(shocked_data(), as.numeric(input$ubi_amount), funding = input$funding, config = config_r())
  })

  metrics <- reactive({
    compute_welfare(sim_data(), baseline_data = shocked_data(), config = config_r())
  })

  grid_results <- reactive({
    run_scenario_grid(config = config_r(), data = household_data)
  })

  sensitivity_data <- reactive({
    run_sensitivity_grid(config = config_r(), data = household_data, scenario = input$ai_scenario, funding = input$funding)
  })

  output$vb_welfare <- renderText({
    sprintf("%+.2f%%", metrics()$welfare_change_pct)
  })
  output$vb_poverty <- renderText({
    sprintf("%.1f%%", metrics()$poverty_rate * 100)
  })
  output$vb_fiscal <- renderText({
    paste0("$", format(round(metrics()$net_fiscal_cost / 1e9, 2), nsmall = 2), "B")
  })
  output$vb_gini <- renderText({
    sprintf("%.3f", metrics()$gini)
  })

  econ_plot <- function(p, caption = NULL) style_econ_plot(p, caption = caption)

  output$welfare_plot <- renderPlot({
    m <- metrics()
    df <- data.frame(
      metric = c("Poverty (%)", "Gini ×100", "Welfare chg (%)"),
      value = c(m$poverty_rate * 100, m$gini * 100, m$welfare_change_pct)
    )
    cols <- econ_colors()
    econ_plot(
      ggplot(df, aes(metric, value)) +
        geom_col(fill = cols$primary, width = 0.55) +
        geom_text(aes(label = round(value, 1)), vjust = -0.5, size = 3.5) +
        scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
        labs(title = "Policy snapshot", x = NULL, y = NULL),
      caption = "Selected scenario and UBI level."
    )
  })

  output$decile_plot <- renderPlot({
    sim <- sim_data()
    dec <- welfare_by_decile(sim, config = config_r())
    base <- welfare_by_decile(shocked_data() |> dplyr::mutate(net_resources = ai_shocked_income), config = config_r())
    plot_df <- dec |>
      left_join(base |> select(decile, base = mean_consumption), by = "decile") |>
      mutate(gain = mean_consumption - base, fill_pos = gain > 0)
    cols <- econ_colors()
    econ_plot(
      ggplot(plot_df, aes(factor(decile), gain, fill = fill_pos)) +
        geom_col(width = 0.7) +
        scale_fill_manual(values = c("TRUE" = cols$positive, "FALSE" = cols$negative), guide = "none") +
        scale_y_continuous(labels = dollar_format()) +
        labs(
          title = "Lower deciles gain the most from UBI",
          x = "Pre-policy income decile", y = "Annual consumption gain ($)"
        )
    )
  })

  output$poverty_plot <- renderPlot({
    sim <- sim_data()
    cols <- econ_colors()
    econ_plot(
      ggplot(sim, aes(net_resources, weight = weight)) +
        geom_histogram(bins = 40, fill = cols$primary, alpha = 0.85, color = "white") +
        geom_vline(xintercept = mean(sim$poverty_line), color = cols$negative, linetype = "dashed") +
        scale_x_continuous(labels = dollar_format()) +
        labs(title = "Consumption distribution vs. poverty line", x = "Net resources ($)", y = "Weighted count")
    )
  })

  output$grid_table <- renderTable({
    grid_results() |>
      filter(funding == "deficit_financed") |>
      select(ai_scenario_label, ubi_monthly, poverty_rate, welfare_change_pct, net_fiscal_cost) |>
      mutate(
        poverty_rate = round(poverty_rate * 100, 1),
        welfare_change_pct = round(welfare_change_pct, 2),
        net_fiscal_cost = round(net_fiscal_cost / 1e6, 1)
      ) |>
      head(12)
  }, striped = TRUE, hover = TRUE, spacing = "s")

  output$heatmap_plot <- renderPlot({
    econ_plot(
      grid_results() |>
        filter(funding == "deficit_financed") |>
        ggplot(aes(factor(ubi_monthly), ai_scenario_label, fill = welfare_change_pct)) +
        geom_tile(color = "white", linewidth = 0.4) +
        scale_econ_diverging("Welfare chg (%)") +
        labs(
          title = "Welfare gains are largest under misaligned automation",
          x = "UBI ($/month)", y = NULL
        )
    )
  })

  output$sensitivity_plot <- renderPlot({
    econ_plot(
      ggplot(sensitivity_data(), aes(factor(ubi_monthly), ai_job_security_shock, fill = welfare_change_pct)) +
        geom_tile(color = "white", linewidth = 0.4) +
        scale_econ_diverging("Welfare chg (%)") +
        labs(
          title = "Higher AI disruption amplifies the value of UBI",
          x = "UBI ($/month)", y = "AI job-security shock"
        )
    )
  })

  did_result <- reactive(run_did_analysis())
  sc_result <- reactive(run_synthetic_control())
  ml_result <- reactive({
    run_ml_welfare_prediction(household_data, as.numeric(input$ubi_amount), input$ai_scenario, config_r())
  })

  output$did_text <- renderPrint({
    cat("DiD treated coefficient:", round(did_result()$did_estimate, 4), "\n")
    cat("(Template — illustrative only)\n")
  })

  output$did_plot <- renderPlot({
    d <- did_result()
    if (is.null(d$event_study)) return(NULL)
    es <- d$event_study[grepl("rel_period", d$event_study$term), , drop = FALSE]
    if (nrow(es) == 0) return(NULL)
    es$period <- as.numeric(gsub(".*::(-?[0-9]+).*", "\\1", es$term))
    cols <- econ_colors()
    econ_plot(
      ggplot(es, aes(period, estimate)) +
        geom_hline(yintercept = 0, linetype = "dashed", color = cols$mid) +
        geom_vline(xintercept = -0.5, linetype = "dotted", color = cols$negative) +
        geom_point(color = cols$primary) +
        geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.2, color = cols$primary) +
        labs(title = "Event study around ChatGPT release", x = "Months from Nov 2022", y = "Coefficient")
    )
  })

  output$sc_text <- renderPrint({
    s <- sc_result()
    cat("Synthetic control ATT:", round(s$att, 4), "\n")
    cat("Pre-RMSPE:", round(s$pre_rmspe, 4), "\n")
  })

  output$sc_plot <- renderPlot({
    s <- sc_result()
    if (is.null(s$treated_post)) return(NULL)
    df <- data.frame(year = s$years_post, treated = s$treated_post, synthetic = s$synthetic_post) |>
      pivot_longer(c(treated, synthetic), names_to = "series", values_to = "employment_rate") |>
      mutate(series = ifelse(series == "treated", "Alaska", "Synthetic control"))
    cols <- econ_colors()
    econ_plot(
      ggplot(df, aes(year, employment_rate, color = series)) +
        geom_line(linewidth = 1) +
        geom_vline(xintercept = 1981.5, linetype = "dotted", color = cols$mid) +
        scale_color_manual(values = c("Alaska" = cols$primary, "Synthetic control" = cols$mid)) +
        scale_y_continuous(labels = percent_format(accuracy = 1)) +
        labs(title = "Alaska Permanent Fund template", x = "Year", y = "Employment rate", color = NULL)
    )
  })

  output$ml_plot <- renderPlot({
    imp <- ml_result()$feature_importance
    df <- data.frame(feature = names(imp), importance = as.numeric(imp))
    cols <- econ_colors()
    econ_plot(
      ggplot(df, aes(reorder(feature, importance), importance)) +
        geom_col(fill = cols$primary, width = 0.7) +
        coord_flip() +
        labs(title = "Income and AI exposure predict UBI welfare gains", x = NULL, y = "Importance")
    )
  })
}

shinyApp(ui = ui, server = server)
