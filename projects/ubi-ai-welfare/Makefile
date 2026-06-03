.PHONY: all data pdf preview clean install

all: data pdf

install:
	Rscript -e "if (!requireNamespace('renv', quietly = TRUE)) install.packages('renv'); renv::restore(prompt = FALSE)"

data:
	Rscript R/build_data.R

pdf:
	Rscript R/render_pdf.R

preview:
	Rscript -e "shiny::runApp('.', launch.browser = FALSE, port = 3838, host = '127.0.0.1')" &

clean:
	rm -rf output/*.pdf output/*.png
