# =============================================================================
# Site: Santa Fe (New Mexico, USA), via NOAA GHCN-Daily.
#
# The reference series, labelled "Santa Fe", splices the city's original
# in-town COOP station (USC00298072, 1874-1972) onto its direct successor a
# few km south (USC00298085, 1972->) for one gap-free record back to 1874 —
# the same predecessor/successor idea as Karlsruhe's Rheinstetten splice, see
# R/sources/noaa.R and R/sites/karlsruhe.R.
#
# Santa Fe County Municipal Airport (USW00023049), the local comparison, has
# carried temperature since 1941 — but NOAA's own GHCN-Daily archive has no
# digitized daily TMAX/TMIN for it between 1959 and 1996 (verified directly
# against the station's raw .dly file: the gap is upstream, not a fetch bug
# in this pipeline). Its trend therefore uses only the complete years on
# either side of that hole.
# =============================================================================

SITE <- list(
  key    = "santafe",
  source = "noaa",

  paths = list(
    raw       = "data/raw/santafe",
    processed = "data/processed/santafe",
    outputs   = "outputs/santafe",
    figures   = "outputs/santafe/figures"
  ),

  stations = c(
    "USC00298085" = "Santa Fe",
    "USW00023049" = "Santa Fe Airport"
  ),
  reference_station = "Santa Fe",
  local_station      = "Santa Fe Airport",
  local_has_temp     = TRUE,
  local_relation_clause = "is Santa Fe County Municipal Airport, a few miles southwest of downtown",
  local_rationale = paste(
    "Santa Fe Airport (station USW00023049), a few miles southwest of downtown, is the",
    "nearest continuously-sited station and provides the local comparison. NOAA's own",
    "GHCN-Daily archive has no digitized daily temperature for it between 1959 and 1996",
    "— a real gap in the upstream record, not a fetch issue here — so its trend uses only",
    "the complete years on either side. The reference series, labelled “Santa Fe”, splices",
    "the city's original in-town COOP station (298072, 1874–1972) with its direct",
    "successor a few miles south (298085, 1972–2026) for one gap-free record back to 1874."
  ),

  # Reference-station geography. Source: NOAA ghcnd-stations.txt, station USC00298085.
  # Latitude drives the hemisphere test in the Köppen classification, so it
  # must be the real signed value, not a magnitude.
  latitude = 35.6194, longitude = -105.9753, elevation_m = 2059,

  city = "Santa Fe", region = "New Mexico", country = "USA",

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
      "USC00298085" = list(start = "1972-04-01", end = "2030-12-31",
                            predecessor = list(id = "USC00298072", start = "1874-01-01", end = "1972-03-31")),
      "USW00023049" = list(start = "1941-05-27", end = "2030-12-31")
    )
  )
)
