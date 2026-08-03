# =============================================================================
# Shared configuration for the Castanet-Tolosan temperature analysis.
# Sourced by every stage (00_prepare_data, 01_plot, 02_report) so that paths,
# station codes and analysis constants live in exactly one place.
# =============================================================================

# ---- project paths (resolved relative to the project root) ------------------
# Stages are launched from the project root (see Makefile / README), so these
# are simple relative paths.
PATHS <- list(
  raw        = "data/raw",
  processed  = "data/processed",
  outputs    = "outputs",
  figures    = "outputs/figures"
)

# ---- upstream source --------------------------------------------------------
# Météo-France publishes the daily climatological base as gzipped semicolon CSVs,
# one set per department, split into three eras. Mirror used here (plain HTTPS,
# no credentials — Licence Ouverte / Etalab):
MF_BASE_URL <- "https://meteofrance.s3.sbg.io.cloud.ovh.net/data/synchro_ftp/BASE/QUOT"
# Equivalent mirror if the above is unreachable:
#   https://object.files.data.gouv.fr/meteofrance/data/synchro_ftp/BASE/QUOT
MF_DEPT <- "31"   # Haute-Garonne

# The three eras. IMPORTANT: these names encode years and ROTATE each January —
# when 2027 opens, `latest-2025-2026` stops resolving (404) and its 2025-2026 rows
# migrate into `previous-1950-2026`. Nothing is lost upstream, but these constants
# must be bumped for the new cycle. Verified 2026-07-25: the prior cycle's names
# (`latest-2024-2025`, `previous-1950-2023`) now 404.
MF_ERAS <- c("avant-1949", "previous-1950-2024", "latest-2025-2026")

# Raw temperature files we analyse — kept GZIPPED in data/raw (read directly,
# never decompressed to disk: ~10 MB zipped vs ~140 MB unzipped).
# `RR-T-Vent` = rainfall / temperature / wind. The sibling `autres-parametres`
# files (humidity, pressure, sunshine) are NOT used by this pipeline.
RR_T_VENT_GZ <- sprintf("Q_%s_%s_RR-T-Vent.csv.gz", MF_DEPT, MF_ERAS)

# Field definitions. Served upstream as `.csv` despite being plain text, with
# CRLF line endings; stage 00 normalises them to LF and stores them as `.txt`.
FIELD_DOCS <- c("RR-T-Vent")   # add "autres-parametres" if ever needed

# Stage 00 slices the raw files down to just our stations and caches the result
# here, also gzipped (~0.35 MB). Stage 01 reads this small extract.
STATION_EXTRACT <- "stations_daily.csv.gz"

# Columns we keep from the raw CSVs. RR = daily precipitation (mm) — used for the
# rainfall figures; the rest drive the temperature analysis.
KEEP_COLS <- c("NUM_POSTE", "NOM_USUEL", "AAAAMMJJ", "TN", "TX", "TM", "TNTXM", "RR")

# Read a gzipped semicolon CSV directly (no temp file) via a streaming pipe.
read_gz <- function(path, ...) {
  suppressPackageStartupMessages(library(data.table))
  fread(cmd = paste("gzip -dc", shQuote(path)), sep = ";", showProgress = FALSE, ...)
}

# Axis-label formatter for temperatures. Uses a typographic minus (U+2212) so
# negative tick labels match the minus sign used in the titles, subtitles and
# threshold captions. `signed = TRUE` also prefixes non-negatives with "+", for
# the departure-from-normal axis where the sign carries the meaning.
deg_label <- function(x, signed = FALSE) {
  pos <- if (signed) "+" else ""
  out <- paste0(ifelse(x < 0, "−", pos),
                format(abs(x), trim = TRUE, drop0trailing = TRUE), " °C")
  out[is.na(x)] <- NA   # ggplot censors out-of-range breaks to NA; keep them NA
  out
}

# ---- stations ---------------------------------------------------------------
STATIONS <- c(
  "31035001" = "Auzeville-Tolosane-INRAE",   # on the edge of Castanet-Tolosan
  "31069001" = "Toulouse-Blagnac"            # long regional reference (1947->)
)
CLIMATOLOGY_STATION <- "Toulouse-Blagnac"    # longest record -> best daily curves

# ---- analysis constants -----------------------------------------------------
MIN_DAYS <- 330L    # a year needs >= this many valid days to count as "complete"
SMOOTH_WINDOW <- 3L # centred rolling-mean window (days) for the daily climatology
# For the year-to-date comparison (current partial year vs the same Jan 1 -> cutoff
# window of every prior year), a year needs >= this many valid days IN that window
# to be comparable — keeps sparse early records from distorting the ranking.
MIN_YTD_DAYS <- 150L

# ---- temperature-extremes day-count thresholds (Toulouse-Blagnac) -----------
# "Threshold days" per year that make warming tangible. Each is the count of days
# in a year crossing a fixed line; their decade-over-decade change is the story
# ("frost days halved, hot days doubled").
FROST_TX  <- 0    # frost day:      daily minimum TN <  0 °C
HOT_TX    <- 30   # hot day:        daily maximum TX >= 30 °C
VHOT_TX   <- 35   # very hot day:   daily maximum TX >= 35 °C
TROPNIGHT <- 20   # tropical night: daily minimum TN >= 20 °C

# ---- shared palette ---------------------------------------------------------
# Colourblind-safe (validated with the dataviz palette checker). The rain colours
# reuse the temperature blue/green for station identity so the two analyses read
# as one system; ochre is the "dry" pole, opposite the wet blue.
COL <- list(
  tx     = "#C0392B",  # warm red   — daily maximum / current year
  mean   = "#566573",  # slate      — daily mean
  tn     = "#2471A3",  # blue       — daily minimum
  auz    = "#1E8449",  # green      — Auzeville (Castanet) mean
  normal = "#34495E",  # dark slate — long-term daily normal
  spaghetti = "#7E93A1",# grey-blue — individual historical years
  wet    = "#2471A3",  # blue       — rain / wetter than normal (= tn)
  dry    = "#B9770E",  # ochre      — drier than normal (diverging pole vs wet)
  rain_blag = "#2471A3",# blue      — Toulouse-Blagnac annual rainfall (= tn)
  rain_auz  = "#1E8449" # green     — Auzeville annual rainfall       (= auz)
)
