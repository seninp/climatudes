# =============================================================================
# Castanet-Tolosan temperature analysis — reproducible pipeline
#   make all      run the full pipeline (prepare -> plots -> report)
#   make prepare  slice raw .csv.gz -> small gzipped station extract
#   make plots    build the three figures + annual table + stats
#   make report   build the self-contained HTML report
#   make open     open the report in the default browser (macOS)
#   make clean    remove generated outputs + cached extract (raw is untouched)
# =============================================================================

RSCRIPT := Rscript

RAW_GZ      := $(wildcard data/raw/*.csv.gz)
PROCESSED   := data/processed
EXTRACT     := data/processed/stations_daily.csv.gz
FIGURES     := outputs/figures/temperature_series.png \
               outputs/figures/temperature_climatology.png \
               outputs/figures/temperature_ytd.png
ANNUAL      := outputs/annual_temperatures.csv
STATS       := data/processed/trend_stats.rds
REPORT      := outputs/temperature_report.html

.PHONY: all prepare plots report open clean

all: report

# ---- stage 00: raw .csv.gz -> small gzipped station extract -----------------
prepare: $(EXTRACT)
$(EXTRACT): $(RAW_GZ) R/00_prepare_data.R R/config.R
	$(RSCRIPT) R/00_prepare_data.R

# ---- stage 01: figures + annual table + stats -------------------------------
plots: $(FIGURES) $(ANNUAL) $(STATS)
$(FIGURES) $(ANNUAL) $(STATS): R/01_plot.R R/config.R $(EXTRACT)
	$(RSCRIPT) R/01_plot.R

# ---- stage 02: HTML report --------------------------------------------------
report: $(REPORT)
$(REPORT): R/02_report.R R/config.R $(FIGURES) $(ANNUAL) $(STATS)
	$(RSCRIPT) R/02_report.R

open: $(REPORT)
	open $(REPORT)

clean:
	rm -f $(FIGURES) $(ANNUAL) $(STATS) $(REPORT) $(EXTRACT)
