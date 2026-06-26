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

# Raw temperature files we analyse — kept GZIPPED in data/raw (read directly,
# never decompressed to disk: ~14 MB zipped vs ~140 MB unzipped).
RR_T_VENT_GZ <- c(
  "Q_31_avant-1949_RR-T-Vent.csv.gz",
  "Q_31_previous-1950-2024_RR-T-Vent.csv.gz",
  "Q_31_latest-2025-2026_RR-T-Vent.csv.gz"
)

# Stage 00 slices the raw files down to just our stations and caches the result
# here, also gzipped (~0.35 MB). Stage 01 reads this small extract.
STATION_EXTRACT <- "stations_daily.csv.gz"

# Columns we keep from the raw CSVs.
KEEP_COLS <- c("NUM_POSTE", "NOM_USUEL", "AAAAMMJJ", "TN", "TX", "TM", "TNTXM")

# Read a gzipped semicolon CSV directly (no temp file) via a streaming pipe.
read_gz <- function(path, ...) {
  suppressPackageStartupMessages(library(data.table))
  fread(cmd = paste("gzip -dc", shQuote(path)), sep = ";", showProgress = FALSE, ...)
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

# ---- shared palette ---------------------------------------------------------
COL <- list(
  tx     = "#C0392B",  # warm red   — daily maximum / current year
  mean   = "#566573",  # slate      — daily mean
  tn     = "#2471A3",  # blue       — daily minimum
  auz    = "#1E8449",  # green      — Auzeville (Castanet) mean
  normal = "#34495E",  # dark slate — long-term daily normal
  spaghetti = "#7E93A1" # grey-blue — individual historical years
)
