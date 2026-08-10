# =============================================================================
# Shared narrative/citation helpers, used by 01_plot.R (captions), 02_report.R
# and 03_readme.R (report prose). Site-specific facts come from the SITE list
# (R/sites/<site>.R); this file only holds the generic computation.
# =============================================================================

# ---- station id lookup (reverse of SITE$stations) ---------------------------
station_id <- function(site, name) names(site$stations)[match(name, site$stations)]

# ---- one-line upstream citation, shared by every plot caption ---------------
caption_source_line <- function(cite) {
  scope <- if (nzchar(cite$scope_label)) paste0(", ", cite$scope_label) else ""
  sprintf("Source: %s, %s%s (%s). %s.",
          cite$source_name, cite$dataset_label, scope, cite$url, cite$licence)
}

# ---- "since {when}" clause for a record's start year, for the lead paragraph -
# Bucketed by century-ish era rather than spelled out per site — it only needs
# to be roughly right ("mid-20th century" reads fine for 1947 or 1948; "late
# 19th century" for a station starting 1881), and stays correct automatically
# if a station's usable start year ever shifts.
since_phrase <- function(yr0) {
  if (yr0 <= 1870) "the mid-19th century"
  else if (yr0 <= 1900) "the late 19th century"
  else if (yr0 <= 1930) "the early 20th century"
  else if (yr0 <= 1970) "the mid-20th century"
  else "the late 20th century"
}

# ---- neutral bold markers ----------------------------------------------------
# build_common_fills() is shared by an HTML stage and a Markdown stage, which
# spell "bold" differently (<strong>...</strong> vs **...**). Sentences here
# wrap emphasis in these markers; each stage converts them to its own syntax as
# the last step before substitution (see resolve_bold_html()/resolve_bold_md()).
BOLD_OPEN  <- "BOLD_OPEN"
BOLD_CLOSE <- "BOLD_CLOSE"
bold <- function(x) paste0(BOLD_OPEN, x, BOLD_CLOSE)
resolve_bold_html <- function(x) gsub(BOLD_CLOSE, "</strong>", gsub(BOLD_OPEN, "<strong>", x, fixed = TRUE), fixed = TRUE)
resolve_bold_md   <- function(x) gsub(BOLD_CLOSE, "**",         gsub(BOLD_OPEN, "**",        x, fixed = TRUE), fixed = TRUE)

