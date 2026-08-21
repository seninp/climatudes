# =============================================================================
# Source module — DWD (Deutscher Wetterdienst) Climate Data Center, daily
# station observations. Open data, CC BY 4.0, no credentials.
#
# Two product families live under the same tree, one zip per station/period:
#   kl          - "Kl"imadaten: temperature + precipitation in one file.
#   more_precip - precipitation only (stations with no temperature record).
# Each station/product has a closed "historical" zip (filename embeds its own
# start/end date, e.g. tageswerte_KL_04177_19480101_20251231_hist.zip — DWD
# reissues these with a later end date over time, so the exact name is
# discovered from the live directory listing rather than hardcoded) and a
# rolling "recent" zip (tageswerte_<CODE>_<stationsid>_akt.zip, fixed name,
# last ~18 months) whose start overlaps the tail of historical. Each zip's
# produkt_*.txt uses -999(.9) as its missing-value sentinel throughout.
#
# Contract every R/sources/<source>.R module must satisfy: define
# prepare_data(site), which fetches whatever is missing under site$paths$raw,
# slices/normalizes to columns NUM_POSTE, AAAAMMJJ, TN, TX, TNTXM, RR, and
# writes that via write_extract() to site$paths$processed/<STATION_EXTRACT>.
# =============================================================================

# PRODUCT-CODE embedded in DWD filenames, keyed by the product folder name.
DWD_PRODUCT_CODE <- c(kl = "KL", more_precip = "RR")

# DWD's missing-value sentinel (-999, -999.9, ...) across every numeric field.
dwd_na <- function(x) { x[x <= -999] <- NA_real_; x }

# Discover the current historical zip's filename for one station/product from
# the live directory listing — the embedded start/end dates shift as DWD
# reissues these, so a hardcoded name would eventually go stale (404).
dwd_historical_filename <- function(base_url, product, code, stationsid) {
  idx_url <- paste0(base_url, "/", product, "/historical/")
  tmp <- tempfile()
  on.exit(unlink(tmp), add = TRUE)
  ok <- system2("curl", c("-fsSL", "--max-time", "60", "-o", shQuote(tmp), shQuote(idx_url)))
  if (ok != 0) stop("could not list DWD historical directory: ", idx_url)
  html <- paste(readLines(tmp, warn = FALSE), collapse = "\n")
  pat  <- sprintf("tageswerte_%s_%s_[0-9]{8}_[0-9]{8}_hist\\.zip", code, stationsid)
  hits <- unique(regmatches(html, gregexpr(pat, html))[[1]])
  if (length(hits) == 0)
    stop("no historical zip found for station ", stationsid, " (product ", product,
         ") in ", idx_url, " — filename pattern may have changed upstream")
  if (length(hits) > 1)
    stop("multiple historical zip candidates for station ", stationsid, ": ",
         paste(hits, collapse = ", "))
  hits[[1]]
}

# Extract the single produkt_*.txt data file from a DWD station zip (ignoring
# the various Metadaten_*.{txt,html} sidecar files) and read it, dropping the
# trailing literal "eor" field every row ends with. Extracts to a per-call
# temp dir so nothing is left behind in site$paths$raw.
dwd_read_produkt <- function(zip_path) {
  suppressPackageStartupMessages(library(data.table))
  tmp_dir <- tempfile("dwd_")
  dir.create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)
  ok <- system2("unzip", c("-o", "-q", shQuote(zip_path), "-d", shQuote(tmp_dir)),
                stdout = FALSE, stderr = FALSE)
  if (ok != 0) stop("could not unzip: ", zip_path)
  produkt <- list.files(tmp_dir, pattern = "^produkt_.*\\.txt$", full.names = TRUE)
  if (length(produkt) != 1)
    stop("expected exactly one produkt_*.txt inside ", zip_path, ", found ", length(produkt))
  d <- fread(produkt, sep = ";")
  d[, eor := NULL]
  d
}

# A station config may name a `predecessor`: an earlier, now-closed station
# whose own record ends right where this one's begins (e.g. Karlsruhe's
# Rheinstetten/04177, succeeding the in-city 02522 — see R/sites/karlsruhe.R).
# Predecessors are fetched historical-only: a closed station has no rolling
# "recent" file.
fetch_predecessor <- function(base_url, raw_dir, predecessor) {
  pid  <- predecessor$id
  prod <- predecessor$product
  code <- DWD_PRODUCT_CODE[[prod]]
  hist_name <- dwd_historical_filename(base_url, prod, code, pid)
  hist_path <- file.path(raw_dir, hist_name)
  if (!file.exists(hist_path))
    fetch_url(file.path(base_url, prod, "historical", hist_name), hist_path, verify_zip)
  list(product = prod, hist = hist_path)
}

# Splice a predecessor's full run in ahead of the successor's own combined
# (historical+recent) rows, keeping the successor's rows only for dates after
# the predecessor's last one — so a successor that itself carries older,
# pre-handoff rows for a *different* physical site (Rheinstetten ran as
# "Forchheim" 1948-85 before the 2008 handoff from 02522) doesn't shadow the
# predecessor's more representative, gap-free record for that same window.
splice_predecessor <- function(successor_rows, predecessor_rows) {
  rbindlist(list(predecessor_rows,
                 successor_rows[AAAAMMJJ > max(predecessor_rows$AAAAMMJJ)]))
}

