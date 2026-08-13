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

prepare_data <- function(site) {
  suppressPackageStartupMessages(library(data.table))
  dir.create(site$paths$processed, recursive = TRUE, showWarnings = FALSE)
  dir.create(site$paths$raw,       recursive = TRUE, showWarnings = FALSE)

  mf <- site$meteofrance
  rr_t_vent_gz <- sprintf("Q_%s_%s_RR-T-Vent.csv.gz", mf$dept, mf$eras)
  gz_paths <- file.path(site$paths$raw, rr_t_vent_gz)

  for (i in seq_along(gz_paths))
    if (!file.exists(gz_paths[i]))
      fetch_url(file.path(mf$base_url, rr_t_vent_gz[i]), gz_paths[i], verify_gz,
                on_404_hint = sprintf(
                  "If this is a 404, the upstream era names have rotated — see meteofrance$eras in R/sites/%s.R.",
                  site$key))

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
  inputs <- c(gz_paths, "R/sources/meteofrance.R", sprintf("R/sites/%s.R", site$key))
  if (file.exists(extract_gz) &&
      file.info(extract_gz)$mtime >= max(file.info(inputs)$mtime)) {
    message("up to date: ", extract_gz)
    return(invisible(NULL))
  }

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
