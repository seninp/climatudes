# =============================================================================
# Site: Honolulu (Oʻahu, Hawaiʻi, USA), via NOAA GHCN-Daily.
#
# Honolulu International Airport (USW00022521, WMO 91182) reports daily
# TMAX/TMIN/PRCP from 1940 to today with no splice needed — though every year
# of the 1940s falls below the MIN_DAYS completeness bar, so the trend here
# actually starts at 1950. No other digitized GHCN-Daily station near Honolulu carries an
# independent temperature record, so the local tier is rainfall-only, the way
# Karlsruhe-Wolfartsweier is for Karlsruhe — `local_has_temp = FALSE`.
#
# The obvious rain-only pick, Honolulu Fire Station 703 (USC00511925), turned
# out to have only 6 complete (>= 330 valid days) years in 18 — too sparse and
# unevenly spaced for a stable LOESS fit (verified: it produces a wildly
# oscillating curve). Moanalua (USC00516395), a valley neighbourhood between
# the airport and downtown, reports 81 rain years since 1906 of which 80 are
# complete, and is used instead.
# =============================================================================

SITE <- list(
  key    = "honolulu",
  source = "noaa",

  paths = list(
    raw       = "data/raw/honolulu",
    processed = "data/processed/honolulu",
    outputs   = "outputs/honolulu",
    figures   = "outputs/honolulu/figures"
  ),

  stations = c(
    "USW00022521" = "Honolulu Airport",
    "USC00516395" = "Honolulu-Moanalua"
  ),
  reference_station = "Honolulu Airport",
  local_station      = "Honolulu-Moanalua",
  local_has_temp     = FALSE,   # rain gauge only — see header note
  local_rationale = paste(
    "No other digitized GHCN-Daily station near Honolulu carries a temperature record",
    "independent of the airport. Moanalua (station USC00516395), a valley neighbourhood",
    "between the airport and downtown, has recorded rainfall since 1906 — 80 complete years",
    "of the 81 it reports — and stands in for local rainfall. Honolulu International Airport",
    "(station USW00022521) provides the temperature trend: its readings begin in 1940, but the",
    "1940s years all fall short of the completeness rule used here, so the trend starts at its",
    "first complete year, 1950, and runs unbroken from there."
  ),

  city = "Honolulu", region = "Oʻahu, Hawaiʻi", country = "USA",

  citation = list(
    source_name   = "NOAA (National Centers for Environmental Information)",
    dataset_label = "GHCN-Daily — Global Historical Climatology Network, daily summaries",
    scope_label   = "",
    url           = "https://www.ncei.noaa.gov/access/services/data/v1",
    licence       = "U.S. Government work — no copyright restriction (NOAA Open Data)"
  ),

  # ---- source-specific fetch parameters (noaa.R) -----------------------------
  noaa = list(
    base_url = "https://www.ncei.noaa.gov/access/services/data/v1",
    stations = list(
      "USW00022521" = list(start = "1940-01-01", end = "2030-12-31"),
      "USC00516395" = list(start = "1905-01-01", end = "2030-12-31")
    )
  )
)
