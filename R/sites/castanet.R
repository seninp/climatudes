# =============================================================================
# Site: Castanet-Tolosan (Haute-Garonne, France) — the original site.
# Paths are the legacy root locations (this project had exactly one site before
# Zurich/Karlsruhe were added) — left untouched to avoid disturbing anything
# already committed or linked from README.md.
# =============================================================================

SITE <- list(
  key    = "castanet",
  source = "meteofrance",

  paths = list(
    raw       = "data/raw",
    processed = "data/processed",
    outputs   = "outputs",
    figures   = "outputs/figures"
  ),

  stations = c(
    "31035001" = "Auzeville-Tolosane-INRAE",   # on the edge of Castanet-Tolosan
    "31069001" = "Toulouse-Blagnac"             # long regional reference (1947->)
  ),
  reference_station = "Toulouse-Blagnac",
  local_station      = "Auzeville-Tolosane-INRAE",
  local_has_temp     = TRUE,
  local_relation_clause = "is the station on the edge of Castanet-Tolosan",
  local_rationale = paste(
    "The Météo-France dataset for department 31 contains no station literally",
    "named “Castanet-Tolosan”. The Auzeville-Tolosane-INRAE station (no. 31035001),",
    "on the INRAE/ENSAT campus, sits right on the Castanet-Tolosan boundary — the most",
    "representative local record. Toulouse-Blagnac (no. 31069001) provides the historical",
    "depth needed to see the underlying trend and to draw the day-by-day climatology."
  ),

  # Reference-station geography. Source: Meteo-France station metadata (LAT/LON/ALTI in the daily CSV), station 31069001.
  # Latitude drives the hemisphere test in the Köppen classification, so it
  # must be the real signed value, not a magnitude.
  latitude = 43.621, longitude = 1.378833, elevation_m = 151,

  city = "Castanet-Tolosan", region = "Haute-Garonne", country = "France",

  citation = list(
    source_name   = "Météo-France",
    dataset_label = "Données climatologiques de base – quotidiennes",
    scope_label   = "dept. 31",
    url           = "https://meteo.data.gouv.fr/datasets/6569b51ae64326786e4e8e1a",
    licence       = "Licence Ouverte / Open Licence (Etalab 2.0)"
  ),

  # ---- source-specific fetch parameters (meteofrance.R) ---------------------
  meteofrance = list(
    base_url = "https://meteofrance.s3.sbg.io.cloud.ovh.net/data/synchro_ftp/BASE/QUOT",
    # Equivalent mirror if the above is unreachable:
    #   https://object.files.data.gouv.fr/meteofrance/data/synchro_ftp/BASE/QUOT
    dept = "31",   # Haute-Garonne
    # The three eras. IMPORTANT: these names encode years and ROTATE each January —
    # when 2027 opens, `latest-2025-2026` stops resolving (404) and its rows migrate
    # into `previous-1950-2026`. Verified 2026-07-25.
    eras = c("avant-1949", "previous-1950-2024", "latest-2025-2026"),
    field_docs = c("RR-T-Vent")
  )
)
