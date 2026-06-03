# Shared visualization theme — economics / policy brief style
# Inspired by J-PAL, Opportunity Insights, and PolicyViz best practices:
# - Takeaway titles, minimal clutter, colorblind-safe palette, source footnotes

#' Color palette (non-partisan, colorblind-friendly)
econ_colors <- function() {
  list(
    primary   = "#1F4E79",  # steel blue accent
    secondary = "#0D7680",  # teal
    positive  = "#2D8659",
    negative  = "#B84A4A",
    neutral   = "#4A4A4A",
    light     = "#ECEFF1",
    mid       = "#90A4AE",
    seq       = c("#1F4E79", "#0D7680", "#5C6BC0", "#78909C", "#2D8659", "#B84A4A")
  )
}

#' Diverging fill scale for welfare / change metrics
scale_econ_diverging <- function(name = "Change (%)") {
  cols <- econ_colors()
  ggplot2::scale_fill_gradient2(
    low = cols$negative, mid = "#F7F7F7", high = cols$positive,
    midpoint = 0, name = name, guide = ggplot2::guide_colorbar(barheight = ggplot2::unit(60, "pt"))
  )
}

#' Clean ggplot2 theme for policy reports
theme_econ <- function(base_size = 11, base_family = "sans") {
  cols <- econ_colors()
  ggplot2::theme_minimal(base_size = base_size, base_family = base_family) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(
        face = "bold", size = base_size + 2, color = cols$neutral, hjust = 0, margin = ggplot2::margin(b = 4)
      ),
      plot.subtitle = ggplot2::element_text(
        size = base_size, color = cols$mid, hjust = 0, margin = ggplot2::margin(b = 8)
      ),
      plot.caption = ggplot2::element_text(
        size = base_size - 2, color = cols$mid, hjust = 0, margin = ggplot2::margin(t = 8)
      ),
      panel.grid.major.y = ggplot2::element_line(color = "#E0E0E0", linewidth = 0.3),
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      axis.title = ggplot2::element_text(color = cols$neutral, size = base_size - 1),
      axis.text = ggplot2::element_text(color = cols$neutral),
      legend.title = ggplot2::element_text(face = "bold", size = base_size - 1),
      legend.position = "right",
      plot.margin = ggplot2::margin(12, 12, 12, 12)
    )
}

#' Apply standard economics styling to a ggplot object
style_econ_plot <- function(p, caption = NULL) {
  p <- p + theme_econ()
  if (!is.null(caption)) {
    p <- p + ggplot2::labs(caption = caption)
  }
  p
}

#' Format dollar labels for ggplot scales
label_dollar <- function(x) {
  if (!requireNamespace("scales", quietly = TRUE)) return(x)
  scales::label_dollar(accuracy = 1, scale = 1e-3, suffix = "K")(x * 1000)
}

#' Shiny bslib theme (Opportunity Insights–inspired: grayscale + accent)
shiny_econ_theme <- function() {
  if (!requireNamespace("bslib", quietly = TRUE)) return(NULL)
  cols <- econ_colors()
  bslib::bs_theme(
    version = 5,
    bg = "#FFFFFF",
    fg = cols$neutral,
    primary = cols$primary,
    secondary = cols$secondary,
    success = cols$positive,
    danger = cols$negative,
    base_font = bslib::font_google("Source Sans 3"),
    heading_font = bslib::font_google("Source Serif 4"),
    "navbar-bg" = cols$primary,
    "card-border-width" = "1px",
    "card-border-color" = "#E0E0E0"
  )
}
