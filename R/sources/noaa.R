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

# Fetch one station's full requested range in a single request (GHCN-Daily
# station histories are small enough — a hundred years is a few hundred KB —
# that there is no need for DWD/MeteoSwiss's historical/recent file split).
# `end` is deliberately requested far in the future: the service just returns
# whatever has actually been published up to today, so a fixed future end
# date never needs bumping and never 404s.
noaa_fetch_station <- function(base_url, raw_dir, id, start, end) {
  dest <- file.path(raw_dir, sprintf("%s_%s_%s.csv", id, start, end))
  if (!file.exists(dest)) {
    url <- sprintf(
      "%s?dataset=daily-summaries&stations=%s&startDate=%s&endDate=%s&format=csv&units=metric&dataTypes=TMAX,TMIN,PRCP&includeAttributes=true",
      base_url, id, start, end)
    fetch_url(url, dest, verify_text, on_404_hint = sprintf(
      "station %s may not exist in GHCN-Daily, or has no data between %s and %s.",
      id, start, end))
  }
  dest
}

# Each element's *_ATTRIBUTES column is "MFLAG,QFLAG,SFLAG[,...]" — the daily-
# summaries endpoint returns the raw value even when GHCN's own QC has flagged
# it (e.g. QFLAG "G", failed gap check — seen in practice: a -50 degC August
# TMIN at Santa Fe, 1901-08-25, physically impossible for that station/season).
# A non-empty QFLAG means "do not trust this value" — null it out here rather
# than downstream, so every stage after stage 00 sees only QC-passed values.
noaa_qflag_ok <- function(attrs) {
  # A station/date with no reading at all for this element (e.g. a rain-only
  # station has no TMAX/TMIN column data) makes fread() infer the whole
  # *_ATTRIBUTES column as logical NA rather than character — coerce first so
  # strsplit() never sees a non-character vector.
  attrs <- as.character(attrs)
  qflag <- vapply(strsplit(attrs, ",", fixed = TRUE), function(x)
    if (length(x) >= 2) x[[2]] else "", character(1))
  is.na(attrs) | qflag == ""
}

noaa_read <- function(path, num_poste) {
  suppressPackageStartupMessages(library(data.table))
  d <- fread(path)
  tn <- as.numeric(d$TMIN)
  tx <- as.numeric(d$TMAX)
  rr <- as.numeric(d$PRCP)
  tn[!noaa_qflag_ok(d$TMIN_ATTRIBUTES)] <- NA_real_
  tx[!noaa_qflag_ok(d$TMAX_ATTRIBUTES)] <- NA_real_
  rr[!noaa_qflag_ok(d$PRCP_ATTRIBUTES)] <- NA_real_
  data.table(
    NUM_POSTE = num_poste,
    AAAAMMJJ  = as.integer(gsub("-", "", d$DATE, fixed = TRUE)),
    TN        = tn,
    TX        = tx,
    TNTXM     = (tn + tx) / 2,
    RR        = rr
  )
}

prepare_data <- function(site) {
  suppressPackageStartupMessages(library(data.table))
  dir.create(site$paths$processed, recursive = TRUE, showWarnings = FALSE)
  dir.create(site$paths$raw,       recursive = TRUE, showWarnings = FALSE)

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
  inputs <- c(raw_paths, "R/sources/noaa.R", sprintf("R/sites/%s.R", site$key))
  if (file.exists(extract_gz) &&
      file.info(extract_gz)$mtime >= max(file.info(inputs)$mtime)) {
    message("up to date: ", extract_gz)
    return(invisible(NULL))
  }

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
