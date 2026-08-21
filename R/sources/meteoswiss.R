# =============================================================================
# Source module — MeteoSwiss Open Government Data (daily station data).
#
# Publishes one plain-text (uncompressed) semicolon CSV per station per
# "granularity", split into two files that between them cover the whole
# record: "historical" (reviewed, ends at the previous calendar-year
# boundary) and "recent" (rolling, current calendar year to date). Two
# datasets: NBCN (homogeneous long-term climate stations — temperature only,
# no daily precipitation) and SMN (automatic network — temperature +
# precipitation in one file, shorter history). Mirror used here (plain
# HTTPS, no credentials — MeteoSwiss Open Data, attribution-only licence).
#
# Contract every R/sources/<source>.R module must satisfy: define
# prepare_data(site), which fetches whatever is missing under site$paths$raw,
# slices/normalizes to columns NUM_POSTE, AAAAMMJJ, TN, TX, TNTXM, RR, and
# writes that via write_extract() to site$paths$processed/<STATION_EXTRACT>.
# =============================================================================

# Rolling files — the only raw files that change between refreshes. For every
# distinct (dataset, station) pair the site needs, the "recent" file rolls
# (current calendar year to date); the "historical" file is closed at the
# previous year-end and stable, so refresh-rolling leaves it alone. This mirrors
# the pair-collection in prepare_data() so the two never drift.
rolling_files <- function(site) {
  ms <- site$meteoswiss
  paths <- character(0)
  seen  <- character(0)
  for (abbr in names(ms$stations)) {
    st <- ms$stations[[abbr]]
    for (dataset in unique(c(st$temp_dataset, st$rain_dataset))) {
      combo <- paste(dataset, abbr)
      if (combo %in% seen) next
      seen <- c(seen, combo)
      paths <- c(paths, file.path(site$paths$raw,
                                  sprintf("ogd-%s_%s_d_recent.csv", dataset, tolower(abbr))))
    }
  }
  paths
}

