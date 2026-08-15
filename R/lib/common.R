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
# ...and those days must be SPREAD ACROSS the window, not bunched in part of it:
# every calendar month the window covers must be at least this fraction present.
# A raw day-count floor alone is not enough. Albuquerque Airport's feed starts
# 1931-03-01, so 1931 cleared the 150-day floor for a Jan 1 - Aug 11 window while
# missing January and February entirely — the two coldest months. Its "Jan-Aug
# mean" was really a Mar-Aug mean, 3.9 degC too warm, which made 1931 the
# apparent record holder and shrank the current year's true margin from
# +1.6 degC to +0.3. A part-of-window mean must not enter a same-window ranking.
MIN_YTD_MONTH_FRAC <- 1/3

# The longest window EVERY site shares — the latest first-complete-year across
# all sites (Nouméa, 1951). Used for the cross-site comparison's like-for-like
# rate column, so a raw-rate ranking cannot be mistaken for a speed ranking when
# the records run 74 to 151 years. R/04_compare.R asserts no site starts later
# than this; if one ever does, bump this constant rather than silently comparing
# a site against a window it does not cover.
COMMON_YR0 <- 1951L

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

# ---- Köppen-Geiger climate classification ------------------------------------
# Computed from a station's own monthly normals rather than asserted, for the
# same reason every other claim here is computed: a hardcoded "Cfb" cannot be
# checked and goes stale silently. Follows the standard Peel/Finlayson/McMahon
# (2007) formulation of the criteria.
#
# Two things to be honest about when reading the result:
#  * It classifies THE REFERENCE STATION, not the city. A leeward airport can
#    land in a drier class than the city it serves — Honolulu Airport takes
#    about a third of the rain that windward Oʻahu does.
#  * Classes sit on hard thresholds, so a station near one can flip between
#    neighbouring classes with the baseline period. KOPPEN_YEARS below fixes the
#    baseline at the most recent 30 complete years, which describes the climate
#    a reader lives in now rather than the record average.
KOPPEN_YEARS <- 30L

koppen_code <- function(tmon, pmon, southern) {
  if (anyNA(tmon) || anyNA(pmon)) return(NA_character_)
  Tann <- mean(tmon); Pann <- sum(pmon)
  Thot <- max(tmon);  Tcold <- min(tmon)
  n10  <- sum(tmon >= 10)
  Pdry <- min(pmon)
  # "Summer" is the warmer half-year: Apr-Sep north of the equator, Oct-Mar south.
  summer <- if (southern) c(10:12, 1:3) else 4:9
  winter <- setdiff(1:12, summer)
  Psdry <- min(pmon[summer]); Pswet <- max(pmon[summer])
  Pwdry <- min(pmon[winter]); Pwwet <- max(pmon[winter])
  # Aridity threshold depends on WHEN the rain falls, not just how much.
  frac_summer <- sum(pmon[summer]) / Pann
  Pthr <- if (frac_summer >= 0.7) 2 * Tann + 28 else
          if (frac_summer <= 0.3) 2 * Tann else 2 * Tann + 14

  if (Pann < 10 * Pthr) {                                   # B — arid
    paste0("B", if (Pann < 5 * Pthr) "W" else "S",
                if (Tann >= 18) "h" else "k")
  } else if (Tcold >= 18) {                                 # A — tropical
    if (Pdry >= 60) "Af"
    else if (Pdry >= 100 - Pann / 25) "Am"
    else paste0("A", if (which.min(pmon) %in% summer) "s" else "w")
  } else if (Thot > 10) {                                   # C / D
    main <- if (Tcold > 0) "C" else "D"
    second <- if (Psdry < 40 && Psdry < Pwwet / 3) "s" else
              if (Pwdry < Pswet / 10) "w" else "f"
    third <- if (Thot >= 22) "a" else if (n10 >= 4) "b" else
             if (main == "D" && Tcold < -38) "d" else "c"
    paste0(main, second, third)
  } else "E"                                                # polar
}

# Plain-language gloss, so the table does not require the reader to know the codes.
KOPPEN_LABELS <- c(
  Af = "tropical rainforest", Am = "tropical monsoon",
  Aw = "tropical savanna, dry winter", As = "tropical savanna, dry summer",
  BWh = "hot desert", BWk = "cold desert",
  BSh = "hot semi-arid", BSk = "cold semi-arid",
  Csa = "Mediterranean, hot summer", Csb = "Mediterranean, warm summer",
  Cfa = "humid subtropical", Cfb = "temperate oceanic", Cfc = "subpolar oceanic",
  Cwa = "humid subtropical, dry winter", Cwb = "temperate, dry winter",
  Dfa = "humid continental, hot summer", Dfb = "humid continental, warm summer",
  Dfc = "subarctic", Dfd = "extremely cold subarctic",
  Dsa = "continental, dry hot summer", Dsb = "continental, dry warm summer",
  Dwa = "continental, dry winter", Dwb = "continental, dry warm summer",
  E = "polar")
koppen_label <- function(code) if (is.na(code)) NA_character_ else
  unname(ifelse(code %in% names(KOPPEN_LABELS), KOPPEN_LABELS[code], code))

# Köppen classes sit on hard thresholds, so a station sitting almost exactly on
# one gets a label that flips with the baseline period — Albuquerque's 30-year
# rainfall is within about 5 mm of the steppe/desert line, and Voronezh's warmest
# month is within a tenth of a degree of the hot/warm-summer split. Reference
# works that use a different normal period will disagree in exactly those cases.
# Report which sites are near a boundary rather than presenting them as settled.
koppen_borderline <- function(tmon, pmon, southern, tol_frac = 0.05, tol_deg = 0.5) {
  if (anyNA(tmon) || anyNA(pmon)) return(NA_character_)
  code <- koppen_code(tmon, pmon, southern)
  if (is.na(code)) return(NA_character_)
  main <- substr(code, 1, 1)
  Tann <- mean(tmon); Pann <- sum(pmon)
  summer <- if (southern) c(10:12, 1:3) else 4:9
  frac_summer <- sum(pmon[summer]) / Pann
  Pthr <- if (frac_summer >= 0.7) 2 * Tann + 28 else
          if (frac_summer <= 0.3) 2 * Tann else 2 * Tann + 14
  near <- function(x, target, tol) abs(x - target) <= tol
  r <- character(0)
  # Only test boundaries that this class actually sits on. The summer-heat and
  # winter-cold letters exist only for C and D, so checking Thot against 22 for an
  # arid station reported a "hot/warm summer" boundary that means nothing there —
  # Santa Fe (BSk) was flagged for a letter its code does not have.
  if (near(Pann, 10 * Pthr, tol_frac * 10 * Pthr)) r <- c(r, "arid/humid")
  if (main == "B" && near(Pann, 5 * Pthr, tol_frac * 5 * Pthr)) r <- c(r, "steppe/desert")
  if (main %in% c("C", "D")) {
    if (near(max(tmon), 22, tol_deg)) r <- c(r, "hot/warm summer")
    if (near(min(tmon),  0, tol_deg)) r <- c(r, "temperate/continental")
  }
  if (main %in% c("A", "C") && near(min(tmon), 18, tol_deg)) r <- c(r, "tropical/temperate")
  if (length(r)) paste(r, collapse = ", ") else NA_character_
}
