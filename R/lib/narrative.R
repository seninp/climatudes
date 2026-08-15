# =============================================================================
# Shared narrative/citation helpers, used by 01_plot.R (captions), 02_report.R
# and 03_readme.R (report prose). Site-specific facts come from the SITE list
# (R/sites/<site>.R); this file only holds the generic computation.
# =============================================================================

# ---- station id lookup (reverse of SITE$stations) ---------------------------
station_id <- function(site, name) names(site$stations)[match(name, site$stations)]

# ---- YTD standing, as plain text (shared by every per-site chapter AND the
# cross-site comparison table in R/04_compare.R — one wording, so they can
# never silently disagree) ----------------------------------------------------
ytd_standing_text <- function(y) {
  if (!isTRUE(y$has_ytd)) "too early to rank"
  else if (isTRUE(y$is_record)) sprintf("#1 of %d — record", y$n_years)
  else sprintf("#%d of %d", y$rank, y$n_years)
}

# ---- "A, B and C" — an Oxford-comma-free but non-run-on join. Plain
# `paste(x, collapse = " and ")` reads fine for 1-2 items but produces
# "A and B and C and D" for 3+; this project's year lists occasionally run to
# 5-6 items (e.g. Voronezh's both-extremes years). --------------------------
join_and <- function(x) {
  if (length(x) <= 1) return(paste(x, collapse = ""))
  if (length(x) == 2) return(paste(x, collapse = " and "))
  paste0(paste(x[-length(x)], collapse = ", "), " and ", x[length(x)])
}

# ---- year lists, capped ------------------------------------------------------
# Inlining every qualifying year stops being readable past a handful, and for the
# cold threshold most sites cross it in most years: Santa Fe in 148 of 152,
# Moscow and Voronezh in every year of their record. Dumping 148 four-digit
# numbers into a sentence is transcribing a table, not reporting. Past the cap,
# give what the list is actually read for — when it started, when it last
# happened — and leave the full enumeration to the figure, which labels every
# crossing year anyway.
MAX_YEARS_INLINE <- 12L
years_paren <- function(years) {
  if (length(years) == 0) return("")
  if (length(years) <= MAX_YEARS_INLINE)
    return(sprintf(" (%s)", paste(years, collapse = ", ")))
  y <- sort(years)
  sprintf(" (first in %d, most recently %s)", y[1], join_and(tail(y, 2)))
}

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
BOLD_OPEN  <- "BOLD_OPEN"
BOLD_CLOSE <- "BOLD_CLOSE"
bold <- function(x) paste0(BOLD_OPEN, x, BOLD_CLOSE)
resolve_bold_html <- function(x) gsub(BOLD_CLOSE, "</strong>", gsub(BOLD_OPEN, "<strong>", x, fixed = TRUE), fixed = TRUE)
resolve_bold_md   <- function(x) gsub(BOLD_CLOSE, "**",         gsub(BOLD_OPEN, "**",        x, fixed = TRUE), fixed = TRUE)

ITALIC_OPEN  <- "ITALIC_OPEN"
ITALIC_CLOSE <- "ITALIC_CLOSE"
italic <- function(x) paste0(ITALIC_OPEN, x, ITALIC_CLOSE)
resolve_italic_html <- function(x) gsub(ITALIC_CLOSE, "</em>", gsub(ITALIC_OPEN, "<em>", x, fixed = TRUE), fixed = TRUE)
resolve_italic_md   <- function(x) gsub(ITALIC_CLOSE, "*",     gsub(ITALIC_OPEN, "*",    x, fixed = TRUE), fixed = TRUE)

