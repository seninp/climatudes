# =============================================================================
# Site: Albuquerque (New Mexico, USA), via NOAA GHCN-Daily.
#
# Unlike Santa Fe/Irvine, no splice is needed here: Albuquerque International
# Airport (USW00023050) has one clean, continuous daily TMAX/TMIN/PRCP record
# from 1931 to today. It also carries NOAA's GSN flag (GCOS Surface Network —
# a station judged globally significant for long-term climate monitoring),
# the same two-full-stations-no-splice shape as Castanet-Tolosan/Toulouse-
# Blagnac, not the predecessor/successor shape of Santa Fe or Irvine.
#
# Albuquerque Foothills NE (USC00290225), in the foothills district in the
# northeast of the city, is the local comparison — a genuinely different
# microclimate from the valley-floor airport, the same role Auzeville plays
# for Castanet-Tolosan. Its own temperature reporting has a real gap from
# late June 2026 onward (rainfall continues; TMAX/TMIN go blank) — confirmed
# against the raw NOAA feed, not a fetch issue in this pipeline.
# =============================================================================

SITE <- list(
  key    = "albuquerque",
  source = "noaa",

  paths = list(
    raw       = "data/raw/albuquerque",
    processed = "data/processed/albuquerque",
    outputs   = "outputs/albuquerque",
    figures   = "outputs/albuquerque/figures"
  ),

  stations = c(
    "USW00023050" = "Albuquerque Airport",
    "USC00290225" = "Albuquerque Foothills NE"
  ),
  reference_station = "Albuquerque Airport",
  local_station      = "Albuquerque Foothills NE",
  local_has_temp     = TRUE,
  local_relation_clause = "sits in the foothills district in the northeast of the city, well above the valley-floor airport",
  local_rationale = paste(
    "Albuquerque Foothills NE (station USC00290225), in the northeast of the city, is a",
    "genuinely different microclimate from the valley-floor airport and provides the local",
    "comparison — though its temperature reporting stops in late June 2026 (rainfall",
    "continues, TMAX/TMIN go blank), a real gap in the upstream feed, not a fetch issue here.",
    "Albuquerque Airport (station USW00023050) provides the temperature trend: one continuous",
    "record back to 1931, no splice needed, and one of NOAA's long-term global climate",
    "reference stations."
  ),

  city = "Albuquerque", region = "New Mexico", country = "USA",

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
      "USW00023050" = list(start = "1931-03-01", end = "2030-12-31"),
      "USC00290225" = list(start = "1991-10-01", end = "2030-12-31")
    )
  )
)
