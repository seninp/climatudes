# =============================================================================
# Site: Zurich (Switzerland), via MeteoSwiss Open Data.
#
# Zürich-Fluntern (SMA) is MeteoSwiss's homogeneous long-term reference for
# Zurich (Swiss NBCN network, temperature back to 1881 / mean back to 1864) but
# NBCN carries no daily precipitation — that comes from the sibling automatic-
# network (SMN) file for the same physical station. Zürich-Affoltern (REH), a
# district in the north of the city, is a plain SMN station (temp + precip both
# from one file) used as the local comparison, the way Auzeville-Tolosane-INRAE
# is used for Castanet-Tolosan.
# =============================================================================

SITE <- list(
  key    = "zurich",
  source = "meteoswiss",

  paths = list(
    raw       = "data/raw/zurich",
    processed = "data/processed/zurich",
    outputs   = "outputs/zurich",
    figures   = "outputs/zurich/figures"
  ),

  stations = c(
    "SMA" = "Zürich-Fluntern",
    "REH" = "Zürich-Affoltern"
  ),
  reference_station = "Zürich-Fluntern",
  local_station      = "Zürich-Affoltern",
  local_has_temp     = TRUE,
  local_relation_clause = "is MeteoSwiss’s automatic station in Zurich’s Affoltern district",
  local_rationale = paste(
    "MeteoSwiss’s homogeneous long-term series (Swiss NBCN) covers only about thirty",
    "stations nationwide; Affoltern — a district in the north of Zurich — isn’t one of",
    "them. REH, MeteoSwiss’s automatic station there, is the closest full station to",
    "that neighbourhood and has carried temperature since 1978. Zürich-Fluntern",
    "(station SMA), in the hills above the city centre, provides the historical depth —",
    "a homogeneous record back to 1881 — needed to see the underlying trend and to draw",
    "the day-by-day climatology."
  ),

  city = "Zurich", region = "Kanton Zürich", country = "Switzerland",

  citation = list(
    source_name   = "MeteoSwiss",
    dataset_label = "Open Government Data — climate stations (NBCN) & automatic weather stations (SMN)",
    scope_label   = "",
    url           = "https://opendatadocs.meteoswiss.ch/",
    licence       = "MeteoSwiss Open Data (attribution required: “Source: MeteoSwiss”)"
  ),

  # ---- source-specific fetch parameters (meteoswiss.R) -----------------------
  # Fixed filenames per station/granularity (no era-rotation like Météo-France).
  # Each station's daily file for a given dataset is:
  #   https://data.geo.admin.ch/ch.meteoschweiz.ogd-<dataset>/<abbr_lower>/ogd-<dataset>_<abbr_lower>_d_historical.csv
  #   https://data.geo.admin.ch/ch.meteoschweiz.ogd-<dataset>/<abbr_lower>/ogd-<dataset>_<abbr_lower>_d_recent.csv
  meteoswiss = list(
    base_url = "https://data.geo.admin.ch",
    # dataset() per station: "nbcn" = homogeneous long series (temp only — no
    # daily precip); "smn" = automatic network (temp + precip in one file).
    # SMA needs temp from nbcn (the homogeneous, break-corrected series) and
    # precip from smn (its own daily precip is only in the raw operational
    # dataset); REH has no nbcn record at all, so both come from smn.
    stations = list(
      SMA = list(temp_dataset = "nbcn", rain_dataset = "smn"),
      REH = list(temp_dataset = "smn",  rain_dataset = "smn")
    )
  )
)
