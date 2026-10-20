# =============================================================================
# Source module — Météo-France daily climatological base (RR-T-Vent).
#
# Publishes gzipped semicolon CSVs, one set per department, split into three
# "eras" that ROTATE every January (see R/sites/castanet.R for the caveat).
# Mirror used here (plain HTTPS, no credentials — Licence Ouverte / Etalab).
#
# Contract every R/sources/<source>.R module must satisfy: define
# prepare_data(site), which fetches whatever is missing under site$paths$raw,
# slices/normalizes to columns NUM_POSTE, AAAAMMJJ, TN, TX, TNTXM, RR, and
# writes that via write_extract() to site$paths$processed/<STATION_EXTRACT>.
# =============================================================================

# The era names encode years and rotate each January, so hand-copied names in
# R/sites/*.R would all 404 at once when the year turns. Ask the mirror instead:
# both hosts are S3 buckets that answer a ListObjectsV2 query, and the listing
# for one department's prefix names exactly its current eras. The site file's
# `eras` remains as the offline fallback (no network, or a listing that does not
# show exactly one avant/previous/latest file). Cached per department per run.
mf_era_cache <- new.env()
mf_eras <- function(site) {
  mf <- site$meteofrance
  if (!is.null(mf_era_cache[[mf$dept]])) return(mf_era_cache[[mf$dept]])
  bucket <- sub("/data/synchro_ftp/.*$", "", mf$base_url)
  prefix <- sprintf("data/synchro_ftp/BASE/QUOT/Q_%s_", mf$dept)
  listing <- suppressWarnings(tryCatch(
    system2("curl", c("-fsS", "--max-time", "30",
                      shQuote(sprintf("%s/?list-type=2&prefix=%s", bucket, prefix))),
            stdout = TRUE, stderr = FALSE),
    error = function(e) character(0)))
  pat   <- sprintf("Q_%s_((avant|previous|latest)[-0-9]*)_RR-T-Vent\\.csv\\.gz", mf$dept)
  found <- unique(sub(pat, "\\1", unlist(regmatches(listing, gregexpr(pat, listing)))))
  kind  <- sub("-.*$", "", found)
  eras <- if (identical(sort(kind), c("avant", "latest", "previous"))) {
    found[order(match(kind, c("avant", "previous", "latest")))]
  } else {
    message("  could not list Météo-France eras for dept ", mf$dept,
            " — falling back to meteofrance$eras in R/sites/", site$key, ".R")
    mf$eras
  }
  if (!identical(eras, mf$eras))
    message("  Météo-France eras for dept ", mf$dept, " are now ", paste(eras, collapse = ", "),
            " — update the fallback meteofrance$eras in R/sites/", site$key, ".R")
  mf_era_cache[[mf$dept]] <- eras
  eras
}

# Rolling files — the only raw files that change between refreshes. The three
# eras are ordered oldest -> newest; only the newest (`latest-*`) gains rows.
# `avant-1949` and the closed `previous-*` era are stable, so refresh-rolling
# leaves them alone. After a January rotation the new `previous-*` name is
# absent locally too, so the next prepare fetches it once — which is correct,
# since the old latest era's rows have moved into it.
rolling_files <- function(site) {
  eras <- mf_eras(site)
  file.path(site$paths$raw, sprintf("Q_%s_%s_RR-T-Vent.csv.gz",
                                    site$meteofrance$dept, eras[length(eras)]))
}

prepare_data <- function(site) {
  suppressPackageStartupMessages(library(data.table))
  ensure_site_dirs(site)

  mf <- site$meteofrance
  rr_t_vent_gz <- sprintf("Q_%s_%s_RR-T-Vent.csv.gz", mf$dept, mf_eras(site))
  gz_paths <- file.path(site$paths$raw, rr_t_vent_gz)

  for (i in seq_along(gz_paths))
    if (!file.exists(gz_paths[i]))
      fetch_url(file.path(mf$base_url, rr_t_vent_gz[i]), gz_paths[i], verify_gz,
                on_404_hint = sprintf(
                  "If this is a 404, the upstream era names have rotated and the listing failed — see meteofrance$eras in R/sites/%s.R.",
                  site$key))

  # Only once the current eras are safely on disk: files from eras that have
  # rotated away are superseded (their rows now live under the new names) and
  # would otherwise sit in the raw dir forever.
  stale <- setdiff(list.files(site$paths$raw, sprintf("^Q_%s_.*_RR-T-Vent\\.csv\\.gz$", mf$dept)),
                   rr_t_vent_gz)
  for (f in stale) { unlink(file.path(site$paths$raw, f)); message("  removed rotated-out era: ", f) }

  # field-definition docs (reference only, not read by the pipeline) — served
  # upstream as `.csv` with CRLF endings despite being plain text; normalise to
  # LF and store as `.txt`.
  for (doc in mf$field_docs) {
    dest <- file.path(site$paths$raw, sprintf("Q_descriptif_champs_%s.txt", doc))
    if (!file.exists(dest))
      fetch_url(file.path(mf$base_url, sprintf("Q_descriptif_champs_%s.csv", doc)), dest,
                function(p) writeLines(sub("\r$", "", readLines(p, warn = FALSE)), p))
  }

  extract_gz <- file.path(site$paths$processed, STATION_EXTRACT)
  if (extract_up_to_date(site, gz_paths)) return(invisible(NULL))

  message("Slicing ", length(gz_paths), " raw .gz files to stations: ",
          paste(names(site$stations), collapse = ", "))

  # TNTXM is always derived as (TN+TX)/2 here, never Météo-France's own
  # TNTXM field, for methodological consistency with the other sites' source
  # modules (see R/sources/dwd.R, R/sources/meteoswiss.R).
  keep_cols <- c("NUM_POSTE", "AAAAMMJJ", "TN", "TX", "RR")
  slice <- rbindlist(lapply(gz_paths, function(f) {
    message("  reading ", basename(f), " ...")
    d <- read_gz(f, select = keep_cols, colClasses = list(character = "NUM_POSTE"))
    d <- d[NUM_POSTE %in% names(site$stations)]
    d[, TNTXM := (TN + TX) / 2]
    d
  }))

  write_extract(slice, extract_gz)
}
