# UBI, AI, and Social Welfare

An R project that estimates how Universal Basic Income (UBI) changes social welfare under configurable AI labor-market disruption scenarios. The baseline population is the United States.

## Quick start

```bash
make install   # R packages (renv)
make data      # build data/
make pdf       # report → output/ubi_ai_welfare.pdf
make preview   # dashboard → http://127.0.0.1:3838
```

Or in R:

```r
source("R/run_analysis.R")
run_full_analysis()
shiny::runApp(".")
```

## Project layout

| Path | Purpose |
|------|---------|
| `scenarios.yml` | UBI amounts, AI scenarios, tax/funding assumptions |
| `R/` | Core code + `build_data.R` |
| `data/` | Cached datasets |
| `ubi_ai_welfare.Rmd` | PDF report source |
| `references.bib` | Citations for the report |
| `app.R` | Shiny dashboard |
| `output/` | `ubi_ai_welfare.pdf`, `ubi_ai_welfare.tex`, figures, results |

## Requirements

- R >= 4.2
- Pandoc and LaTeX for PDF
- `Rscript -e "renv::restore()"`

## Makefile

| Target | Action |
|--------|--------|
| `make install` | Restore R packages |
| `make data` | Run `R/build_data.R` |
| `make pdf` | Render PDF + LaTeX to `output/` |
| `make preview` | Start Shiny app |
| `make clean` | Remove generated PDFs/figures |