# ---- direction of a before/after extreme-day count, as a single word --------
# "Halved"/"doubled" were fixed words that happened to fit the first 2 sites
# checked (Castanet, Zurich) and were wrong everywhere else once 5 more sites
# were added: Santa Fe's frost days ROSE (150->157), Honolulu's and Nouméa's
# stayed at exactly zero (never had frost to begin with), Karlsruhe/Moscow/
# Voronezh's fell by 12-28%, nowhere near half. A plain direction word makes
# no claim about magnitude, so it can't be wrong about magnitude.
extreme_direction <- function(early, recent) {
  if (early == 0 && recent == 0) "at zero"
  else if (recent > early) "up"
  else if (recent < early) "down"
  else "unchanged"
}

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
  # A site may have no second station at all (e.g. Moscow/Voronezh, manually
  # exported from AISORI-M with a single WMO index) — distinct from
  # local_has_temp = FALSE, which still implies a real rain-only local station
  # (e.g. Karlsruhe-Wolfartsweier).
  HAS_LOCAL <- !is.null(site$local_station)
  # Whether `cur_year` is a genuinely in-progress partial year, or (Moscow's
  # case) already a complete, finished calendar year — see R/01_plot.R.
  YEAR_COMPLETE <- isTRUE(stats$year_complete)

  # "No year hit both extremes" is only worth saying where both extremes are
  # actually reachable. Where one threshold is never crossed at all (Zurich,
  # Santa Fe, Honolulu, Nouméa, Irvine, Albuquerque) nothing COULD hit both, so
  # the sentence states an arithmetic necessity as if it were a finding.
  both_sentence <- if (length(stats$hot_years) == 0 || length(stats$cold_years) == 0) ""
    else if (length(stats$both_years) == 0) "No year hit both extremes."
    else sprintf("Years hitting both extremes: %s.", join_and(stats$both_years))

  # "— all of them recent —" restates what an inlined list already shows, and
  # reads as ungrammatical for a single year ("**1** year ... — all of them
  # recent —"). Only worth saying once the list itself has been capped.
  hot_recent_clause <- if (isTRUE(stats$hot_all_recent) &&
                           length(stats$hot_years) > MAX_YEARS_INLINE)
    " — all of them recent —" else ""
  # Where a threshold is crossed in almost every year of the record, the count is
  # not a finding about unusual years — it is a description of the climate. Moscow
  # and Voronezh cross -5 °C in every single year; Santa Fe in 148 of 152. Saying
  # "78 of 78 years" invites the reader to weigh a number that cannot vary.
  cold_ubiquitous <- length(stats$cold_years) >= 0.9 * stats$clim_nyears
  cold_era_clause <- if (cold_ubiquitous) "" else
                     if (isTRUE(stats$cold_all_but_one)) ", all but one before 2000" else ""
  # Parenthetical year lists — omitted entirely (not left as an empty "()")
  # when a site's climate never crosses one of the two thresholds, e.g. Zurich
  # never touches +30 °C on the smoothed daily mean; capped past
  # MAX_YEARS_INLINE, see years_paren().
  hot_years_paren  <- years_paren(stats$hot_years)
  cold_years_paren <- if (cold_ubiquitous) " — every year in the record" else
                      years_paren(stats$cold_years)
  raw_both_sentence <- if (length(stats$raw_both_years) == 0)
    "(On the raw, unsmoothed daily mean, no year touches both extremes.)" else
  if (length(stats$raw_both_years) == 1)
    sprintf("(If the threshold is applied instead to the raw, unsmoothed daily mean, %s alone touches both extremes.)",
            stats$raw_both_years[1]) else
    sprintf("(If the threshold is applied instead to the raw, unsmoothed daily mean, %s each touch both extremes.)",
            join_and(stats$raw_both_years))

  # "The hot extremes and the cold extremes fall in different eras" is only a
  # real claim when BOTH sides actually cluster the way it describes (hot in
  # recent decades, cold in early ones) — checked via the same hot_all_recent/
  # cold_all_but_one flags the parenthetical clauses above use. It is also
  # self-contradicting whenever a year hit both extremes at once (that year's
  # hot and cold extremes did NOT fall in different eras), and empty on
  # whichever side never crosses its threshold at all (Zurich/Karlsruhe/Santa
  # Fe never hit +30 °C; Honolulu/Nouméa never drop below -5 °C).
  era_clause <- {
    has_both  <- length(stats$both_years) > 0
    hot_empty <- length(stats$hot_years)  == 0
    cold_empty <- length(stats$cold_years) == 0
    hot_clustered  <- isTRUE(stats$hot_all_recent)
    cold_clustered <- isTRUE(stats$cold_all_but_one)
    full_claim <- "The hot extremes and the cold extremes fall in different eras, which is itself a fingerprint of the warming trend."
    if (has_both) {
      if (hot_clustered && cold_clustered) {
        exc <- if (length(stats$both_years) == 1) sprintf("Except for %d", stats$both_years) else
                 sprintf("Except for %s", join_and(stats$both_years))
        sprintf("%s, the hot extremes and the cold extremes otherwise fall in different eras.", exc)
      } else ""
    } else if (hot_empty || cold_empty) {
      ""
    } else if (hot_clustered && cold_clustered) {
      full_claim
    } else if (hot_clustered) {
      "The hot extremes cluster entirely in recent decades; the cold threshold, crossed most years here regardless of era, is part of this climate's baseline rather than a fading relic."
    } else if (cold_clustered) {
      "The cold extremes cluster in the record's early decades; the hot extremes here are not concentrated the same way in recent years."
    } else ""
  }

  # Subtitle's "— plus {{CUR_YEAR}} so far" clause, and every other "so far" /
  # "still in progress" reference, only make sense when cur_year is actually
  # partial. Moscow's manual export's last year (2025) is already complete —
  # asserting it's "still in progress" or showing a hollow to-date marker for
  # it would be describing a chart element that R/01_plot.R never draws.
  cur_year_clause <- if (YEAR_COMPLETE) "" else sprintf(" — plus %d so far", stats$cur_year)
  so_far_suffix   <- if (YEAR_COMPLETE) "" else " so far"
  ytd_section_year <- if (YEAR_COMPLETE) as.character(stats$cur_year) else "This year"
  smooth_half <- (stats$smooth_window - 1) %/% 2
  smooth_half_word <- if (smooth_half == 1) "day" else "days"

  # The old wording asserted the part-year point sits "lower than its eventual
  # annual figure". That direction is wrong for most sites here: a Jan-to-August
  # window omits late autumn and winter, so in the northern hemisphere it runs
  # ABOVE the eventual annual mean, not below (Toulouse's Jan-Aug normal is
  # ~0.7 °C above its annual one). Which way it leans depends on the cutoff and
  # the hemisphere, so name the incomparability and claim no direction.
  partial_year_note <- if (!YEAR_COMPLETE)
    sprintf(paste0("A part-year mean cannot be compared with other years' full-year means. ",
                   "That is why %d appears on the long-view chart above only as a marked, hollow ",
                   "\"to date\" point — a part-year mean on an axis of full-year means — while its ",
                   "like-for-like standing is the chart here."),
            stats$cur_year) else
    sprintf(paste0("%d is %s's most recent complete year — this export has no %d data yet, so it ",
                   "is plotted as a solid point like every other complete year, not as a hollow ",
                   "\"to date\" marker."),
            stats$cur_year, site$reference_station, stats$cur_year + 1)

  # Moscow's window IS the whole calendar year, so calling it "the warmest
  # Jan 1 – Dec 31" (and, elsewhere, "year-to-date") describes a full year in the
  # vocabulary of a partial one.
  FULL_WINDOW <- isTRUE(y$window_days >= 350)
  window_noun <- if (FULL_WINDOW) "year" else y$window
  # Name the baseline span instead of saying "the long-term normal". The normal is
  # the mean of this site's whole qualifying record, so a longer record yields a
  # cooler baseline and a bigger anomaly: Zurich's "+3.5 °C above normal" is
  # against an 1882-2025 mean, Karlsruhe's "+2.4" against 1876-2025. Unlabelled,
  # the two invite a comparison the numbers do not support.
  norm_span <- sprintf("%d–%d", y$norm_yr0, y$norm_yr1)

  ytd_sentence <- if (!isTRUE(y$has_ytd)) {
    sprintf(paste0("%s's %d data covers too little of the year so far for a fair comparison ",
                   "against every prior year's same window (fewer than %d days). ",
                   "Check back once more of the year is recorded."),
            site$reference_station, stats$cur_year, y$min_days)
  } else if (isTRUE(y$is_record)) {
    lead      <- bold(sprintf("%d is the warmest %s in %d years", stats$cur_year, window_noun, y$n_years))
    cur_val   <- bold(sprintf("%s °C", fmt(y$cur, 1)))
    anom_val  <- bold(sprintf("+%s °C above the %s mean", fmt(y$cur_anom, 1), norm_span))
    sprintf(paste0("Measured like-for-like, %s at %s: %s — +%s °C above the previous record ",
                   "(%d, %s °C) and %s (%s °C)."),
            lead, site$reference_station, cur_val, fmt(y$cur - y$rec_val, 1),
            y$rec_year, fmt(y$rec_val, 1), anom_val, fmt(y$normal, 1))
  } else {
    rank_val <- bold(sprintf("#%d of %d", y$rank, y$n_years))
    sprintf(paste0("Measured like-for-like over %s, %d ranks %s at ",
                   "%s (%s °C). The warmest such window on record remains ",
                   "%d (%s °C)."),
            y$window, stats$cur_year, rank_val, site$reference_station,
            fmt(y$cur, 1), y$rec_year, fmt(y$rec_val, 1))
  }

  # Row label and fairness sentence, likewise conditioned on the window being a
  # full year rather than a part of one.
  ytd_row_label <- if (FULL_WINDOW) sprintf("%d, full calendar year", stats$cur_year)
                   else sprintf("%d year-to-date (%s)", stats$cur_year, y$window)
  ytd_fairness_sentence <- if (FULL_WINDOW)
    "Every bar covers a full calendar year, so the years compare directly." else
    "Holding the part-of-year identical is what makes one year comparable with another."

  # "the largest bar"/"the tallest of all" is only true when the current year
  # is actually the record — for a mid-pack year (Honolulu #18/84, Nouméa
  # #5/76, Voronezh #55/84, and even Karlsruhe's near-miss #2/150) it was
  # simply wrong every time it wasn't checked.
  ytd_alt_suffix    <- if (isTRUE(y$has_ytd) && isTRUE(y$is_record)) "the largest bar" else "highlighted"
  ytd_tallest_clause <- if (isTRUE(y$has_ytd) && isTRUE(y$is_record))
    sprintf(" — and %d is the tallest of all", stats$cur_year) else ""

  early_span <- sprintf("%d–%d", stats$yr0, stats$yr0 + 9)

  # A station whose nights COOL while its days WARM is showing a widening
  # day-night range. That is the opposite of the greenhouse signature (which
  # narrows it, minima rising fastest) and a standard symptom of station-history
  # artifacts — a site move, a change in observation time — in a record that has
  # not been homogenised. GHCN-Daily is raw. Computed, so it fires only where the
  # signs actually diverge: at Santa Fe they do, which is the real reason its
  # headline rate is the lowest of any city here.
  dtr_change <- stats$dtr_recent - stats$dtr_early
  homogeneity_note <- if (isTRUE(stats$slope_dec_tn < 0 && stats$slope_dec_tx > 0))
    sprintf(paste0("One caveat specific to this station: its daily minima have %s (%s °C/decade) ",
                   "while its maxima rose (+%s °C/decade), widening the average gap between day and ",
                   "night by %s °C over the record. Greenhouse warming narrows that gap, minima ",
                   "rising fastest; a widening gap usually means something about the station changed ",
                   "— a move, or a shift in reading time — and these are raw observations, not a ",
                   "homogenised series. Treat this city's headline rate with more caution than the ",
                   "others here, and see the note below on which station this series is."),
            italic("fallen"), fmt(stats$slope_dec_tn), fmt(stats$slope_dec_tx),
            fmt(dtr_change, 1)) else ""

  # The local-station comparison paragraph: only meaningful where a local
  # station exists AND actually carries a temperature record. Karlsruhe has a
  # local station but no local temperature (its local tier is rain-only, see
  # R/sites/karlsruhe.R); Moscow/Voronezh have no local station at all
  # (manually exported from AISORI-M with a single WMO index). The relation
  # clause ("which is the station on the edge of...") is stated once, in the
  # figure caption just above this paragraph (FIG1_LOCAL_CAPTION) — repeating
  # it here added nothing.
  # "the local station sits almost exactly on the regional mean" was a fixed
  # claim, and it is false wherever the two slopes are not actually close:
  # Albuquerque's local site runs +0.82 °C/decade against the airport's +0.31
  # over the same years, a factor of 2.6. Branch on the measured gap instead —
  # the same discipline extreme_direction() already applies to day counts.
  local_gap <- if (HAS_LOCAL && isTRUE(site$local_has_temp))
    abs(stats$slope_dec_local - stats$slope_dec_ref_localwin) else NA_real_
  local_agreement <- if (isTRUE(local_gap <= 0.05))
    sprintf("and over these years the two stations agree to within %s °C/decade", fmt(local_gap))
  else if (isTRUE(local_gap <= 0.20))
    sprintf("and the two differ by %s °C/decade over these years — the same trend, read off a different site",
            fmt(local_gap))
  else
    sprintf(paste0("and the gap between the two — %s °C/decade — is wide enough that this short ",
                   "local window should not be read as the area's trend"), fmt(local_gap))

  local_temp_paragraph <- if (!HAS_LOCAL)
    sprintf(paste0("This site has no second station — %s alone provides the temperature ",
                   "trend and the daily climatology."),
            site$reference_station) else
  if (site$local_has_temp)
    sprintf(paste0("The local %s station only covers %d→%d. Its slope over ",
                   "that shorter, more recent window is steeper (+%s °C/decade), and so is ",
                   "%s’s over the same years (+%s °C/decade): recent decades warm faster, %s."),
            site$local_station, stats$local_yr0, stats$local_yr1,
            fmt(stats$slope_dec_local), site$reference_station,
            fmt(stats$slope_dec_ref_localwin), local_agreement) else
    sprintf(paste0("%s carries no temperature record; %s alone provides the temperature trend ",
                   "for this area. The local comparison here uses rainfall instead — see below."),
            site$local_station, site$reference_station)

  # Same overclaim as local_agreement above, in a second string: "tracks ... almost
  # exactly" fired for every site regardless of whether it does. Only assert the
  # tracking where the two slopes actually agree.
  fig1_local_caption <- if (HAS_LOCAL && site$local_has_temp)
    sprintf(" The green series (%s) %s.%s",
            site$local_station, site$local_relation_clause,
            if (isTRUE(local_gap <= 0.05))
              sprintf(" It tracks the long %s reference mean closely.", site$reference_station)
            else "") else ""

  local_note_header <- bold(if (HAS_LOCAL) sprintf("Why %s?", site$local_station) else
                             "Why only one station?")

  rain_stations_alt <- if (HAS_LOCAL) sprintf("%s and %s", site$reference_station, site$local_station) else
                        site$reference_station

  stations_line <- if (HAS_LOCAL)
    sprintf("Stations: %s (%s) and %s (%s).",
            site$local_station, station_id(site, site$local_station),
            site$reference_station, station_id(site, site$reference_station)) else
    sprintf("Station: %s (%s).", site$reference_station, station_id(site, site$reference_station))

  ref_rec <- stats$records[[which(vapply(stats$records, function(r) r$station, character(1)) ==
                                   site$reference_station)]]
  # "Heat more recent than cold" was a fixed claim that happened to hold for the
  # first sites checked but is not universal — Santa Fe's record cold (2011-02-03,
  # the Southwest's February 2011 cold wave) postdates its record heat (1994-06-26).
  # Check which date is actually later rather than assert it.
  # State the gap as a number rather than trailing off into "the same warming
  # signature seen throughout this report" — that clause described the document,
  # not the climate, and repeated verbatim in all ten chapters.
  hot_is_recent <- as.Date(ref_rec$hot$date) > as.Date(ref_rec$cold$date)
  yrs_apart <- abs(as.integer(format(as.Date(ref_rec$hot$date), "%Y")) -
                   as.integer(format(as.Date(ref_rec$cold$date), "%Y")))
  closing_record_note <- if (hot_is_recent)
    sprintf("At %s, the all-time heat (%s) postdates the all-time cold (%s) by %d years.",
            site$reference_station, ref_rec$hot$date, ref_rec$cold$date, yrs_apart) else
    sprintf(paste0("At %s the all-time cold (%s) postdates the all-time heat (%s) by %d years: ",
                   "a single record day is noisy, and the mean trend above is the more reliable ",
                   "measure."),
            site$reference_station, ref_rec$cold$date, ref_rec$hot$date, yrs_apart)

  # Extreme-day header/closing: computed direction words, not fixed rhetoric —
  # see extreme_direction()'s comment for why "halved"/"doubled" broke.
  frost_dir <- extreme_direction(ex$frost_early, ex$frost_recent)
  hot_dir   <- extreme_direction(ex$hot_early, ex$hot_recent)
  extremes_header <- sprintf("Frost days %s, hot days %s", frost_dir, hot_dir)
  # A fixed 30 °C line means different things in ten climates. Where the
  # threshold sits out in the tail (Castanet p86, Santa Fe p84, Albuquerque p70,
  # ~6-7% of recent days within 1 °C of it) the count is a real tail measure.
  # Where it cuts through the bulk it is not: at Honolulu 29% of recent days fall
  # within 1 °C of 30 °C, so a mean-maximum shift of just +1.7 °C shows up as a
  # 4x jump in the count (42 -> 175 days). Reporting that ratio without saying so
  # overstates the tropical sites, so say it — and only where it applies.
  hot_thr_crowded <- isTRUE(ex$hot_thr_near > 0.15)
  hot_thr_caveat <- if (hot_thr_crowded)
    sprintf(paste0(" Read the hot-day jump with care here: %.0f%% of recent days come within 1 °C ",
                   "of the %d °C line, so the count amplifies what is really a %+.1f °C shift in the ",
                   "average daily maximum."),
            100 * ex$hot_thr_near, ex$hot_thr, ex$tx_shift) else ""

  # The "frost retreating as heat advances" line repeated in seven chapters and
  # said nothing the heading and the table above it had not already said.
  extremes_closing <- paste0(
    if (frost_dir == "down" && hot_dir == "up") "" else
    if (frost_dir == "at zero" && hot_dir == "up")
      " There was never a frost season here to retreat; the change shows up entirely on the hot side of the ledger." else
    if (frost_dir == "up" && hot_dir == "up")
      " Both counts have risen here — a reminder that year-to-year extreme-day counts are noisy even where the underlying mean trend, shown above, is unambiguous." else
      " Extreme-day counts shift year to year; the underlying mean trend, shown above, is the more reliable signal.",
    hot_thr_caveat)

  # Rainfall trend text must branch on rn$significant: this was previously
  # hardcoded to "no statistically significant trend" everywhere, which is
  # wrong wherever it isn't true (e.g. Karlsruhe/Rheinstetten: -11 mm/decade,
  # p = 0.00 — actually significant).
  rain_sig_clause <- if (isTRUE(rn$significant))
    bold(sprintf("a statistically significant trend (%+.0f mm/decade, p = %s)", rn$slope_dec, fmt(rn$p, 2))) else
    bold("no statistically significant trend")

  rain_flat_clause <- if (isTRUE(rn$significant))
    sprintf("is measurable and statistically significant (p = %s)", fmt(rn$p, 2)) else
    sprintf("is flat and not significant (p = %s)", fmt(rn$p, 2))

  # "Unlike most of the sites in this series" was a fixed claim that went
  # stale the moment a majority of sites had a significant trend (5 of 8, once
  # Karlsruhe/Santa Fe/Honolulu/Moscow/Voronezh were added) — dropped rather
  # than replaced with a recomputed count, since that count would just go
  # stale again the next time a site is added.
  # Both arms restated numbers the lead sentence and the figure caption had
  # already given (the significant arm printed the same slope and p-value a third
  # time), and the flat arm closed on "A dataset that manufactured trends would
  # have produced one here too; this one does not" — a rebuttal to an unstated
  # skeptic, and the kind of epigram the house style rules out. State the finding.
  rain_closing_paragraph <- if (isTRUE(rn$significant))
    sprintf(paste0("Rainfall here is not flat: the long run tilts %s. The tilt is small against the ",
                   "year-to-year spread above, which is why it is easy to miss in any single decade."),
            if (rn$slope_dec < 0) "drier" else "wetter") else
    sprintf(paste0("The same daily records that carry a strong warming signal carry %s comparable ",
                   "signal in how much it rains: annual totals swing widely from year to year around ",
                   "a flat long-run mean."),
            italic("no"))

  # The monthly-rainfall-climatology caption's closing clause asserted "no
  # annual trend emerges" unconditionally — wrong for the 5 sites whose annual
  # trend (above, RAIN_SIG_CLAUSE) IS significant; this is about a different
  # chart (monthly shape, not the annual series) so it needs its own branch.
  rain_monthly_closing <- if (isTRUE(rn$significant))
    "but the spread between years is why that slow trend is easy to miss from the monthly shape alone." else
    "but the spread between years dwarfs the seasonal cycle, which is exactly why no annual trend emerges."

  c(
    YR0 = stats$yr0, YR1 = stats$yr1, NYEARS = stats$yr1 - stats$yr0,
    SLOPE_DEC = fmt(stats$slope_dec_ref),
    RISE = fmt(stats$rise_ref, 1),
    MEAN_RECENT = fmt(stats$mean_recent, 1), MEAN_EARLY = fmt(stats$mean_early, 1),
    EARLY_SPAN = early_span,
    N_STATION_YEARS = stats$n_station_years,
    CLIM_YR0 = stats$clim_yr0, CLIM_YR1 = stats$clim_yr1, CLIM_NYEARS = stats$clim_nyears,
    HOMOGENEITY_NOTE = homogeneity_note,
    YTD_ROW_LABEL = ytd_row_label, YTD_FAIRNESS_SENTENCE = ytd_fairness_sentence,
    CUR_YEAR = stats$cur_year,
    CUR_YEAR_CLAUSE = cur_year_clause, SO_FAR_SUFFIX = so_far_suffix,
    YTD_SECTION_YEAR = ytd_section_year, PARTIAL_YEAR_NOTE = partial_year_note,
    SMOOTH_HALF_WORD = smooth_half_word,
    YTD_ALT_SUFFIX = ytd_alt_suffix, YTD_TALLEST_CLAUSE = ytd_tallest_clause,
    HOT_THR = stats$hot_thr, COLD_THR = stats$cold_thr,
    N_HOT = length(stats$hot_years), N_COLD = length(stats$cold_years),
    N_HOT_WORD = if (length(stats$hot_years) == 1) "year" else "years",
    N_COLD_WORD = if (length(stats$cold_years) == 1) "year" else "years",
    SMOOTH_WINDOW = stats$smooth_window, SMOOTH_HALF = smooth_half,
    HOT_YEARS_PAREN = hot_years_paren, COLD_YEARS_PAREN = cold_years_paren,
    BOTH_SENTENCE = both_sentence, ERA_CLAUSE = era_clause,
    HOT_RECENT_CLAUSE = hot_recent_clause, COLD_ERA_CLAUSE = cold_era_clause,
    RAW_BOTH_SENTENCE = raw_both_sentence,
    YTD_WINDOW = y$window, YTD_NORMAL = fmt(y$normal, 1), YTD_SENTENCE = ytd_sentence,
    YTD_NORM_SPAN = norm_span,
    YTD_NYEARS_PRIOR = y$n_years - 1,
    YTD_STANDING = bold(ytd_standing_text(y)),
    EXTREMES_HEADER = extremes_header, EXTREMES_CLOSING = extremes_closing,
    EXT_SPAN0 = sprintf("%d–%d", ex$yr0, ex$yr0 + 9),
    EXT_SPAN1 = sprintf("%d–%d", ex$yr1 - 9, ex$yr1),
    HOT_TX = ex$hot_thr, VHOT_TX = ex$vhot_thr, TROP_TX = ex$trop_thr,
    FROST_EARLY = ex$frost_early, FROST_RECENT = ex$frost_recent,
    HOT_EARLY = ex$hot_early, HOT_RECENT = ex$hot_recent,
    VHOT_EARLY = ex$vhot_early, VHOT_RECENT = ex$vhot_recent,
    TROP_EARLY = ex$trop_early, TROP_RECENT = ex$trop_recent,
    RAIN_YR0 = rn$yr0, RAIN_YR1 = rn$yr1, RAIN_NYEARS = rn$n_years, RAIN_MEAN = rn$mean_ref,
    RAIN_SLOPE = sprintf("%+.0f", rn$slope_dec),
    RAIN_SIG_CLAUSE = rain_sig_clause, RAIN_FLAT_CLAUSE = rain_flat_clause,
    RAIN_CLOSING_PARAGRAPH = rain_closing_paragraph, RAIN_MONTHLY_CLOSING = rain_monthly_closing,
    WETTEST_YEAR = rn$wettest_year, WETTEST_MM = rn$wettest_mm,
    DRIEST_YEAR = rn$driest_year, DRIEST_MM = rn$driest_mm,
    WET_MONTH = rn$wet_month, WET_MONTH_MM = rn$wet_month_mm,
    DRY_MONTH = rn$dry_month, DRY_MONTH_MM = rn$dry_month_mm,
    MIN_DAYS = MIN_DAYS, MIN_YTD_DAYS = y$min_days,
    # site facts
    # SITE_KEY lives here, not in a per-stage local fill, because BOTH the HTML
    # report and the README chapter print the reproduce-me command and it must
    # name this site: `make all` alone silently rebuilds castanet (the Makefile's
    # SITE default), whichever city's report you happen to be reading.
    SITE_KEY = site$key,
    CITY = site$city, REGION = site$region, COUNTRY = site$country,
    REF_STATION = site$reference_station,
    SOURCE_NAME = site$citation$source_name,
    DATASET_LABEL = site$citation$dataset_label,
    CITATION_URL = site$citation$url,
    LICENCE = site$citation$licence,
    SINCE_PHRASE = since_phrase(stats$yr0),
    LOCAL_RATIONALE = site$local_rationale,
    LOCAL_NOTE_HEADER = local_note_header,
    RAIN_STATIONS_ALT = rain_stations_alt,
    STATIONS_LINE = stations_line,
    LOCAL_TEMP_PARAGRAPH = local_temp_paragraph,
    FIG1_LOCAL_CAPTION = fig1_local_caption,
    CLOSING_RECORD_NOTE = closing_record_note
  )
}