# Map one station's raw DWD columns (product-specific) onto the pipeline's
# shared shape. `more_precip` stations have no temperature record at all, so
# TN/TX/TNTXM are NA_real_ for every row; `kl` stations get TNTXM computed
# from TN/TX here (not DWD's own TMK mean field), for methodological
# consistency with how the other sites' source modules derive their mean.
dwd_normalize <- function(d, product, num_poste) {
  if (product == "kl") {
    tn <- dwd_na(d$TNK)
    tx <- dwd_na(d$TXK)
    data.table(
      NUM_POSTE = num_poste,
      AAAAMMJJ  = as.integer(d$MESS_DATUM),
      TN        = tn,
      TX        = tx,
      TNTXM     = (tn + tx) / 2,
      RR        = dwd_na(d$RSK)
    )
  } else if (product == "more_precip") {
    data.table(
      NUM_POSTE = num_poste,
      AAAAMMJJ  = as.integer(d$MESS_DATUM),
      TN        = NA_real_,
      TX        = NA_real_,
      TNTXM     = NA_real_,
      RR        = dwd_na(d$RS)
    )
  } else {
    stop("unknown DWD product '", product, "'")
  }
}

# Rolling files — the only raw files that change between refreshes. Each active
# station's "recent" (akt) zip rolls (fixed name, last ~18 months); the
# date-stamped "historical" zips and any predecessor (closed station,
# historical-only) are stable, so refresh-rolling leaves them alone.
rolling_files <- function(site) {
  dwd <- site$dwd
  vapply(names(dwd$stations), function(sid) {
    code <- DWD_PRODUCT_CODE[[dwd$stations[[sid]]$product]]
    file.path(site$paths$raw, sprintf("tageswerte_%s_%s_akt.zip", code, sid))
  }, character(1), USE.NAMES = FALSE)
}

prepare_data <- function(site) {
  suppressPackageStartupMessages(library(data.table))
  dir.create(site$paths$processed, recursive = TRUE, showWarnings = FALSE)
  dir.create(site$paths$raw,       recursive = TRUE, showWarnings = FALSE)

  dwd <- site$dwd
  station_ids <- names(dwd$stations)

  # Resolve every station's raw zip paths (fetching whatever is missing)
  # before deciding whether the cached extract is still fresh — the historical
  # filename must be discovered from the live listing regardless, since it can
  # only be compared against a local file once we know what to call it.
  station_files <- lapply(station_ids, function(sid) {
    cfg <- dwd$stations[[sid]]
    product <- cfg$product
    if (!product %in% names(DWD_PRODUCT_CODE))
      stop("unknown DWD product '", product, "' for station ", sid,
           " — expected one of: ", paste(names(DWD_PRODUCT_CODE), collapse = ", "))
    code <- DWD_PRODUCT_CODE[[product]]

    hist_name <- dwd_historical_filename(dwd$base_url, product, code, sid)
    hist_path <- file.path(site$paths$raw, hist_name)
    if (!file.exists(hist_path))
      fetch_url(file.path(dwd$base_url, product, "historical", hist_name), hist_path, verify_zip)

    akt_name <- sprintf("tageswerte_%s_%s_akt.zip", code, sid)
    akt_path <- file.path(site$paths$raw, akt_name)
    if (!file.exists(akt_path))
      fetch_url(file.path(dwd$base_url, product, "recent", akt_name), akt_path, verify_zip)

    predecessor <- if (!is.null(cfg$predecessor))
      fetch_predecessor(dwd$base_url, site$paths$raw, cfg$predecessor)

    list(product = product, hist = hist_path, akt = akt_path, predecessor = predecessor)
  })
  names(station_files) <- station_ids

  extract_gz <- file.path(site$paths$processed, STATION_EXTRACT)
  raw_paths  <- unlist(lapply(station_files, function(x)
    c(x$hist, x$akt, x$predecessor$hist)), use.names = FALSE)
  inputs <- c(raw_paths, "R/sources/dwd.R", sprintf("R/sites/%s.R", site$key))
  if (file.exists(extract_gz) &&
      file.info(extract_gz)$mtime >= max(file.info(inputs)$mtime)) {
    message("up to date: ", extract_gz)
    return(invisible(NULL))
  }

  message("Slicing DWD raw zips to stations: ",
          paste(names(site$stations), collapse = ", "))

  slice <- rbindlist(lapply(station_ids, function(sid) {
    f <- station_files[[sid]]
    message("  reading station ", sid, " (", f$product, ") ...")
    hist_n <- dwd_normalize(dwd_read_produkt(f$hist), f$product, sid)
    akt_n  <- dwd_normalize(dwd_read_produkt(f$akt),  f$product, sid)
    # historical and recent overlap by design (recent covers the last ~18
    # months); keep recent's row for any date present in both, since it's
    # fresher. hist rows come first, so fromLast = TRUE prefers akt's rows.
    combined <- rbindlist(list(hist_n, akt_n))
    combined <- unique(combined, by = "AAAAMMJJ", fromLast = TRUE)

    if (!is.null(f$predecessor)) {
      message("    splicing predecessor station (", f$predecessor$product, ") ...")
      pred_n <- dwd_normalize(dwd_read_produkt(f$predecessor$hist), f$predecessor$product, sid)
      combined <- splice_predecessor(combined, pred_n)
    }
    combined
  }))

  write_extract(slice, extract_gz)
}
