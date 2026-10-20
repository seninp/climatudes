# =============================================================================
# Source module — NOAA GHCN-Daily via the Climate Data Online "Access Data
# Service" (v1), https://www.ncei.noaa.gov/access/services/data/v1. Plain
# HTTPS GET, no credentials, no token — unlike the older CDO v2 API. Returns
# CSV already in the requested units (`units=metric` -> whole °C / mm), so
# unlike the raw fixed-width .dly archive there is no tenths-of-a-unit
# conversion to do here.
#
# A station config may name a `predecessor`: an earlier, physically distinct
# station whose own digitized record ends right where this one's begins (the
# same idea as R/sources/dwd.R's predecessor splice) — used for Santa Fe's
# in-town COOP station (298085, 1972->) spliced onto 298072 (1874-1972).
#
# Contract every R/sources/<source>.R module must satisfy: define
# prepare_data(site), which fetches whatever is missing under site$paths$raw,
# slices/normalizes to columns NUM_POSTE, AAAAMMJJ, TN, TX, TNTXM, RR, and
# writes that via write_extract() to site$paths$processed/<STATION_EXTRACT>.
# =============================================================================

source("R/lib/ghcn.R")   # ghcn_fetch(), ghcn_read() — shared with R/sources/ghcn_iem.R

# Fetch one station's full requested range in a single request (GHCN-Daily
# station histories are small enough — a hundred years is a few hundred KB —
# that there is no need for DWD/MeteoSwiss's historical/recent file split).
# `end` is deliberately requested far in the future (2030-12-31 in the site
# files): the service just returns whatever has actually been published up to
# today, so the end date never 404s — but it does need bumping before 2031.
noaa_fetch_station <- function(base_url, raw_dir, id, start, end)
  ghcn_fetch(base_url, file.path(raw_dir, sprintf("%s_%s_%s.csv", id, start, end)), id, start, end)

noaa_read <- function(path, num_poste) {
  d <- ghcn_read(path)
  d[, `:=`(NUM_POSTE = num_poste, TNTXM = (TN + TX) / 2)]
  setcolorder(d, c("NUM_POSTE", "AAAAMMJJ", "TN", "TX", "TNTXM", "RR"))
  d
}

# Rolling files — the only raw files that change between refreshes. Each main
# station's request runs to the future sentinel `end` (so its file keeps gaining
# rows as NOAA publishes); a `predecessor` is a closed station whose request
# ends at a real past date and never changes, so refresh-rolling leaves it alone.
rolling_files <- function(site) {
  noaa <- site$noaa
  vapply(names(noaa$stations), function(sid) {
    cfg <- noaa$stations[[sid]]
    file.path(site$paths$raw, sprintf("%s_%s_%s.csv", sid, cfg$start, cfg$end))
  }, character(1), USE.NAMES = FALSE)
}

prepare_data <- function(site) {
  suppressPackageStartupMessages(library(data.table))
  ensure_site_dirs(site)

  noaa <- site$noaa
  station_ids <- names(noaa$stations)

  station_files <- lapply(station_ids, function(sid) {
    cfg <- noaa$stations[[sid]]
    main <- noaa_fetch_station(noaa$base_url, site$paths$raw, sid, cfg$start, cfg$end)
    predecessor <- if (!is.null(cfg$predecessor))
      noaa_fetch_station(noaa$base_url, site$paths$raw, cfg$predecessor$id,
                          cfg$predecessor$start, cfg$predecessor$end)
    list(main = main, predecessor = predecessor)
  })
  names(station_files) <- station_ids

  extract_gz <- file.path(site$paths$processed, STATION_EXTRACT)
  raw_paths  <- unlist(lapply(station_files, function(x) c(x$main, x$predecessor)), use.names = FALSE)
  if (extract_up_to_date(site, raw_paths)) return(invisible(NULL))

  message("Reading NOAA GHCN-Daily stations: ", paste(names(site$stations), collapse = ", "))

  slice <- rbindlist(lapply(station_ids, function(sid) {
    f <- station_files[[sid]]
    message("  reading station ", sid, " ...")
    main_n <- noaa_read(f$main, sid)
    if (!is.null(f$predecessor)) {
      message("    splicing predecessor station ...")
      pred_n <- noaa_read(f$predecessor, sid)
      main_n <- rbindlist(list(pred_n, main_n[AAAAMMJJ > max(pred_n$AAAAMMJJ)]))
    }
    main_n
  }))

  write_extract(slice, extract_gz)
}
