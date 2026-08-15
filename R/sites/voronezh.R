# =============================================================================
# Site: Voronezh (Russia), via Roshydromet's AISORI-M portal.
#
# Same source and caveats as R/sites/moscow.R: AISORI-M is login/session-gated
# with no stable URL, so the export is manual, dropped into
# data/raw/voronezh/, and read as-is by R/sources/meteoru.R. Single station
# (WMO 34123, Voronezh) — no `local_station`.
#
# Freshness: real (quality-flag "0") data reaches 2026-02-28 as of the
# 2026-08-14 export — fresher than Moscow's own station in the same export
# (2025-12-31), for reasons not established here (possibly just which
# station Roshydromet last synced). Still short of "today," so this site's
# "current year" reads as 2026 but only through February.
# =============================================================================

SITE <- list(
  key    = "voronezh",
  source = "meteoru",

  paths = list(
    raw       = "data/raw/voronezh",
    processed = "data/processed/voronezh",
    outputs   = "outputs/voronezh",
    figures   = "outputs/voronezh/figures"
  ),

  stations = c(
    "34123" = "Voronezh"
  ),
  reference_station = "Voronezh",
  # local_station intentionally unset — see header note.
  local_has_temp     = FALSE,
  local_rationale = paste(
    "This export from Roshydromet's AISORI-M portal (aisori-m.meteo.ru) includes only",
    "WMO index 34123 (Voronezh) — the manual, login-gated query wasn't run for a second",
    "nearby station. Every other site in this project pairs a long regional reference",
    "with a shorter local one; re-querying AISORI-M with an additional station selected",
    "would let a future update add that pairing here too."
  ),

  # Reference-station geography. Source: WMO station registry, index 34123 -- NOT from the AISORI-M export, which carries no coordinates.
  # Latitude drives the hemisphere test in the Köppen classification, so it
  # must be the real signed value, not a magnitude.
  latitude = 51.65, longitude = 39.25, elevation_m = 154,

  city = "Voronezh", region = "Voronezh Oblast", country = "Russia",

  citation = list(
    source_name   = "Roshydromet / RIHMI-WDC — AISORI-M",
    dataset_label = "AISORI-M daily archive, Сутки → TTTR (temperature + precipitation)",
    scope_label   = "WMO 34123, manually exported",
    url           = "http://aisori-m.meteo.ru/waisori/index0.xhtml",
    licence       = "Not openly licensed — registered as an official reference publication (Rospatent 2019621537); used here for personal, non-commercial analysis only"
  ),

  # ---- source-specific parameters (meteoru.R) --------------------------------
  meteoru = list()
)
