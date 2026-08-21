# =============================================================================
# Climate temperature analysis — reproducible, multi-site pipeline
#   make all               run the full pipeline for one site (prepare -> plots -> report)
#   make all SITE=zurich   ... for a different site (default: castanet)
#   make all-sites         run the full pipeline for every site in R/sites/, then compare
#   make compare           rebuild the cross-site comparison (needs every site's stats already built)
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
# Per-site stamp for the README stage. README.md itself CANNOT be the target:
# every site writes into the same file, so the first site's run bumps README.md's
# mtime past every other site's dependencies and `make all-sites` then silently
# skips stages 03 for sites 2..N — leaving their blocks stale while reporting
# "Nothing to be done for 'readme'". Verified: editing R/lib/narrative.R and
# running `make all-sites` regenerated only the first site's block. The stamp
# lives per-site under $(PROCESSED), so each site's staleness is judged against
# its own inputs.
README_STAMP := $(PROCESSED)/readme.stamp

.PHONY: all all-sites compare prepare refresh refresh-rolling refresh-rolling-all-sites plots report readme open clean

all: report readme

all-sites:
	@for s in $(SITES); do $(MAKE) SITE=$$s all; done
	$(MAKE) compare

# ---- cross-site comparison — not parameterized by SITE, needs every site's --
# trend_stats.rds already on disk (run all-sites, or each site's `make plots`,
# first). See R/04_compare.R's own header for why the site list there is
# hand-maintained rather than reusing $(SITES).
compare:
	$(RSCRIPT) R/04_compare.R

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

# ---- surgical refresh: re-download ONLY the rolling files, keep historical ---
# Deletes just the raw files that actually change between refreshes (the newest
# meteofrance era, DWD _akt, MeteoSwiss _recent, NOAA open-ended stations) plus
# the extract, then rebuilds — leaving the stable multi-MB historical archives
# on disk. Contrast `refresh`, which nukes RAWDIR and re-downloads everything.
# "Which files roll" is defined per source in R/sources/<source>.R::rolling_files().
# Manual sources (meteoru: Moscow, Voronezh) report no rolling files, so the
# driver leaves their hand-placed exports and extract untouched.
refresh-rolling:
	SITE=$(SITE) $(RSCRIPT) R/00_refresh_rolling.R
	$(MAKE) SITE=$(SITE) all

refresh-rolling-all-sites:
	@for s in $(SITES); do $(MAKE) SITE=$$s refresh-rolling; done
	$(MAKE) compare

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
#
# The target is $(README_STAMP), not README.md — see its definition above for why
# using the shared file made `make all-sites` skip every site but the first.
readme: $(README_STAMP)
$(README_STAMP): R/03_readme.R R/lib/common.R R/lib/narrative.R $(SITE_CONFIG) $(FIGURES) $(ANNUAL) $(STATS)
	SITE=$(SITE) $(RSCRIPT) R/03_readme.R
	@mkdir -p $(dir $@) && touch $@

open: $(REPORT)
	open $(REPORT)

# NOTE: $(FIGURES) are tracked (README.md renders them), so `clean` leaves the
# working tree dirty until `make plots` regenerates them — or restore from
# version control. README.md itself is never removed.
clean:
	rm -f $(FIGURES) $(ANNUAL) $(STATS) $(REPORT) $(EXTRACT) $(README_STAMP)
