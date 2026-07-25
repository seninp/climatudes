#!/usr/bin/env Rscript
# =============================================================================
# Stage 00 — fetch + prepare data
#
# FETCH: downloads whatever raw Météo-France files are missing from data/raw/
# (nothing is version-controlled — data/raw/ is regenerable from upstream), then
# SLICE: reads them DIRECTLY (streamed, never written out decompressed), keeps
# just the stations we analyse, and caches that small extract — also gzipped —
# at data/processed/<STATION_EXTRACT>.
#
# Why: the raw zips are ~10 MB; fully decompressed they are ~140 MB. The two
# stations we need are a tiny fraction, so we keep everything compressed and
# only ever materialise the small slice (~0.35 MB).
#
# Idempotent twice over: a file already on disk is never re-downloaded, and the
# slice is skipped if the extract is newer than every raw file + this code. To
# force a refresh of the current era (the only one that changes day to day):
#   rm data/raw/Q_31_latest-*.csv.gz && make prepare
#
# See R/config.R for the mirror URL and the era-naming caveat (names rotate every
# January and the old ones start returning 404).
# =============================================================================

suppressPackageStartupMessages(library(data.table))
source("R/config.R")

dir.create(PATHS$processed, recursive = TRUE, showWarnings = FALSE)
dir.create(PATHS$raw,       recursive = TRUE, showWarnings = FALSE)

# ---- fetch: download any raw file we do not already have --------------------
# curl over plain HTTPS, no credentials (Licence Ouverte). Downloads to a temp
# file and only moves it into place once it is verified, so an interrupted or
# truncated transfer can never leave a corrupt file that looks cached.
fetch <- function(url, dest, verify) {
  message("  downloading ", basename(dest), " ...")
  tmp <- paste0(dest, ".part")
  on.exit(unlink(tmp), add = TRUE)
  ok <- system2("curl", c("-fsSL", "--max-time", "600", "-o", shQuote(tmp), shQuote(url)))
  if (ok != 0 || !file.exists(tmp) || file.size(tmp) == 0)
    stop("download failed (curl exit ", ok, "): ", url,
         "\nIf this is a 404, the upstream era names have rotated — see MF_ERAS in R/config.R.")
  verify(tmp)                       # integrity / format check before committing
  if (!file.rename(tmp, dest)) stop("could not move ", tmp, " into place")
  message(sprintf("    ok (%.1f MB)", file.size(dest) / 1024^2))
}

# gzipped data: verify the archive is complete and readable.
verify_gz <- function(p) if (system2("gzip", c("-t", shQuote(p)),
                                     stdout = FALSE, stderr = FALSE) != 0)
  stop("downloaded file is not a valid gzip archive: ", p)

gz_paths <- file.path(PATHS$raw, RR_T_VENT_GZ)
for (i in seq_along(gz_paths))
  if (!file.exists(gz_paths[i]))
    fetch(file.path(MF_BASE_URL, RR_T_VENT_GZ[i]), gz_paths[i], verify_gz)

# ---- fetch: field-definition docs (reference only, not read by the pipeline) --
# Upstream serves these as `.csv` with CRLF endings even though they are plain
# text; normalise to LF and store as `.txt` — the transformation that produced
# the files this project has always shipped.
for (doc in FIELD_DOCS) {
  dest <- file.path(PATHS$raw, sprintf("Q_descriptif_champs_%s.txt", doc))
  if (!file.exists(dest))
    fetch(file.path(MF_BASE_URL, sprintf("Q_descriptif_champs_%s.csv", doc)), dest,
          function(p) writeLines(sub("\r$", "", readLines(p, warn = FALSE)), p))
}

extract_gz <- file.path(PATHS$processed, STATION_EXTRACT)

# up-to-date check: extract newer than all inputs (raw files + this script + config)
inputs <- c(gz_paths, "R/00_prepare_data.R", "R/config.R")
if (file.exists(extract_gz) &&
    file.info(extract_gz)$mtime >= max(file.info(inputs)$mtime)) {
  message("up to date: ", extract_gz)
  quit(save = "no", status = 0)
}

message("Slicing ", length(gz_paths), " raw .gz files to stations: ",
        paste(names(STATIONS), collapse = ", "))

slice <- rbindlist(lapply(gz_paths, function(f) {
  message("  reading ", basename(f), " ...")
  d <- read_gz(f, select = KEEP_COLS, colClasses = list(character = "NUM_POSTE"))
  d[NUM_POSTE %in% names(STATIONS)]
}))

setorder(slice, NUM_POSTE, AAAAMMJJ)

# Write gzipped. fwrite only takes a filename (not a connection) and its built-in
# .gz needs data.table compiled against zlib (not guaranteed here), so write a
# temp CSV and compress it with the system gzip — symmetric with read_gz().
tmp_csv <- tempfile(fileext = ".csv")
fwrite(slice, tmp_csv, sep = ";")   # match the raw ';' format that read_gz expects
ret <- system2("gzip", c("-cf", shQuote(tmp_csv)),
               stdout = extract_gz, stderr = "")
unlink(tmp_csv)
if (ret != 0 || !file.exists(extract_gz) || file.size(extract_gz) == 0)
  stop("gzip compression of the station extract failed (exit ", ret, ").")

message(sprintf("Stage 00 complete: %d rows -> %s (%.0f KB)",
                nrow(slice), extract_gz, file.size(extract_gz) / 1024))
