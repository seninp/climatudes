# =============================================================================
# Shared, source-agnostic helpers and constants.
# Sourced by every stage, for every site — nothing in here names a city,
# country or upstream data provider. Per-site facts (stations, paths, source,
# citation, narrative) live in R/sites/<site>.R; per-source fetch/parse logic
# lives in R/sources/<source>.R.
# =============================================================================

# ---- shared filenames --------------------------------------------------------
STATION_EXTRACT <- "stations_daily.csv.gz"   # per-site: <site>$paths$processed/<this>

# ---- analysis constants (same methodology across every site, for comparability) --
MIN_DAYS      <- 330L   # a year needs >= this many valid days to count as "complete"
SMOOTH_WINDOW <- 3L     # centred rolling-mean window (days) for the daily climatology
MIN_YTD_DAYS  <- 150L   # a year needs >= this many valid days in the YTD window

# ---- temperature-extremes day-count thresholds -------------------------------
FROST_TX  <- 0    # frost day:      daily minimum TN <  0 °C
HOT_TX    <- 30   # hot day:        daily maximum TX >= 30 °C
VHOT_TX   <- 35   # very hot day:   daily maximum TX >= 35 °C
TROPNIGHT <- 20   # tropical night: daily minimum TN >= 20 °C

# ---- shared palette -----------------------------------------------------------
# Colourblind-safe (validated with the dataviz palette checker). Same palette for
# every site so the reports read as one system.
COL <- list(
  tx     = "#C0392B",  # warm red   — daily maximum / current year
  mean   = "#566573",  # slate      — daily mean
  tn     = "#2471A3",  # blue       — daily minimum
  auz    = "#1E8449",  # green      — local station mean
  normal = "#34495E",  # dark slate — long-term daily normal
  spaghetti = "#7E93A1",# grey-blue — individual historical years
  wet    = "#2471A3",  # blue       — rain / wetter than normal (= tn)
  dry    = "#B9770E",  # ochre      — drier than normal (diverging pole vs wet)
  rain_blag = "#2471A3",# blue      — reference-station annual rainfall (= tn)
  rain_auz  = "#1E8449" # green     — local-station annual rainfall     (= auz)
)

# ---- axis-label formatter for temperatures -----------------------------------
# Uses a typographic minus (U+2212) so negative tick labels match the minus sign
# used in titles, subtitles and threshold captions. `signed = TRUE` also prefixes
# non-negatives with "+", for the departure-from-normal axis where the sign
# carries the meaning.
deg_label <- function(x, signed = FALSE) {
  pos <- if (signed) "+" else ""
  out <- paste0(ifelse(x < 0, "−", pos),
                format(abs(x), trim = TRUE, drop0trailing = TRUE), " °C")
  out[is.na(x)] <- NA   # ggplot censors out-of-range breaks to NA; keep them NA
  out
}

# ---- read a gzipped semicolon CSV directly (no temp file), via streaming pipe --
# Every source's normalized extract is written in this shape, so every stage
# downstream of stage 00 reads it the same way regardless of upstream provider.
read_gz <- function(path, ...) {
  suppressPackageStartupMessages(library(data.table))
  fread(cmd = paste("gzip -dc", shQuote(path)), sep = ";", showProgress = FALSE, ...)
}

# ---- download helper shared by every R/sources/*.R fetcher -------------------
# curl over plain HTTPS, no credentials — every source used here (Météo-France,
# MeteoSwiss, DWD) is open data under an attribution-only licence. Downloads to a
# temp file and only moves it into place once verified, so an interrupted or
# truncated transfer can never leave a corrupt file that looks cached.
fetch_url <- function(url, dest, verify, on_404_hint = NULL) {
  message("  downloading ", basename(dest), " ...")
  tmp <- paste0(dest, ".part")
  on.exit(unlink(tmp), add = TRUE)
  ok <- system2("curl", c("-fsSL", "--max-time", "600", "-o", shQuote(tmp), shQuote(url)))
  if (ok != 0 || !file.exists(tmp) || file.size(tmp) == 0)
    stop("download failed (curl exit ", ok, "): ", url,
         if (!is.null(on_404_hint)) paste0("\n", on_404_hint) else "")
  verify(tmp)                       # integrity / format check before committing
  if (!file.rename(tmp, dest)) stop("could not move ", tmp, " into place")
  message(sprintf("    ok (%.1f MB)", file.size(dest) / 1024^2))
}

# gzipped data: verify the archive is complete and readable.
verify_gz <- function(p) if (system2("gzip", c("-t", shQuote(p)),
                                     stdout = FALSE, stderr = FALSE) != 0)
  stop("downloaded file is not a valid gzip archive: ", p)

# plain-text data (CSV, no compression): just check it is non-empty and looks
# like text, not e.g. an HTML error page from a wrong URL.
verify_text <- function(p) {
  first <- readLines(p, n = 1, warn = FALSE)
  if (length(first) == 0 || grepl("^\\s*<", first))
    stop("downloaded file does not look like plain-text data (got HTML?): ", p)
}

# zip archives (DWD ships one zip per station/period): verify it opens cleanly.
verify_zip <- function(p) if (system2("unzip", c("-t", shQuote(p)),
                                      stdout = FALSE, stderr = FALSE) != 0)
  stop("downloaded file is not a valid zip archive: ", p)

# ---- write the normalized daily extract --------------------------------------
# Every R/sources/*.R fetcher ends by handing its normalized data.table (columns
# NUM_POSTE, AAAAMMJJ, TN, TX, TNTXM, RR — TNTXM always computed as (TN+TX)/2 for
# methodological consistency across sites) to this, which writes it gzipped in
# the same ';'-delimited shape read_gz() expects.
write_extract <- function(dat, dest) {
  suppressPackageStartupMessages(library(data.table))
  setorder(dat, NUM_POSTE, AAAAMMJJ)
  tmp_csv <- tempfile(fileext = ".csv")
  fwrite(dat, tmp_csv, sep = ";")
  ret <- system2("gzip", c("-cf", shQuote(tmp_csv)), stdout = dest, stderr = "")
  unlink(tmp_csv)
  if (ret != 0 || !file.exists(dest) || file.size(dest) == 0)
    stop("gzip compression of the station extract failed (exit ", ret, ").")
  message(sprintf("Wrote %d rows -> %s (%.0f KB)", nrow(dat), dest, file.size(dest) / 1024))
}
