# =============================================================================
# Site: Hyderabad (Telangana, India) — Begumpet observatory, two open feeds of
# the SAME station homogenized into one series (see R/sources/ghcn_iem.R).
#
# Begumpet is IMD's Hyderabad observatory, on the grounds of the old city
# airport (WMO 43128) — today well inside the city, and the only long daily
# record for it that is openly published anywhere. India shares little daily
# data internationally, so the open record of this one station is split across
# two feeds, complementary in time:
#
#   * NOAA GHCN-Daily (station IN001080500, GSN): daily rainfall complete
#     1901-1970, then collapsing — patchy to 1998, ~100-130 days/yr since 1999.
#     Daily temperature only from 1973 (plus a complete 1957-58 and slivers of
#     1961-62), never filling a year: 120-350 days/yr. The only source of
#     daily rainfall here.
#   * Iowa Environmental Mesonet's archive of the airport's METAR (VOHY, the
#     same field): daily max/min near-complete 1973->present (>= 350 days/yr
#     except 1975 and 2011), current to about yesterday. Temperature only —
#     METAR measures no usable precipitation.
#
# Same recipe as Lalitpur, the module's first case — see ghcn_iem.R for the
# method. Here the same-day overlap is far richer (GHCN and IEM both cover
# 1973-2025), so the per-month offset rests on decades of pairs. The combined
# series prefers the real GHCN value wherever one exists; it opens with a lone
# complete 1958 (GHCN carries a full 1957-58), shows an honest 14-year gap to
# 1973, and is essentially complete from then on. Rainfall stays GHCN-only —
# deep but old: 70 complete years 1901-1970, too few valid days in most years
# since. The inverse of Lalitpur's thin-and-recent rain record.
#
# Why not the alternatives, briefly:
#   * IMD sells its daily station archive per request under a closed licence —
#     incompatible with this project's open, scriptable basis.
#   * VOHS (Rajiv Gandhi Intl, the 2008 replacement airport) starts 2008 and
#     sits ~24 km south of the city at 617 m — too short, and a site move.
#   * The other GHCN gauges around the city (Sultan Bazar, Saifabad, Bolaram,
#     ...) are rain-only, start in the same 1901 batch and stop 1955-1957 —
#     they add no temperature and no years Begumpet's own gauge lacks.
#   * GHCN's only station NAMED "Hyderabad" is Hyderabad, Pakistan
#     (PKM00041764); the Indian record is filed under "Begumpet Obsy".
# =============================================================================

SITE <- list(
  key    = "hyderabad",
  source = "ghcn_iem",

  paths = list(
    raw       = "data/raw/hyderabad",
    processed = "data/processed/hyderabad",
    outputs   = "outputs/hyderabad",
    figures   = "outputs/hyderabad/figures"
  ),

  # One physical station (Begumpet observatory / old airport). Its id is the
  # WMO index 43128, shared by both providers (GHCN IN001080500, IEM VOHY) —
  # see the header on why the series takes two sources.
  stations = c(
    "43128" = "Hyderabad-Begumpet"
  ),
  reference_station = "Hyderabad-Begumpet",
  # local_station intentionally unset; local_has_temp = FALSE. A single
  # observatory station has no second "local" gauge — same single-station path
  # through the pipeline as Moscow/Voronezh and Lalitpur (HAS_LOCAL = FALSE).
  local_has_temp = FALSE,
  local_rationale = paste(
    "Hyderabad's one long, openly published record is the Begumpet observatory,",
    "on the grounds of the old city airport (WMO 43128) — today well inside the",
    "city. India's weather service does not publish its daily archives openly,",
    "so this station's open record is split across two feeds: NOAA GHCN-Daily",
    "carries complete daily rainfall for 1901–1970 and daily temperature from",
    "1973 that never fills a year, and the Iowa Environmental Mesonet's archive",
    "of the airport's hourly METAR reports supplies near-complete daily",
    "temperature from 1973 to about yesterday. The two feeds are the same",
    "instrument through different processing and sit on slightly different",
    "scales, so — because they overlap on tens of thousands of days — the",
    "offset is measured month by month from same-day pairs and the METAR feed",
    "is shifted onto the long record's scale before use. GHCN also holds a",
    "complete 1957–58, so the temperature series opens with a lone complete",
    "1958, then an honest 14-year gap to 1973. Rainfall comes from GHCN alone —",
    "METAR carries no usable precipitation — so the rain record here is deep",
    "but mostly old: seventy complete years, 1901–1970, and too few valid days",
    "in most years since. Every value is still a real observation from this one",
    "station, adjusted only by a measured scale offset, not a model or a",
    "reanalysis."
  ),

  # Reference-station geography. Source: NOAA ghcnd-stations.txt, IN001080500
  # (17.45°N, 78.47°E, 527 m) — the observatory. Latitude drives the hemisphere
  # test in the Köppen classification, so it must be the real signed value.
  latitude = 17.45, longitude = 78.47, elevation_m = 527,

  city = "Hyderabad", region = "Telangana", country = "India",

  citation = list(
    # Kept short because the shared templates put it in the possessive
    # ("<source_name>'s daily records for ..."), where the full two-provider
    # string with its "/ ASOS METAR" tail reads badly. The detail lives in
    # dataset_label, which every surface prints alongside this.
    source_name   = "NOAA GHCN-Daily and the Iowa Environmental Mesonet",
    dataset_label = "Hyderabad-Begumpet (WMO 43128): daily temperature from two open feeds of the one station, METAR homogenized to the GHCN scale by a measured per-month offset; rainfall from GHCN (complete 1901–1970, thin after)",
    scope_label   = "single observatory station",
    url           = "https://www.ncei.noaa.gov/access/services/data/v1 ; https://mesonet.agron.iastate.edu/request/daily.phtml",
    licence       = "NOAA: U.S. Government work, no copyright restriction. IEM: open data (Iowa State University), attribution requested"
  ),

  # ---- source-specific fetch parameters (ghcn_iem.R) -------------------------
  # ghcn_start reaches back to the 1901 start of the rainfall record; the
  # service returns only what exists, so the 1957-58 temperature fragment rides
  # along free. iem_start: IEM's VOHY archive nominally opens 1944, but its
  # first daily max/min rows are 1957-07 — requesting from 1957 loses nothing.
  ghcn_iem = list(
    ghcn_base_url = "https://www.ncei.noaa.gov/access/services/data/v1",
    ghcn_id       = "IN001080500",
    ghcn_start    = "1901-01-01",
    ghcn_end      = "2030-12-31",   # future sentinel; service returns only what exists
    iem_network   = "IN__ASOS",
    iem_station   = "VOHY",
    iem_start     = "1957-01-01"
  )
)
