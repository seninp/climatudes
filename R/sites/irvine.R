# =============================================================================
# Site: Irvine (California, USA), via NOAA GHCN-Daily.
#
# The reference series, labelled "Irvine", splices the Irvine Ranch COOP
# station's original site (USC00049087, "Tustin Irvine Ranch", 1915-2003) onto
# its direct successor a few km away (USC00044303, "Irvine Ranch", 2003->) for
# one continuous record back to 1915 — the same predecessor/successor idea as
# Santa Fe's in-town splice, see R/sources/noaa.R and R/sites/santafe.R. The
# two stations' own records do not quite touch (049087 ends 2003-06-30,
# 044303 begins 2003-08-01) — a one-month gap that costs 2003 its "complete
# year" status but otherwise splices cleanly.
#
# John Wayne Airport (USW00093184, Orange County's regional airport, a few km
# southwest, on Irvine's border) is the local comparison — continuously sited
# since 1999, no gaps, but a much shorter record than the spliced reference.
# =============================================================================

SITE <- list(
  key    = "irvine",
  source = "noaa",

  paths = list(
    raw       = "data/raw/irvine",
    processed = "data/processed/irvine",
    outputs   = "outputs/irvine",
    figures   = "outputs/irvine/figures"
  ),

  stations = c(
    "USC00044303" = "Irvine",
    "USW00093184" = "John Wayne Airport"
  ),
  reference_station = "Irvine",
  local_station      = "John Wayne Airport",
  local_has_temp     = TRUE,
  local_relation_clause = "is Orange County's regional airport, a few miles southwest on Irvine's border",
  local_rationale = paste(
    "John Wayne Airport (station USW00093184), a few miles southwest on Irvine's border, is the",
    "nearest continuously-sited station and provides the local comparison — but only since 1999.",
    "The reference series, labelled “Irvine”, splices the Irvine Ranch COOP station's original",
    "site (049087, “Tustin Irvine Ranch”, 1915–2003) with its direct successor a few miles away",
    "(044303, 2003–2026) for one continuous record back to 1915. The handoff is not seamless —",
    "049087 ends June 2003, 044303 begins August 2003 — which costs 2003 its “complete year”",
    "status."
  ),

  # Reference-station geography. Source: NOAA ghcnd-stations.txt, station USC00044303.
  # Latitude drives the hemisphere test in the Köppen classification, so it
  # must be the real signed value, not a magnitude.
  latitude = 33.72, longitude = -117.7231, elevation_m = 165,

  city = "Irvine", region = "California", country = "USA",

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
      "USC00044303" = list(start = "2003-08-01", end = "2030-12-31",
                            predecessor = list(id = "USC00049087", start = "1915-01-01", end = "2003-06-30")),
      "USW00093184" = list(start = "1999-02-12", end = "2030-12-31")
    )
  )
)
