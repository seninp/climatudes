# =============================================================================
# NOAA GHCN-Daily via the Access Data Service v1 — the fetch, QC and read steps
# shared by R/sources/noaa.R and R/sources/ghcn_iem.R, which each source this.
# Provider-specific, so it lives here rather than in R/lib/common.R.
# =============================================================================

# Fetch one station's requested range in a single request into `dest`, unless
# it is already on disk. Returns `dest`.
ghcn_fetch <- function(base_url, dest, id, start, end) {
  if (!file.exists(dest)) {
    url <- sprintf(
      "%s?dataset=daily-summaries&stations=%s&startDate=%s&endDate=%s&format=csv&units=metric&dataTypes=TMAX,TMIN,PRCP&includeAttributes=true",
      base_url, id, start, end)
    fetch_url(url, dest, verify_text, on_404_hint = sprintf(
      "station %s may not exist in GHCN-Daily, or has no data between %s and %s.",
      id, start, end))
  }
  dest
}

# Each element's *_ATTRIBUTES column is "MFLAG,QFLAG,SFLAG[,...]" — the daily-
# summaries endpoint returns the raw value even when GHCN's own QC has flagged
# it (e.g. QFLAG "G", failed gap check — seen in practice: a -50 degC August
# TMIN at Santa Fe, 1901-08-25, physically impossible for that station/season).
# A non-empty QFLAG means "do not trust this value" — null it out here rather
# than downstream, so every stage after stage 00 sees only QC-passed values.
ghcn_qflag_ok <- function(attrs) {
  # A station/date with no reading at all for this element (e.g. a rain-only
  # station has no TMAX/TMIN column data) makes fread() infer the whole
  # *_ATTRIBUTES column as logical NA rather than character — coerce first so
  # strsplit() never sees a non-character vector.
  attrs <- as.character(attrs)
  qflag <- vapply(strsplit(attrs, ",", fixed = TRUE), function(x)
    if (length(x) >= 2) x[[2]] else "", character(1))
  is.na(attrs) | qflag == ""
}

# Read a fetched CSV to AAAAMMJJ, TN, TX, RR with QC-failed values nulled.
ghcn_read <- function(path) {
  suppressPackageStartupMessages(library(data.table))
  d <- fread(path)
  tn <- as.numeric(d$TMIN); tx <- as.numeric(d$TMAX); rr <- as.numeric(d$PRCP)
  tn[!ghcn_qflag_ok(d$TMIN_ATTRIBUTES)] <- NA_real_
  tx[!ghcn_qflag_ok(d$TMAX_ATTRIBUTES)] <- NA_real_
  rr[!ghcn_qflag_ok(d$PRCP_ATTRIBUTES)] <- NA_real_
  data.table(AAAAMMJJ = as.integer(gsub("-", "", d$DATE, fixed = TRUE)),
             TN = tn, TX = tx, RR = rr)
}
