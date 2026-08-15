# =============================================================================
# Site: Lyon (Rhône, France), via Météo-France's daily climatological base.
#
# Lyon-Bron (69029001), the city's historic airport 7 km east of the centre, is
# the reference: 1921-> with 105 complete years and NOT ONE incomplete year
# inside that span — the cleanest long record of any site in this project.
#
# Saint-Genis-Laval (69204002) is tempting and was checked first: it reaches
# back to 1881 and has 122 complete years, more than Bron. It is rejected as the
# reference because those years are not contiguous — 1920-1939 is almost
# entirely missing (20 of 23 absent years fall in that window), plus 1900, 1903
# and 1991. A 145-year span with a 20-year hole through the middle is a worse
# trend basis than a gap-free 105-year one, and this project's headline rate is
# a least-squares slope on the reference station. Bron also carries the city's
# name, which the chapter prose leans on.
#
# Lyon-Saint-Exupéry (69299001), the current international airport ~25 km east,
# is the local comparison: 1976-> , 50 complete years, also gap-free. Shorter
# and more recent than the reference, which is the shape the shared template
# assumes (see R/lib/narrative.R's local_temp_paragraph).
#
# Also available and not used: Lyon Tête d'Or (69123002), a gauge in the city
# centre park with 60 complete RAIN years (1961-> ) but only 17 complete
# temperature years (2007-> , with 2017-18 missing) — too short and too holed to
# carry a local temperature series.
# =============================================================================

SITE <- list(
  key    = "lyon",
  source = "meteofrance",

  paths = list(
    raw       = "data/raw/lyon",
    processed = "data/processed/lyon",
    outputs   = "outputs/lyon",
    figures   = "outputs/lyon/figures"
  ),

  stations = c(
    "69029001" = "Lyon-Bron",              # historic airport, 1921-> , gap-free
    "69299001" = "Lyon-Saint-Exupéry"      # current international airport, 1976->
  ),
  reference_station = "Lyon-Bron",
  local_station      = "Lyon-Saint-Exupéry",
  local_has_temp     = TRUE,
  local_relation_clause = "is Lyon's current international airport, about 25 km east of the city",
  local_rationale = paste(
    "Lyon-Saint-Exupéry (station 69299001), the city's international airport about 25 km",
    "east, has recorded temperature since 1976 with no missing years and provides the local",
    "comparison. Lyon-Bron (station 69029001), the historic airport 7 km east of the centre,",
    "provides the trend: 1921 onward with 105 complete years and no incomplete year in",
    "between. Saint-Genis-Laval, in the southern suburbs, reaches back further — to 1881 —",
    "but 1920–1939 is almost entirely missing from it, so a gap-free century at Bron is the",
    "sounder basis for a slope than a longer record with a hole through its middle."
  ),

  city = "Lyon", region = "Rhône", country = "France",

  citation = list(
    source_name   = "Météo-France",
    dataset_label = "Données climatologiques de base – quotidiennes",
    scope_label   = "dept. 69",
    url           = "https://meteo.data.gouv.fr/datasets/6569b51ae64326786e4e8e1a",
    licence       = "Licence Ouverte / Open Licence (Etalab 2.0)"
  ),

  # ---- source-specific fetch parameters (meteofrance.R) ---------------------
  meteofrance = list(
    base_url = "https://meteofrance.s3.sbg.io.cloud.ovh.net/data/synchro_ftp/BASE/QUOT",
    dept = "69",   # Rhône
    # These era names encode years and ROTATE each January — see
    # R/sites/castanet.R for the same caveat. Verified 2026-08-15.
    eras = c("avant-1949", "previous-1950-2024", "latest-2025-2026"),
    field_docs = c("RR-T-Vent")
  )
)
