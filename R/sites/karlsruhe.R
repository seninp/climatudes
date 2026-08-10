# =============================================================================
# Site: Karlsruhe (Baden-Württemberg, Germany), via DWD (Deutscher Wetterdienst)
# Climate Data Center open data.
#
# Rheinstetten (04177) is Karlsruhe's regional reference. Its own record has a
# 1985-07 -> 2008-10 gap (it ran as "Forchheim" 1948-85, then went dark) — but
# DWD documents a clean handoff: the original in-city station (02522) ran
# continuously 1876-01-01 -> 2008-10-31, one day before 04177 reopened as its
# successor a few km south at the regional airfield. `dwd$stations$"04177"$
# predecessor` below tells R/sources/dwd.R to splice 02522's full run in ahead
# of 04177's, giving one gap-free 1876-> series under the "Rheinstetten" name
# instead of a 04177-only record with an undisclosed 24-year hole in it.
#
# No active DWD station near Grötzingen — a district on Karlsruhe's eastern
# edge — carries a temperature record. The nearest that once did (Augustenberg)
# closed in 1985; the nearest ACTIVE station of any kind is Karlsruhe-
# Wolfartsweier (02523), 5.4 km away — but it is precipitation only. Unlike
# Castanet-Tolosan/Auzeville or Zurich/Affoltern, Karlsruhe's local tier is
# therefore rain-only: `local_has_temp = FALSE` disables the local station's
# temperature series and record-day entries throughout the pipeline, while its
# rainfall still pairs normally with Rheinstetten.
# =============================================================================

SITE <- list(
  key    = "karlsruhe",
  source = "dwd",

  paths = list(
    raw       = "data/raw/karlsruhe",
    processed = "data/processed/karlsruhe",
    outputs   = "outputs/karlsruhe",
    figures   = "outputs/karlsruhe/figures"
  ),

  stations = c(
    "04177" = "Rheinstetten",
    "02523" = "Karlsruhe-Wolfartsweier"
  ),
  reference_station = "Rheinstetten",
  local_station      = "Karlsruhe-Wolfartsweier",
  local_has_temp     = FALSE,   # rain gauge only — see header note
  local_rationale = paste(
    "No active DWD station near Grötzingen — a district on Karlsruhe’s eastern edge —",
    "carries a temperature record; the nearest that once did (Augustenberg, under 1 km",
    "away) closed in 1985. Karlsruhe-Wolfartsweier (station 02523), 5.4 km away and",
    "active since 1931, is the nearest active rain gauge and stands in for local",
    "rainfall. Rheinstetten (station 04177) provides the temperature trend, spliced",
    "with its in-city predecessor (02522, 1876–2008) for the historical depth needed",
    "to see the underlying trend."
  ),

  city = "Karlsruhe", region = "Baden-Württemberg", country = "Germany",

  citation = list(
    source_name   = "DWD (Deutscher Wetterdienst)",
    dataset_label = "Climate Data Center — daily station observations (KL) & precipitation (RR)",
    scope_label   = "",
    url           = "https://opendata.dwd.de/climate_environment/CDC/observations_germany/climate/daily/",
    licence       = "Creative Commons BY 4.0"
  ),

  # ---- source-specific fetch parameters (dwd.R) ------------------------------
  dwd = list(
    base_url = "https://opendata.dwd.de/climate_environment/CDC/observations_germany/climate/daily",
    stations = list(
      "04177" = list(product = "kl",                          # temperature + precipitation
                     predecessor = list(id = "02522", product = "kl")),  # in-city, 1876 -> 2008-10-31
      "02523" = list(product = "more_precip")  # precipitation only
    )
  )
)
