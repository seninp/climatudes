# =============================================================================
# Site: Boston (Massachusetts, USA), via NOAA GHCN-Daily.
#
# The reference is Blue Hill Observatory (USC00190736), on the summit of
# Great Blue Hill in Milton, ten miles south of downtown at 190 m — the
# oldest continuously operating weather observatory in the United States,
# measuring at the same hilltop since 1885. Daily temperature runs from
# 1885-02-01 with no interior gap in the raw record (verified per-year
# against the daily file, not just the inventory span); rainfall from 1886
# with only 1893 and 1899 a day or two under the completeness bar. No splice,
# no site move. GHCN's internal-consistency QC (QFLAG "I") nulls ~150
# temperature days across 2009-2010, dropping just those two years below the
# 330-day bar — so the pipeline counts 139 complete years through 2025.
#
# Logan International Airport (USW00014739, WMO 72509), across the harbor
# two miles east of downtown, is Boston's official first-order station and
# the local comparison: 1936-01-01 -> present, also gap-free (90 complete
# years through 2025).
#
# Why not the alternatives, briefly:
#   * USW00094701 "Boston City WSO" (downtown, 1893-1935) could be spliced
#     onto Logan for a "Boston" series back to 1893 — but that record is
#     still eight years shorter than Blue Hill's, and the splice would hide
#     a real site move from the city centre to the airport. Blue Hill needs
#     neither.
#   * USC00190768 (downtown COOP) is rain-only, 1891-1912.
#   * USW00014753 "Blue Hill LCD" (GSN, WMO 74492) is a second, shorter feed
#     (1959->) of the same observatory — adds nothing over USC00190736.
# =============================================================================

SITE <- list(
  key    = "boston",
  source = "noaa",

  paths = list(
    raw       = "data/raw/boston",
    processed = "data/processed/boston",
    outputs   = "outputs/boston",
    figures   = "outputs/boston/figures"
  ),

  stations = c(
    "USC00190736" = "Blue Hill Observatory",
    "USW00014739" = "Logan Airport"
  ),
  reference_station = "Blue Hill Observatory",
  local_station      = "Logan Airport",
  local_has_temp     = TRUE,
  local_relation_clause = "is Boston's own first-order station, on the harbor two miles east of downtown",
  local_rationale = paste(
    "Unusually for this project, the reference station is not the one inside the city.",
    "Blue Hill Observatory (station USC00190736), on the summit of Great Blue Hill in",
    "Milton, ten miles south of downtown, is the oldest continuously operating weather",
    "observatory in the United States: the same hilltop has been measured since 1885,",
    "with no site move and no interior gap in the raw daily record; GHCN's own quality",
    "flags thin 2009 and 2010 below the completeness bar, leaving 139 complete years.",
    "Logan International Airport (USW00014739), across the harbor two miles east of",
    "downtown, is Boston's official station and provides the local comparison; its",
    "record starts in 1936 and is likewise gap-free. The observatory sits at 190 m,",
    "so its absolute temperatures run cooler than sea-level Boston — the trends, not",
    "the levels, are what the two series share."
  ),

  # Reference-station geography. Source: NOAA ghcnd-stations.txt, station USC00190736.
  # Latitude drives the hemisphere test in the Köppen classification, so it
  # must be the real signed value, not a magnitude.
  latitude = 42.2122, longitude = -71.1136, elevation_m = 190.5,

  city = "Boston", region = "Massachusetts", country = "USA",

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
      "USC00190736" = list(start = "1885-02-01", end = "2030-12-31"),
      "USW00014739" = list(start = "1936-01-01", end = "2030-12-31")
    )
  )
)