prepare_data <- function(site) {
  suppressPackageStartupMessages(library(data.table))
  dir.create(site$paths$processed, recursive = TRUE, showWarnings = FALSE)
  dir.create(site$paths$raw,       recursive = TRUE, showWarnings = FALSE)

  ms <- site$meteoswiss

  # column names (fread `select=`) and NA-normalised names, per dataset. NBCN
  # carries no daily precipitation column at all; SMN carries temperature and
  # precipitation in the same file. Both give TN/TX; we deliberately do NOT
  # read either dataset's own precomputed daily mean (ths200d0 / tre200d0) —
  # TNTXM is always computed downstream as (TN+TX)/2, so the mean is
  # methodologically consistent across every source in this pipeline (see
  # R/lib/common.R).
  col_map <- list(
    nbcn = c(reference_timestamp = "reference_timestamp",
             ths200dn = "TN", ths200dx = "TX"),
    smn  = c(reference_timestamp = "reference_timestamp",
             tre200dn = "TN", tre200dx = "TX", rre150d0 = "RR")
  )

  raw_path <- function(dataset, abbr, kind)
    file.path(site$paths$raw, sprintf("ogd-%s_%s_d_%s.csv", dataset, tolower(abbr), kind))

  # ---- fetch step ------------------------------------------------------------
  # Two stations can need the same dataset (e.g. both SMA and REH pull from
  # smn); one station can need two different datasets (SMA: temp from nbcn,
  # rain from smn). Collect the distinct (dataset, abbr) pairs actually needed
  # first, so a dataset shared by two stations is only fetched once.
  seen <- character(0)
  raw_paths <- character(0)
  for (abbr in names(ms$stations)) {
    st <- ms$stations[[abbr]]
    for (dataset in unique(c(st$temp_dataset, st$rain_dataset))) {
      combo <- paste(dataset, abbr)
      if (combo %in% seen) next
      seen <- c(seen, combo)
      for (kind in c("historical", "recent")) {
        dest <- raw_path(dataset, abbr, kind)
        raw_paths <- c(raw_paths, dest)
        if (!file.exists(dest)) {
          url <- file.path(ms$base_url, sprintf("ch.meteoschweiz.ogd-%s", dataset), tolower(abbr),
                            sprintf("ogd-%s_%s_d_%s.csv", dataset, tolower(abbr), kind))
          fetch_url(url, dest, verify_text, on_404_hint = sprintf(
            "If this is a 404, station %s may not have a %s dataset — check meteoswiss$stations in R/sites/%s.R.",
            abbr, dataset, site$key))
        }
      }
    }
  }

  extract_gz <- file.path(site$paths$processed, STATION_EXTRACT)
  inputs <- c(raw_paths, "R/sources/meteoswiss.R", sprintf("R/sites/%s.R", site$key))
  if (file.exists(extract_gz) &&
      file.info(extract_gz)$mtime >= max(file.info(inputs)$mtime)) {
    message("up to date: ", extract_gz)
    return(invisible(NULL))
  }

  # ---- read step --------------------------------------------------------------
  # Cache one combined (historical + recent) table per (dataset, abbr) pair, so
  # a station whose temp and rain come from the same dataset (e.g. REH: both
  # from smn) reads that file's pair only once.
  cache <- new.env(parent = emptyenv())

  read_dataset <- function(dataset, abbr) {
    key <- paste(dataset, abbr)
    if (!is.null(cache[[key]])) return(cache[[key]])

    colmap <- col_map[[dataset]]
    read_one <- function(kind) {
      d <- fread(raw_path(dataset, abbr, kind), sep = ";", select = unname(names(colmap)))
      setnames(d, names(colmap), colmap)
      # reference_timestamp is always "DD.MM.YYYY 00:00" for daily granularity
      # (fixed-width, zero-padded) — split the date part on "." rather than
      # paying for a full date-parser on ~60k rows/file.
      ymd <- tstrsplit(substr(d$reference_timestamp, 1, 10), ".", fixed = TRUE)
      d[, AAAAMMJJ := as.integer(ymd[[3]]) * 10000L + as.integer(ymd[[2]]) * 100L + as.integer(ymd[[1]])]
      d[, reference_timestamp := NULL]
      d
    }

    hist <- read_one("historical")
    rec  <- read_one("recent")
    # Observed in practice (fetched Aug 2026): MeteoSwiss's "historical" file
    # ends at the previous calendar-year boundary (...31.12.2025) and "recent"
    # starts exactly the day after (01.01.2026) — no overlapping AAAAMMJJ for
    # either dataset/station checked here, and no duplicate dates within
    # either file. Still dedupe defensively in case that ever changes: keep
    # the "recent" row on any date present in both, since it is the more
    # recently refreshed of the two files for that date.
    both <- rbindlist(list(hist, rec), fill = TRUE)
    setorder(both, AAAAMMJJ)
    combined <- both[!duplicated(AAAAMMJJ, fromLast = TRUE)]

    cache[[key]] <- combined
    combined
  }

  # ---- normalize step ---------------------------------------------------------
  build_station <- function(abbr) {
    st <- ms$stations[[abbr]]
    temp_dt <- read_dataset(st$temp_dataset, abbr)
    if (!all(c("TN", "TX") %in% names(temp_dt)))
      stop(sprintf("meteoswiss$stations$%s$temp_dataset = '%s' has no TN/TX columns", abbr, st$temp_dataset))
    temp_dt <- temp_dt[, .(AAAAMMJJ, TN, TX)]

    rain_dt <- read_dataset(st$rain_dataset, abbr)
    if (!("RR" %in% names(rain_dt)))
      stop(sprintf("meteoswiss$stations$%s$rain_dataset = '%s' has no RR column", abbr, st$rain_dataset))
    rain_dt <- rain_dt[, .(AAAAMMJJ, RR)]

    merged <- if (st$temp_dataset == st$rain_dataset && identical(temp_dt$AAAAMMJJ, rain_dt$AAAAMMJJ)) {
      temp_dt[, RR := rain_dt$RR]
      temp_dt
    } else {
      merge(temp_dt, rain_dt, by = "AAAAMMJJ", all = TRUE)   # full outer join: keep NA, don't drop rows
    }

    merged[, TNTXM := (TN + TX) / 2]                          # always derived, never the source's own mean
    merged[, NUM_POSTE := abbr]                                # exact abbreviation, matches site$stations keys
    merged
  }

  message("Building station extract for: ", paste(names(ms$stations), collapse = ", "))
  slice <- rbindlist(lapply(names(ms$stations), build_station))
  slice <- slice[, .(NUM_POSTE, AAAAMMJJ, TN, TX, TNTXM, RR)]

  write_extract(slice, extract_gz)
}
