# =============================================================================
# Castanet-Tolosan temperature analysis — reproducible pipeline
#   make all      run the full pipeline (prepare -> plots -> report)
#   make prepare  fetch missing raw .csv.gz -> small gzipped station extract
#   make refresh  re-download the current era and rebuild everything
#   make plots    build the three figures + annual table + stats
#   make report   build the self-contained HTML report
#   make readme   inject the same report into README.md (between its markers)
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
README      := README.md

.PHONY: all prepare refresh plots report readme open clean

all: report readme

# ---- stage 00: fetch raw .csv.gz (if absent) -> small gzipped station extract -
# RAW_GZ is a wildcard, so on a fresh clone (empty data/raw) it expands to
# nothing — that is fine and intended: stage 00 downloads what it needs. It is
# only listed so that dropping in a newer raw file re-triggers the slice.
prepare: $(EXTRACT)
$(EXTRACT): $(RAW_GZ) R/00_prepare_data.R R/config.R
	$(RSCRIPT) R/00_prepare_data.R

# force a re-download of the current era, then rebuild everything downstream
refresh:
	rm -f data/raw/Q_31_latest-*.csv.gz $(EXTRACT)
	$(MAKE) all

# ---- stage 01: figures + annual table + stats -------------------------------
plots: $(FIGURES) $(ANNUAL) $(STATS)
$(FIGURES) $(ANNUAL) $(STATS): R/01_plot.R R/config.R $(EXTRACT)
	$(RSCRIPT) R/01_plot.R

# ---- stage 02: HTML report --------------------------------------------------
report: $(REPORT)
$(REPORT): R/02_report.R R/config.R $(FIGURES) $(ANNUAL) $(STATS)
	$(RSCRIPT) R/02_report.R

# ---- stage 03: the same report, as Markdown inside README.md ----------------
# README.md is version-controlled and only partly generated — stage 03 rewrites
# the block between its BEGIN/END REPORT markers and leaves the rest alone.
# `clean` therefore does NOT delete it.
readme: $(README)
$(README): R/03_readme.R R/config.R $(FIGURES) $(ANNUAL) $(STATS)
	$(RSCRIPT) R/03_readme.R

open: $(REPORT)
	open $(REPORT)

# NOTE: $(FIGURES) are tracked (README.md renders them), so `clean` leaves the
# working tree dirty until `make plots` regenerates them — or restore with
# `git checkout -- outputs/figures`. README.md itself is never removed.
clean:
	rm -f $(FIGURES) $(ANNUAL) $(STATS) $(REPORT) $(EXTRACT)
