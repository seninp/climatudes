# =============================================================================
# Site: Nouméa (New Caledonia), via Météo-France.
#
# New Caledonia has no mainland "département" number, but Météo-France folds
# it into the same "Données climatologiques de base – quotidiennes" dataset
# under the pseudo-département code 988 — same file layout, same three
# rotating eras, as Castanet-Tolosan's dept 31 (see R/sources/meteofrance.R,
# already fully generic in `mf$dept`; no source-module changes needed).
#
# Nouméa (98818001) is the long reference record, 1950 to today. Nouméa-
# Magenta (98818002), the in-town domestic airfield, has carried a complete,
# gap-free temperature record since 1964 and serves as the local comparison
# — unlike Castanet-Tolosan's Auzeville or Zurich's Affoltern, no data-
# quality caveat is needed here.
# =============================================================================

SITE <- list(
  key    = "noumea",
  source = "meteofrance",

  paths = list(
    raw       = "data/raw/noumea",
    processed = "data/processed/noumea",
    outputs   = "outputs/noumea",
    figures   = "outputs/noumea/figures"
  ),

  stations = c(
    "98818001" = "Nouméa",
    "98818002" = "Nouméa-Magenta"
  ),
  reference_station = "Nouméa",
  local_station      = "Nouméa-Magenta",
  local_has_temp     = TRUE,
  local_relation_clause = "is Nouméa's in-town domestic airfield, Magenta",
  local_rationale = paste(
    "Nouméa-Magenta (station 98818002), the in-town domestic airfield, has carried a",
    "complete, gap-free temperature record since 1964 and provides the local",
    "comparison. Nouméa (station 98818001) provides the historical depth needed to see",
    "the underlying trend, back to 1950."
  ),

  # Reference-station geography. Source: Meteo-France station metadata (LAT/LON/ALTI in the daily CSV), station 98818001.
  # Latitude drives the hemisphere test in the Köppen classification, so it
  # must be the real signed value, not a magnitude.
  latitude = -22.276, longitude = 166.452833, elevation_m = 69,

  city = "Nouméa", region = "New Caledonia", country = "France",

  citation = list(
    source_name   = "Météo-France",
    dataset_label = "Données climatologiques de base – quotidiennes",
    scope_label   = "dept. 988 (Nouvelle-Calédonie)",
    url           = "https://meteo.data.gouv.fr/datasets/6569b51ae64326786e4e8e1a",
    licence       = "Licence Ouverte / Open Licence (Etalab 2.0)"
  ),

  # ---- source-specific fetch parameters (meteofrance.R) ---------------------
  meteofrance = list(
    base_url = "https://meteofrance.s3.sbg.io.cloud.ovh.net/data/synchro_ftp/BASE/QUOT",
    dept = "988",   # Nouvelle-Calédonie
    # The three eras. IMPORTANT: these names encode years and ROTATE each January —
    # when 2027 opens, `latest-2025-2026` stops resolving (404) and its rows migrate
    # into `previous-1950-2026`. Verified 2026-08-14, mirroring castanet.R's caveat.
    eras = c("avant-1949", "previous-1950-2024", "latest-2025-2026"),
    field_docs = c("RR-T-Vent")
  )
)
