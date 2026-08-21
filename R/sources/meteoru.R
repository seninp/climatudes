# =============================================================================
# Source module — Roshydromet daily station data, manually exported from the
# AISORI-M portal (aisori-m.meteo.ru). That portal is a login/session-gated
# web app, not a stable URL — unlike every other source module here,
# prepare_data() does NOT download anything. It expects the site's raw
# directory to already contain the export .zip (see R/sites/moscow.R /
# voronezh.R and the "moscow-aisori-m-data-source" memory for the exact query
# steps) and errors with instructions if none is found.
#
# Export format: a ZIP containing wr<code>.txt, semicolon-delimited, one row
# per station/date, 14 fields:
#   WMO;YEAR;MONTH;DAY;QFLAG;TN;TN.Q;TM;TM.Q;TX;TX.Q;RR;RR.extra;RR.Q
# (TM, the source's own daily mean, is read but unused — TNTXM is always
# derived as (TN+TX)/2 here, for consistency with every other source module.)
# Missing values are blank with their per-field ".Q" flag = "9"; "0" marks a
# trustworthy value — anything else is treated as untrustworthy and nulled.
#
# A query spanning a full calendar year emits one row per calendar day even
# for dates with no data at all (e.g. the remainder of the current year, or
# before the station existed) — rows where TN, TX and RR are ALL blank carry
# no information and are dropped here, so a site's own `cur_year`
# (R/01_plot.R, `max(dat$year)`) reflects its last genuinely reported date,
# not the query's requested end date.
#
# Contract every R/sources/<source>.R module must satisfy: define
# prepare_data(site), which fetches whatever is missing under site$paths$raw,
# slices/normalizes to columns NUM_POSTE, AAAAMMJJ, TN, TX, TNTXM, RR, and
# writes that via write_extract() to site$paths$processed/<STATION_EXTRACT>.
# =============================================================================

meteoru_find_export <- function(raw_dir) {
  zips <- list.files(raw_dir, pattern = "\\.zip$", full.names = TRUE)
  if (length(zips) == 0)
    stop("No AISORI-M export found in ", raw_dir, " — this source is manual, not ",
         "auto-fetched (aisori-m.meteo.ru is login-gated, no stable URL to script). ",
         "Export the station's FULL year (month range 1-12, day range 1-31) from ",
         "AISORI-M and place the downloaded .zip in ", raw_dir, ". See the ",
         "moscow-aisori-m-data-source memory for the exact query steps.")
  zips[[which.max(file.info(zips)$mtime)]]   # most recently added export wins
}

meteoru_read <- function(zip_path, wmo_id) {
  suppressPackageStartupMessages(library(data.table))
  tmp_dir <- tempfile("meteoru_")
  dir.create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)
  ok <- system2("unzip", c("-o", "-q", shQuote(zip_path), "-d", shQuote(tmp_dir)),
                stdout = FALSE, stderr = FALSE)
  if (ok != 0) stop("could not unzip: ", zip_path)
  wr <- list.files(tmp_dir, pattern = "^wr.*\\.txt$", full.names = TRUE)
  if (length(wr) != 1)
    stop("expected exactly one wr*.txt inside ", zip_path, ", found ", length(wr))

  d <- fread(wr, sep = ";", header = FALSE,
             col.names = c("WMO", "YEAR", "MONTH", "DAY", "QFLAG",
                           "TN", "TN_Q", "TM", "TM_Q", "TX", "TX_Q",
                           "RR", "RR_EXTRA", "RR_Q"),
             colClasses = "character")
  d <- d[trimws(WMO) == as.character(wmo_id)]
  if (nrow(d) == 0)
    stop("station ", wmo_id, " not found in ", zip_path, " — check statlist*.txt inside it")

  qc_num <- function(val, qflag) {
    x <- suppressWarnings(as.numeric(val))
    x[trimws(qflag) != "0"] <- NA_real_
    x
  }
  tn <- qc_num(d$TN, d$TN_Q)
  tx <- qc_num(d$TX, d$TX_Q)
  rr <- qc_num(d$RR, d$RR_Q)
  out <- data.table(
    NUM_POSTE = as.character(wmo_id),
    AAAAMMJJ  = as.integer(sprintf("%04d%02d%02d",
                           as.integer(d$YEAR), as.integer(d$MONTH), as.integer(d$DAY))),
    TN = tn, TX = tx, TNTXM = (tn + tx) / 2, RR = rr
  )
  out[!(is.na(TN) & is.na(TX) & is.na(RR))]
}

# Rolling files — none. This source is hand-fed (AISORI-M is login-gated, no
# stable URL to script), so there is nothing to auto-re-download; the export .zip
# and its extract must never be deleted by a refresh. Returning character(0)
# makes refresh-rolling skip Moscow/Voronezh entirely.
rolling_files <- function(site) character(0)

prepare_data <- function(site) {
  suppressPackageStartupMessages(library(data.table))
  dir.create(site$paths$processed, recursive = TRUE, showWarnings = FALSE)
  dir.create(site$paths$raw,       recursive = TRUE, showWarnings = FALSE)

  extract_gz <- file.path(site$paths$processed, STATION_EXTRACT)

  # This source is hand-fed, so "no raw export present" is a normal state rather
  # than a failure — the export is login-gated and deliberately not committed
  # (its licence forbids redistribution). If the processed extract already exists
  # we keep it and stop here.
  #
  # Without this, `make all-sites` hard-fails on Moscow and Voronezh after ANY
  # edit to a shared file: the extract goes stale against R/lib/common.R, make
  # tries to rebuild it from raw, and stage 00 aborts because there is nothing to
  # rebuild it from. The other nine sites re-download and carry on; these two
  # cannot. Only error when there is no extract either, which is the genuine
  # fresh-clone case the message below is for.
  if (!length(Sys.glob(file.path(site$paths$raw, "*.zip")))) {
    if (file.exists(extract_gz)) {
      message("no new AISORI-M export in ", site$paths$raw,
              " — keeping the existing extract (manual source, nothing to fetch)")
      return(invisible(NULL))
    }
    meteoru_find_export(site$paths$raw)   # no export and no extract: real error
  }

  zip_path <- meteoru_find_export(site$paths$raw)
  inputs <- c(zip_path, "R/sources/meteoru.R", sprintf("R/sites/%s.R", site$key))
  if (file.exists(extract_gz) &&
      file.info(extract_gz)$mtime >= max(file.info(inputs)$mtime)) {
    message("up to date: ", extract_gz)
    return(invisible(NULL))
  }

  message("Reading Roshydromet/AISORI-M export: ", basename(zip_path))
  slice <- rbindlist(lapply(names(site$stations), function(sid) {
    message("  reading station ", sid, " ...")
    meteoru_read(zip_path, sid)
  }))

  write_extract(slice, extract_gz)
}
