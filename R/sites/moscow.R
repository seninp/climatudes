# =============================================================================
# Site: Moscow (Russia), via Roshydromet's AISORI-M portal.
#
# AISORI-M (aisori-m.meteo.ru) is a login/session-gated web app with no
# stable, scriptable URL — unlike every other source in this project, its
# data is exported by hand and dropped into data/raw/moscow/ (see
# R/sources/meteoru.R and the "moscow-aisori-m-data-source" memory for the
# exact query steps). This site has no second station: the export (WMO
# 27612, Moscow VDNKh) is single-station, so `local_station` is left unset
# — see the HAS_LOCAL guard in R/01_plot.R and R/lib/narrative.R.
#
# Freshness caveat: real (quality-flag "0") data reaches only as far as the
# export was queried for — confirmed 2025-12-31 as of the 2026-08-14 pull.
# NOAA's internationally-shared GHCN-Daily mirror of the same station stalls
# around January 2022 (Russia appears to have stopped sharing it over GTS);
# AISORI-M's own archive is not frozen, just not "today" like the other
# seven sites — this site's "current year" will read as 2025, not 2026.
# =============================================================================

SITE <- list(
  key    = "moscow",
  source = "meteoru",

  paths = list(
    raw       = "data/raw/moscow",
    processed = "data/processed/moscow",
    outputs   = "outputs/moscow",
    figures   = "outputs/moscow/figures"
  ),

  stations = c(
    "27612" = "Moscow"
  ),
  reference_station = "Moscow",
  # local_station intentionally unset — see header note.
  local_has_temp     = FALSE,
  local_rationale = paste(
    "This export from Roshydromet's AISORI-M portal (aisori-m.meteo.ru) includes only",
    "WMO index 27612 (Moscow, VDNKh) — the manual, login-gated query wasn't run for a",
    "second nearby station. Every other site in this project pairs a long regional",
    "reference with a shorter local one; re-querying AISORI-M with an additional",
    "station selected would let a future update add that pairing here too."
  ),

  # Reference-station geography. Source: WMO station registry, index 27612 -- NOT from the AISORI-M export, which carries no coordinates.
  # Latitude drives the hemisphere test in the Köppen classification, so it
  # must be the real signed value, not a magnitude.
  latitude = 55.833, longitude = 37.617, elevation_m = 156,

  city = "Moscow", region = "Moscow", country = "Russia",

  citation = list(
    source_name   = "Roshydromet / RIHMI-WDC — AISORI-M",
    dataset_label = "AISORI-M daily archive, Сутки → TTTR (temperature + precipitation)",
    scope_label   = "WMO 27612, manually exported",
    url           = "http://aisori-m.meteo.ru/waisori/index0.xhtml",
    licence       = "Not openly licensed — registered as an official reference publication (Rospatent 2019621537); used here for personal, non-commercial analysis only"
  ),

  # ---- source-specific parameters (meteoru.R) --------------------------------
  # No fetch parameters: meteoru.R reads whatever .zip export already sits in
  # data/raw/moscow/ (most recently modified wins) rather than downloading.
  meteoru = list()
)
