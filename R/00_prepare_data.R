#!/usr/bin/env Rscript
# =============================================================================
# Stage 00 — prepare data
# Reads the raw Météo-France .csv.gz files DIRECTLY (streamed, never written
# out decompressed), slices them down to just the stations we analyse, and
# caches that small extract — also gzipped — at data/processed/<STATION_EXTRACT>.
#
# Why: the raw zips are ~14 MB; fully decompressed they are ~140 MB. The two
# stations we need are a tiny fraction, so we keep everything compressed and
# only ever materialise the small slice (~0.35 MB).
# Idempotent: skips work if the extract is newer than every raw file + this code.
# =============================================================================

suppressPackageStartupMessages(library(data.table))
source("R/config.R")

dir.create(PATHS$processed, recursive = TRUE, showWarnings = FALSE)

gz_paths <- file.path(PATHS$raw, RR_T_VENT_GZ)
missing  <- gz_paths[!file.exists(gz_paths)]
if (length(missing))
  stop("Missing raw files in ", PATHS$raw, ":\n  ",
       paste(basename(missing), collapse = "\n  "))

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
