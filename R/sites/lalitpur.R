# =============================================================================
# Site: Lalitpur (Patan, Kathmandu Valley, Nepal) — Tribhuvan Intl Airport,
# two open feeds of the SAME station homogenized into one series
# (see R/sources/ghcn_iem.R).
#
# Lalitpur (Patan) sits in the Kathmandu Valley, contiguous with Kathmandu; the
# only long instrumental record for the valley is the airport ~5 km north.
# Getting a CURRENT, real-station daily series for it takes two open feeds of
# the one physical station, because its internationally-shared climatological
# feed thinned while its live aviation feed did not:
#
#   * NOAA GHCN-Daily (station NP000444540 / WMO 44454): clean daily temperature
#     1971-2000, intermittent 2001-2011, substantial again from ~2015 (200-260
#     days/yr). The only source of daily rainfall here.
#   * Iowa Environmental Mesonet's ASOS archive (VNKT, the same airport): daily
#     max/min from hourly METAR, near-complete from 2012. Temperature only —
#     METAR measures no usable precipitation.
#
# The two feeds are the same instrument through different processing and sit on
# slightly different scales (METAR nights read warm, days read cool). They
# overlap on thousands of days (2015-2025), so the module MEASURES that offset
# per calendar month from same-day pairs and shifts IEM onto GHCN's scale before
# using it — a data-driven homogenization, not a splice-by-date and not a model.
# The combined series prefers the real GHCN value wherever one exists; the
# sparse 2001-2011 years fall below the 330-day bar and show as an honest
# interior gap. Rainfall stays GHCN-only, so it is thin and recent — see the
# rainfall note in the report.
#
# Why not the alternatives, briefly (full trail in the session notes):
#   * ERA5 reanalysis (Open-Meteo) is complete and current but flattens this
#     valley's warming ~10x (+0.05 vs the station's literature-consistent
#     +0.5 C/decade over 1971-2000) — a ~25 km grid cell misses the Himalayan
#     valley and its urban warming. Rejected as materially misleading.
#   * Meteostat looks complete post-2000 only by gap-filling the same station
#     with model data.
#   * Nepal's DHM sells daily data under a closed licence (manual request +
#     payment), incompatible with this project's open, scriptable basis.
# =============================================================================

SITE <- list(
  key    = "lalitpur",
  source = "ghcn_iem",

  paths = list(
    raw       = "data/raw/lalitpur",
    processed = "data/processed/lalitpur",
    outputs   = "outputs/lalitpur",
    figures   = "outputs/lalitpur/figures"
  ),

  # One physical station (Tribhuvan Intl Airport). Its id is the WMO index 44454,
  # shared by both providers (GHCN NP000444540, IEM VNKT) — see the note below on
  # why the series takes two sources.
  stations = c(
    "44454" = "Kathmandu Airport"
  ),
  reference_station = "Kathmandu Airport",
  # local_station intentionally unset; local_has_temp = FALSE. A single airport
  # station has no second "local" gauge — same single-station path through the
  # pipeline as Moscow/Voronezh (HAS_LOCAL = FALSE in R/01_plot.R, narrative.R).
  local_has_temp = FALSE,
  local_rationale = paste(
    "Lalitpur (Patan) sits in the Kathmandu Valley; the valley's only long record",
    "is Tribhuvan International Airport, about 5 km north. To make that a current,",
    "real-station series takes two open feeds of the same airport, because its",
    "internationally-shared climate feed thinned while its live aviation feed did",
    "not: NOAA GHCN-Daily supplies clean daily temperature for 1971–2000 (and",
    "substantial data again from about 2015), and the Iowa Environmental Mesonet's",
    "archive of the airport's hourly METAR reports fills the rest, near-complete",
    "from 2012. The two feeds are the same instrument through different processing",
    "and sit on slightly different scales, so — because they overlap on thousands",
    "of recent days — the offset is measured month by month from same-day pairs",
    "and the METAR feed is shifted onto the long record's scale before use; the",
    "sparse 2001–2011 years still show as a gap rather than invented data.",
    "Rainfall comes from GHCN alone — METAR carries no usable precipitation — so",
    "the rain record here is thin and recent. This is the only site drawing on two",
    "feeds; every value is still a real observation from this one airport, adjusted",
    "only by a measured scale offset, not a model or a reanalysis."
  ),

  # Reference-station geography. Source: NOAA ghcnd-stations.txt, NP000444540
  # (27.70°N, 85.367°E, 1337 m) — the airport. Latitude drives the hemisphere
  # test in the Köppen classification, so it must be the real signed value.
  latitude = 27.70, longitude = 85.367, elevation_m = 1337,

  city = "Lalitpur", region = "Bagmati Province", country = "Nepal",

  citation = list(
    # Kept short because the shared templates put it in the possessive
    # ("<source_name>'s daily records for ..."), where the full two-provider
    # string with its "/ ASOS METAR" tail reads badly. The detail lives in
    # dataset_label, which every surface prints alongside this.
    source_name   = "NOAA GHCN-Daily and the Iowa Environmental Mesonet",
    dataset_label = "Kathmandu Airport (WMO 44454): daily temperature from two open feeds of the one station, METAR homogenized to the GHCN scale by a measured per-month offset; rainfall from GHCN",
    scope_label   = "single airport station",
    url           = "https://www.ncei.noaa.gov/access/services/data/v1 ; https://mesonet.agron.iastate.edu/request/daily.phtml",
    licence       = "NOAA: U.S. Government work, no copyright restriction. IEM: open data (Iowa State University), attribution requested"
  ),

  # ---- source-specific fetch parameters (ghcn_iem.R) -------------------------
  # No date cutoff: the module prefers the real GHCN value wherever one exists
  # and fills the rest with METAR shifted onto GHCN's scale by a per-month offset
  # measured from the two feeds' same-day overlap (2015-2025). See ghcn_iem.R.
  ghcn_iem = list(
    ghcn_base_url = "https://www.ncei.noaa.gov/access/services/data/v1",
    ghcn_id       = "NP000444540",
    ghcn_start    = "1971-01-01",
    ghcn_end      = "2030-12-31",   # future sentinel; service returns only what exists
    iem_network   = "NP__ASOS",
    iem_station   = "VNKT",
    iem_start     = "2001-01-01"
  )
)
