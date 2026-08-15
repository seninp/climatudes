# =============================================================================
# Site: Paris (Île-de-France), via Météo-France's daily climatological base.
#
# Paris-Montsouris (75114001), in the Parc Montsouris in the 14th, is the
# reference and the best record in this project: 1873 onward, 153 complete
# years, and NOT ONE incomplete year inside that span. Longer than Karlsruhe
# (148) and Zurich (143), and unlike either it has no interior gaps at all.
#
# Local comparison is the Jardin du Luxembourg gauge (75106001), 2.5 km north in
# the 6th: 1978 onward, 45 complete years, gap-free apart from 2013-2015. Both
# are city-centre park sites a few metres apart in elevation, so the pairing
# isolates almost nothing but the sites themselves — which is the point of it.
# Labelled "Paris-Luxembourg" here because Météo-France's own NOM_USUEL is the
# bare "LUXEMBOURG", which in a table of cities reads like the country.
#
# Rejected: OBSERVATOIRE (75114002) reaches back to 1816 — the oldest series in
# the whole dataset — but it ends in 1903 and has 19 interior gaps, so it cannot
# carry a trend to the present. TOUR EIFFEL (75107005) has only 23 complete
# years and sits on a tower, which is not a screen-height climate record.
# LARIBOISIERE (75110001) has 97 complete RAIN years but only 6 of temperature.
# =============================================================================

SITE <- list(
  key    = "paris",
  source = "meteofrance",

  paths = list(
    raw       = "data/raw/paris",
    processed = "data/processed/paris",
    outputs   = "outputs/paris",
    figures   = "outputs/paris/figures"
  ),

  stations = c(
    "75114001" = "Paris-Montsouris",   # 1873-> , 153 complete years, no gaps
    "75106001" = "Paris-Luxembourg"    # 1978-> , 45 complete years
  ),
  reference_station = "Paris-Montsouris",
  local_station      = "Paris-Luxembourg",
  local_has_temp     = TRUE,
  local_relation_clause = "is the gauge in the Jardin du Luxembourg, 2.5 km north in the 6th arrondissement",
  local_rationale = paste(
    "The Jardin du Luxembourg gauge (station 75106001), 2.5 km north of Montsouris, has",
    "recorded temperature since 1978 — 45 complete years, with only 2013–2015 missing — and",
    "provides the local comparison. Paris-Montsouris (station 75114001), in the Parc",
    "Montsouris in the 14th, provides the trend, and it is the strongest record in this",
    "collection: 1873 onward with 153 complete years and no incomplete year in between.",
    "The Paris Observatory series is older still, beginning in 1816, but it ends in 1903 and",
    "has nineteen gaps, so it cannot carry a trend to the present."
  ),

  # Reference-station geography. Source: Météo-France station metadata
  # (LAT/LON/ALTI in the daily CSV), station 75114001.
  # Latitude drives the hemisphere test in the Köppen classification, so it
  # must be the real signed value, not a magnitude.
  latitude = 48.8217, longitude = 2.3378, elevation_m = 75,

  city = "Paris", region = "Île-de-France", country = "France",

  citation = list(
    source_name   = "Météo-France",
    dataset_label = "Données climatologiques de base – quotidiennes",
    scope_label   = "dept. 75",
    url           = "https://meteo.data.gouv.fr/datasets/6569b51ae64326786e4e8e1a",
    licence       = "Licence Ouverte / Open Licence (Etalab 2.0)"
  ),

  # ---- source-specific fetch parameters (meteofrance.R) ---------------------
  meteofrance = list(
    base_url = "https://meteofrance.s3.sbg.io.cloud.ovh.net/data/synchro_ftp/BASE/QUOT",
    dept = "75",   # Paris
    # These era names encode years and ROTATE each January — see
    # R/sites/castanet.R for the same caveat. Verified 2026-08-15.
    eras = c("avant-1949", "previous-1950-2024", "latest-2025-2026"),
    field_docs = c("RR-T-Vent")
  )
)
