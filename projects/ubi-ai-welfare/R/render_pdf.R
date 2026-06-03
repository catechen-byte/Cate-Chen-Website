# Render PDF report (and keep LaTeX source in output/)
# Usage: Rscript R/render_pdf.R  (from project root)

ensure_pandoc <- function() {
  if (rmarkdown::pandoc_available()) return(invisible(TRUE))

  local_bin <- path.expand("~/.local/bin")
  pandoc_exe <- file.path(local_bin, "pandoc")
  if (file.exists(pandoc_exe)) {
    Sys.setenv(RSTUDIO_PANDOC = local_bin)
    if (rmarkdown::pandoc_available()) return(invisible(TRUE))
  }

  arch <- Sys.info()[["machine"]]
  ver <- "3.6.4"
  if (arch == "arm64") {
    url <- sprintf(
      "https://github.com/jgm/pandoc/releases/download/%s/pandoc-%s-arm64-macOS.zip",
      ver, ver
    )
  } else {
    url <- sprintf(
      "https://github.com/jgm/pandoc/releases/download/%s/pandoc-%s-x86_64-macOS.zip",
      ver, ver
    )
  }

  message("Pandoc not found. Installing to ", local_bin, " ...")
  dir.create(local_bin, recursive = TRUE, showWarnings = FALSE)
  tmp <- tempfile()
  dir.create(tmp)
  zip_path <- file.path(tmp, "pandoc.zip")
  utils::download.file(url, zip_path, mode = "wb", quiet = TRUE)
  utils::unzip(zip_path, exdir = tmp)
  found <- list.files(tmp, pattern = "^pandoc$", recursive = TRUE, full.names = TRUE)
  found <- found[basename(found) == "pandoc"]
  if (length(found) == 0) stop("Pandoc download failed. Install from https://pandoc.org")
  file.copy(found[1], pandoc_exe, overwrite = TRUE)
  Sys.chmod(pandoc_exe, "0755")
  Sys.setenv(RSTUDIO_PANDOC = local_bin)
  unlink(tmp, recursive = TRUE)

  if (!rmarkdown::pandoc_available()) {
    stop("Pandoc still not available after install. Add ~/.local/bin to PATH.")
  }
  invisible(TRUE)
}

root <- if (file.exists("scenarios.yml")) {
  normalizePath(".")
} else if (file.exists("../scenarios.yml")) {
  normalizePath("..")
} else {
  stop("Run from the project root (directory containing scenarios.yml).")
}
setwd(root)

if (!requireNamespace("rmarkdown", quietly = TRUE)) {
  stop("Package 'rmarkdown' required. Run: renv::restore()")
}

ensure_pandoc()
dir.create("output", showWarnings = FALSE)

message("Rendering PDF to output/ubi_ai_welfare.pdf ...")
rmarkdown::render(
  input = "ubi_ai_welfare.Rmd",
  output_format = rmarkdown::pdf_document(
    latex_engine = "pdflatex",
    keep_tex = TRUE
  ),
  output_dir = "output",
  output_file = "ubi_ai_welfare.pdf",
  quiet = FALSE
)

tex_path <- file.path(root, "output", "ubi_ai_welfare.tex")
pdf_path <- file.path(root, "output", "ubi_ai_welfare.pdf")
message("Done.")
message("  PDF: ", pdf_path)
if (file.exists(tex_path)) message("  LaTeX: ", tex_path)