# ---- fields shared verbatim by both the HTML report and the README section --
# Everything here is prose/number logic common to both output formats; each
# stage adds its own format-specific bits (image embeds vs figure paths, HTML
# vs Markdown table rows) on top of this list, then resolves the bold markers
# above to its own syntax.
build_common_fills <- function(stats, site) {
  fmt <- function(x, d = 2) formatC(x, format = "f", digits = d)
  ex <- stats$extremes
  rn <- stats$rain
  y  <- stats$ytd

  both_sentence <- if (length(stats$both_years) == 0)
    "No single year managed to hit both extremes." else
    sprintf("Years hitting both extremes: %s.", paste(stats$both_years, collapse = ", "))

  hot_recent_clause <- if (isTRUE(stats$hot_all_recent)) " — all of them recent —" else " —"
  cold_era_clause   <- if (isTRUE(stats$cold_all_but_one)) ", all but one before 2000" else ""
  # Parenthetical year lists — omitted entirely (not left as an empty "()")
  # when a site's climate never crosses one of the two thresholds, e.g. Zurich
  # never touches +30 °C on the smoothed daily mean.
  hot_years_paren  <- if (length(stats$hot_years)  == 0) "" else sprintf(" (%s)", paste(stats$hot_years,  collapse = ", "))
  cold_years_paren <- if (length(stats$cold_years) == 0) "" else sprintf(" (%s)", paste(stats$cold_years, collapse = ", "))
  raw_both_sentence <- if (length(stats$raw_both_years) == 0)
    "(On the raw, unsmoothed daily mean, no year touches both extremes.)" else
    sprintf("(If the threshold is applied instead to the raw, unsmoothed daily mean, %s %s touch both extremes.)",
            paste(stats$raw_both_years, collapse = " and "),
            if (length(stats$raw_both_years) == 1) "alone" else "each")

  ytd_sentence <- if (isTRUE(y$is_record)) {
    lead      <- bold(sprintf("%d is the warmest %s in %d years", stats$cur_year, y$window, y$n_years))
    cur_val   <- bold(sprintf("%s °C", fmt(y$cur, 1)))
    anom_val  <- bold(sprintf("+%s °C above the long-term normal", fmt(y$cur_anom, 1)))
    sprintf(paste0("Measured like-for-like, %s at ",
                   "%s: %s — +%s °C above the previous record ",
                   "(%d, %s °C) and %s (%s °C). ",
                   "This is exactly the point of the chart: a year still in progress ",
                   "can already stand out against the whole record."),
            lead, site$reference_station, cur_val, fmt(y$cur - y$rec_val, 1),
            y$rec_year, fmt(y$rec_val, 1), anom_val, fmt(y$normal, 1))
  } else {
    rank_val <- bold(sprintf("#%d of %d", y$rank, y$n_years))
    sprintf(paste0("Measured like-for-like over %s, %d currently ranks %s at ",
                   "%s (%s °C). The warmest such window on record remains ",
                   "%d (%s °C)."),
            y$window, stats$cur_year, rank_val, site$reference_station,
            fmt(y$cur, 1), y$rec_year, fmt(y$rec_val, 1))
  }

  early_span <- sprintf("%d–%d", stats$yr0, stats$yr0 + 9)

  # The local-station comparison paragraph: only meaningful where the local
  # station actually carries a temperature record (Karlsruhe's does not — its
  # local tier is rain-only, see R/sites/karlsruhe.R).
  local_temp_paragraph <- if (site$local_has_temp)
    sprintf(paste0("The local %s station, which %s, only covers %d→%d. Its slope over ",
                   "that shorter, more recent window is steeper (+%s °C/decade) — but so is ",
                   "%s’s over the same years (+%s °C/decade): recent decades warm faster, and ",
                   "the local station sits almost exactly on the regional mean. The local and ",
                   "regional signals are the same."),
            site$local_station, site$local_relation_clause, stats$local_yr0, stats$local_yr1,
            fmt(stats$slope_dec_local), site$reference_station, fmt(stats$slope_dec_ref_localwin)) else
    sprintf(paste0("%s carries no temperature record; %s alone provides the temperature trend ",
                   "for this area. The local comparison here uses rainfall instead — see below."),
            site$local_station, site$reference_station)

  fig1_local_caption <- if (site$local_has_temp)
    sprintf(" The green series (%s) %s; it tracks the long %s reference mean almost exactly.",
            site$local_station, site$local_relation_clause, site$reference_station) else ""

  ref_rec <- stats$records[[which(vapply(stats$records, function(r) r$station, character(1)) ==
                                   site$reference_station)]]
  closing_record_note <- sprintf(
    "At %s, the all-time heat (%s) is far more recent than the all-time cold (%s) — the same warming signature seen throughout this report.",
    site$reference_station, ref_rec$hot$date, ref_rec$cold$date)

  c(
    YR0 = stats$yr0, YR1 = stats$yr1, NYEARS = stats$yr1 - stats$yr0,
    SLOPE_DEC = fmt(stats$slope_dec_ref),
    RISE = fmt(stats$rise_ref, 1),
    MEAN_RECENT = fmt(stats$mean_recent, 1), MEAN_EARLY = fmt(stats$mean_early, 1),
    EARLY_SPAN = early_span,
    N_STATION_YEARS = stats$n_station_years,
    LOCAL_YR0 = stats$local_yr0, LOCAL_YR1 = stats$local_yr1,
    SLOPE_DEC_LOCAL = if (site$local_has_temp) fmt(stats$slope_dec_local) else "",
    SLOPE_DEC_REF_LOCALWIN = if (site$local_has_temp) fmt(stats$slope_dec_ref_localwin) else "",
    CLIM_YR0 = stats$clim_yr0, CLIM_YR1 = stats$clim_yr1, CLIM_NYEARS = stats$clim_nyears,
    CUR_YEAR = stats$cur_year,
    HOT_THR = stats$hot_thr, COLD_THR = stats$cold_thr,
    N_HOT = length(stats$hot_years), N_COLD = length(stats$cold_years),
    SMOOTH_WINDOW = stats$smooth_window, SMOOTH_HALF = (stats$smooth_window - 1) %/% 2,
    HOT_YEARS = paste(stats$hot_years, collapse = ", "),
    COLD_YEARS = paste(stats$cold_years, collapse = ", "),
    HOT_YEARS_PAREN = hot_years_paren, COLD_YEARS_PAREN = cold_years_paren,
    BOTH_SENTENCE = both_sentence,
    HOT_RECENT_CLAUSE = hot_recent_clause, COLD_ERA_CLAUSE = cold_era_clause,
    RAW_BOTH_SENTENCE = raw_both_sentence,
    YTD_WINDOW = y$window, YTD_NORMAL = fmt(y$normal, 1), YTD_SENTENCE = ytd_sentence,
    YTD_NYEARS = y$n_years, YTD_NYEARS_PRIOR = y$n_years - 1,
    YTD_STANDING = if (isTRUE(y$is_record)) bold(sprintf("#1 of %d — record", y$n_years))
                   else bold(sprintf("#%d of %d", y$rank, y$n_years)),
    EXT_SPAN0 = sprintf("%d–%d", ex$yr0, ex$yr0 + 9),
    EXT_SPAN1 = sprintf("%d–%d", ex$yr1 - 9, ex$yr1),
    HOT_TX = ex$hot_thr, VHOT_TX = ex$vhot_thr, TROP_TX = ex$trop_thr,
    FROST_EARLY = ex$frost_early, FROST_RECENT = ex$frost_recent,
    HOT_EARLY = ex$hot_early, HOT_RECENT = ex$hot_recent,
    VHOT_EARLY = ex$vhot_early, VHOT_RECENT = ex$vhot_recent,
    TROP_EARLY = ex$trop_early, TROP_RECENT = ex$trop_recent,
    RAIN_YR0 = rn$yr0, RAIN_YR1 = rn$yr1, RAIN_NYEARS = rn$n_years, RAIN_MEAN = rn$mean_ref,
    RAIN_SLOPE = sprintf("%+.0f", rn$slope_dec), RAIN_P = fmt(rn$p, 2),
    WETTEST_YEAR = rn$wettest_year, WETTEST_MM = rn$wettest_mm,
    DRIEST_YEAR = rn$driest_year, DRIEST_MM = rn$driest_mm,
    WET_MONTH = rn$wet_month, WET_MONTH_MM = rn$wet_month_mm,
    DRY_MONTH = rn$dry_month, DRY_MONTH_MM = rn$dry_month_mm,
    MIN_DAYS = MIN_DAYS, MIN_YTD_DAYS = MIN_YTD_DAYS,
    # site facts
    CITY = site$city, REGION = site$region, COUNTRY = site$country,
    REF_STATION = site$reference_station, LOCAL_STATION = site$local_station,
    REF_ID = station_id(site, site$reference_station),
    LOCAL_ID = station_id(site, site$local_station),
    SOURCE_NAME = site$citation$source_name,
    DATASET_LABEL = site$citation$dataset_label,
    CITATION_URL = site$citation$url,
    LICENCE = site$citation$licence,
    SINCE_PHRASE = since_phrase(stats$yr0),
    LOCAL_RATIONALE = site$local_rationale,
    LOCAL_TEMP_PARAGRAPH = local_temp_paragraph,
    LOCAL_RELATION_CLAUSE = if (site$local_has_temp) site$local_relation_clause else "",
    FIG1_LOCAL_CAPTION = fig1_local_caption,
    CLOSING_RECORD_NOTE = closing_record_note
  )
}
