#!/usr/bin/env Rscript
# =============================================================================
# Stage 00 — fetch + prepare data (generic across sites)
#
# SITE (env var, default "castanet") selects R/sites/<SITE>.R, which in turn
# names the source module (R/sources/<source>.R) that knows how to fetch and
# normalize that site's upstream data. Every source module's prepare_data()
# fetches whatever raw files are missing under site$paths$raw, slices/
# normalizes to columns NUM_POSTE, AAAAMMJJ, TN, TX, TNTXM, RR, and caches that
# small extract — gzipped — at site$paths$processed/<STATION_EXTRACT>.
#
#   SITE=zurich    Rscript R/00_prepare_data.R
#   SITE=karlsruhe Rscript R/00_prepare_data.R
#   (no SITE)      Rscript R/00_prepare_data.R   # defaults to castanet
# =============================================================================

suppressPackageStartupMessages(library(data.table))
source("R/lib/common.R")

site_key  <- Sys.getenv("SITE", "castanet")
site_file <- sprintf("R/sites/%s.R", site_key)
if (!file.exists(site_file))
  stop("Unknown SITE '", site_key, "' — expected one of R/sites/*.R (no ", site_file, ")")
source(site_file)   # defines SITE

source(sprintf("R/sources/%s.R", SITE$source))   # defines prepare_data()

prepare_data(SITE)
