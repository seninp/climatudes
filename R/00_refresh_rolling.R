#!/usr/bin/env Rscript
# =============================================================================
# Refresh helper — delete ONLY a site's rolling raw files (plus its processed
# extract), so the next `make` re-downloads just the data that actually changes
# between refreshes and rebuilds from it. Contrast with `make refresh`, which
# deletes the entire raw tree and re-downloads the multi-MB stable historical
# archives too (wasted transfer — those never change; see the
# climatudes-data-refresh-cadence memory).
#
#   SITE=paris Rscript R/00_refresh_rolling.R
#   (no SITE)  Rscript R/00_refresh_rolling.R   # defaults to castanet
#
# This only deletes; it does not fetch. The Makefile's refresh-rolling target
# runs it and then `make all` to re-download and rebuild.
#
# "Which files roll" is source-specific knowledge, so it lives in each
# R/sources/<source>.R alongside prepare_data(), exposed as rolling_files(site):
# the meteofrance `latest-*` era, DWD `_akt.zip`, MeteoSwiss `_recent.csv`, and
# NOAA's open-ended (future-sentinel) station files roll; the meteoru source is
# hand-fed and returns none, so Moscow/Voronezh are left untouched.
# =============================================================================

suppressPackageStartupMessages(library(data.table))
source("R/lib/common.R")

site_key  <- Sys.getenv("SITE", "castanet")
site_file <- sprintf("R/sites/%s.R", site_key)
if (!file.exists(site_file))
  stop("Unknown SITE '", site_key, "' — expected one of R/sites/*.R (no ", site_file, ")")
source(site_file)   # defines SITE

source(sprintf("R/sources/%s.R", SITE$source))   # defines rolling_files(), prepare_data()

if (!exists("rolling_files"))
  stop("source module R/sources/", SITE$source, ".R defines no rolling_files() — cannot refresh rolling data")

rolling <- rolling_files(SITE)
if (length(rolling) == 0) {
  message("no rolling files for SITE '", site_key, "' (source '", SITE$source,
          "' is manual / nothing auto-fetched) — leaving raw data untouched")
  quit(save = "no", status = 0)
}

removed <- rolling[file.exists(rolling)]
for (f in rolling) {
  if (file.exists(f)) { unlink(f); message("removed rolling raw: ", f) }
  else                  message("absent (nothing to remove): ", f)
}

# Deleting a rolling raw file is not enough on its own: RAW_FILES in the Makefile
# is a wildcard, so a vanished file simply drops out of the prerequisite list and
# the cached extract still looks up to date — stage 00 would not rerun. Delete the
# extract too, so `make` rebuilds it from the freshly re-downloaded rolling data.
extract_gz <- file.path(SITE$paths$processed, STATION_EXTRACT)
if (file.exists(extract_gz)) { unlink(extract_gz); message("removed extract: ", extract_gz) }

message(sprintf("refresh-rolling: SITE '%s' — %d rolling file(s) cleared, extract dropped; run `make` to rebuild",
                site_key, length(removed)))
