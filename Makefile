# =============================================================================
# Climate temperature analysis — reproducible, multi-site pipeline
#   make all               run the full pipeline for one site (prepare -> plots -> report)
#   make all SITE=zurich   ... for a different site (default: castanet)
#   make all-sites         run the full pipeline for every site in R/sites/
#   make prepare           fetch missing raw data -> small gzipped station extract
#   make refresh           re-download the current/rolling raw data and rebuild everything
#   make plots             build the figures + annual table + stats
#   make report            build the self-contained HTML report
#   make readme            inject the same report into README.md (between this site's markers)
#   make open              open the report in the default browser (macOS)
#   make clean             remove this site's generated outputs + cached extract (raw is untouched)
#
# SITE selects R/sites/<SITE>.R, which names the upstream source (Météo-France,
# MeteoSwiss, DWD, ...) and every path/station/citation fact specific to that
# site — see R/lib/common.R and R/sites/*.R.
# =============================================================================

RSCRIPT := Rscript
SITE ?= castanet
SITES := $(basename $(notdir $(wildcard R/sites/*.R)))

# Castanet-Tolosan is the original site and keeps its legacy root-level paths
# (see R/sites/castanet.R); every other site gets its own nested subtree.
ifeq ($(SITE),castanet)
  RAWDIR    := data/raw
  PROCESSED := data/processed
  OUTDIR    := outputs
  FIGDIR    := outputs/figures
else
  RAWDIR    := data/raw/$(SITE)
  PROCESSED := data/processed/$(SITE)
  OUTDIR    := outputs/$(SITE)
  FIGDIR    := outputs/$(SITE)/figures
endif

RAW_FILES   := $(wildcard $(RAWDIR)/*)
EXTRACT     := $(PROCESSED)/stations_daily.csv.gz
FIGURES     := $(FIGDIR)/temperature_series.png \
               $(FIGDIR)/temperature_climatology.png \
               $(FIGDIR)/temperature_ytd.png \
               $(FIGDIR)/rain_series.png \
               $(FIGDIR)/rain_climatology.png
ANNUAL      := $(OUTDIR)/annual_temperatures.csv \
               $(OUTDIR)/annual_rainfall.csv
STATS       := $(PROCESSED)/trend_stats.rds
REPORT      := $(OUTDIR)/temperature_report.html
README      := README.md
SITE_CONFIG := R/sites/$(SITE).R

.PHONY: all all-sites prepare refresh plots report readme open clean

all: report readme

all-sites:
	@for s in $(SITES); do $(MAKE) SITE=$$s all; done

# ---- stage 00: fetch raw data (if absent) -> small gzipped station extract --
# RAW_FILES is a wildcard, so on a fresh clone (empty raw dir) it expands to
# nothing — that is fine and intended: stage 00 downloads what it needs. It is
# only listed so that dropping in a newer raw file re-triggers the slice.
prepare: $(EXTRACT)
$(EXTRACT): $(RAW_FILES) R/00_prepare_data.R R/lib/common.R $(SITE_CONFIG)
	SITE=$(SITE) $(RSCRIPT) R/00_prepare_data.R

# force a re-download of the rolling/current raw data, then rebuild everything
refresh:
	rm -rf $(RAWDIR) $(EXTRACT)
	$(MAKE) SITE=$(SITE) all

# ---- stage 01: figures + annual table + stats -------------------------------
plots: $(FIGURES) $(ANNUAL) $(STATS)
$(FIGURES) $(ANNUAL) $(STATS): R/01_plot.R R/lib/common.R R/lib/narrative.R $(SITE_CONFIG) $(EXTRACT)
	SITE=$(SITE) $(RSCRIPT) R/01_plot.R

# ---- stage 02: HTML report --------------------------------------------------
report: $(REPORT)
$(REPORT): R/02_report.R R/lib/common.R R/lib/narrative.R $(SITE_CONFIG) $(FIGURES) $(ANNUAL) $(STATS)
	SITE=$(SITE) $(RSCRIPT) R/02_report.R

# ---- stage 03: the same report, as Markdown inside README.md ----------------
# README.md is version-controlled and only partly generated — stage 03 rewrites
# the block between this site's BEGIN/END markers and leaves the rest alone.
# `clean` therefore does NOT delete it.
readme: $(README)
$(README): R/03_readme.R R/lib/common.R R/lib/narrative.R $(SITE_CONFIG) $(FIGURES) $(ANNUAL) $(STATS)
	SITE=$(SITE) $(RSCRIPT) R/03_readme.R

open: $(REPORT)
	open $(REPORT)

# NOTE: $(FIGURES) are tracked (README.md renders them), so `clean` leaves the
# working tree dirty until `make plots` regenerates them — or restore from
# version control. README.md itself is never removed.
clean:
	rm -f $(FIGURES) $(ANNUAL) $(STATS) $(REPORT) $(EXTRACT)
