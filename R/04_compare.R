#!/usr/bin/env Rscript
# =============================================================================
# Stage 04 — cross-site comparison (run after every site's stage 01)
# Reads every site's trend_stats.rds and SITE list, and produces:
#   * outputs/compare/figures/warming_rate.png   — ranked bar chart
#   * README.md, spliced between <!-- BEGIN COMPARE --> / <!-- END COMPARE -->
#
# Unlike stages 00-03 this is NOT parameterized by SITE — it always covers
# every site in SITE_ORDER below, hand-maintained (not discovered from
# R/sites/*.R) so a new site is a deliberate addition here, not a silent
# extra row.
#
# SITE_ORDER is presentational only: both the chart and the table re-sort by
# warming rate. It mirrors the chapter order in README.md — Europe, then North
# America, then the Pacific, west to east within each — so the registry reads
# the same way the page does. Do NOT sort the chapters by warming rate instead:
# the chart re-ranks itself on every data refresh while the chapter order is
# hand-maintained, so the two would drift apart silently.
#
#   Rscript R/04_compare.R
# =============================================================================

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(scales)
  library(ragg)
})

source("R/lib/common.R")
source("R/lib/narrative.R")   # shares ytd_standing_text() with every per-site chapter

SITE_ORDER <- c("castanet", "paris", "lyon", "karlsruhe", "zurich", "moscow", "voronezh",
                "irvine", "albuquerque", "santafe", "honolulu", "noumea")

load_site <- function(key) {
  env <- new.env()
  sys.source(sprintf("R/sites/%s.R", key), envir = env)
  site <- env$SITE
  stats_path <- file.path(site$paths$processed, "trend_stats.rds")
  if (!file.exists(stats_path))
    stop("Missing ", stats_path, " — run stage 01 first (SITE=", key, " make plots).")
  stats <- readRDS(stats_path)
  y <- stats$ytd
  # "Data current through" built from the structured cutoff fields (not
  # regex-parsed out of the display string `window`) so a future wording
  # change to that string can't silently break this.
  data.table(
    site_key = key, city = site$city, country = site$country,
    yr0 = stats$yr0, yr1 = stats$yr1,
    # nyears is the slope multiplier (yr1 - yr0), which is what "total rise over
    # N years" needs. span_years is the INCLUSIVE count, which is what belongs
    # next to a count of complete years — otherwise the cell reads "76 yr, 77
    # complete", which looks like an error.
    nyears = stats$yr1 - stats$yr0,
    span_years = stats$yr1 - stats$yr0 + 1L,
    n_complete = stats$n_years_ref,
    slope_dec = stats$slope_dec_ref,
    slope_dec_common = stats$slope_dec_ref_common,
    cur_year = stats$cur_year,
    current_through = sprintf("%s %d, %d", month.abb[y$cutoff_month], y$cutoff_day, stats$cur_year),
    window = y$window, window_days = y$window_days,
    ytd_rank = y$rank, ytd_n = y$n_years, is_record = isTRUE(y$is_record),
    has_ytd = isTRUE(y$has_ytd),
    manual_source = identical(site$source, "meteoru"),
    ref_station = site$reference_station,
    latitude = stats$latitude, elevation_m = stats$elevation_m,
    koppen = stats$koppen, koppen_label = stats$koppen_label,
    koppen_near = stats$koppen_borderline,
    koppen_yr0 = stats$koppen_yr0, koppen_yr1 = stats$koppen_yr1
  )
}

cmp <- rbindlist(lapply(SITE_ORDER, load_site))
cmp[, site_key := factor(site_key, levels = SITE_ORDER)]

# The common-window rate is only honest if every site actually covers that
# window. If a future site starts later than COMMON_YR0, bump the constant in
# R/lib/common.R rather than comparing a site against years it does not have.
if (any(cmp$yr0 > COMMON_YR0))
  stop("These sites start after COMMON_YR0 (", COMMON_YR0, "): ",
       paste(cmp[yr0 > COMMON_YR0]$city, collapse = ", "),
       ". Bump COMMON_YR0 in R/lib/common.R.")

# SITE_ORDER and the physical chapter order in README.md are both hand-maintained,
# and nothing forced them to agree — so a city inserted in one and appended in the
# other would drift silently, exactly the failure this comment warns about above.
# Check it instead of trusting it.
readme_order <- sub(".*BEGIN REPORT:([a-z]+).*", "\\1",
                    grep("<!-- BEGIN REPORT:[a-z]+ -->", readLines("README.md", warn = FALSE),
                         value = TRUE))
if (!identical(readme_order, SITE_ORDER))
  stop("SITE_ORDER disagrees with the chapter order in README.md.\n",
       "  SITE_ORDER: ", paste(SITE_ORDER, collapse = ", "), "\n",
       "  README.md:  ", paste(readme_order, collapse = ", "), "\n",
       "Both are hand-maintained and must match — see the ordering rule under ",
       "Project layout in README.md.")

N_SITES     <- nrow(cmp)
N_AUTOMATED <- sum(!cmp$manual_source)
# Spelled out, since these appear in prose. Hardcoding "ten" meant every new
# city silently made the page lie.
num_word <- function(n) c("one","two","three","four","five","six","seven","eight",
                          "nine","ten","eleven","twelve")[n]
title_case <- function(s) paste0(toupper(substring(s, 1, 1)), substring(s, 2))

# GitHub slug for a chapter heading, so the comparison table can link to each
# city's section. Built from the SAME heading text R/03_readme.R emits, so the
# two cannot drift apart silently.
# NOTE: GitHub KEEPS Unicode letters in heading slugs, so Nouméa's anchor is
# ...-nouméa, not ...-noumea. Only spaces (-> hyphens) and punctuation are
# transformed; do not "sanitize" accented characters away or the link 404s.
chapter_anchor <- function(city)
  paste0("#a-warming-climate-seen-from-",
         gsub("[.,()'\"!?:;/]", "", gsub(" ", "-", tolower(city))))

dir.create("outputs/compare/figures", recursive = TRUE, showWarnings = FALSE)

# ---- FIGURE — warming rate, ranked ------------------------------------------
# Fastest at TOP: ggplot2 places factor level 1 at the BOTTOM of a discrete
# y-axis, so the level order must be the REVERSE of display order, or the
# chart silently renders upside-down from what "ranked fastest to slowest"
# (in the caption below and in the table) claims.
plot_ord <- cmp[order(-slope_dec)]
cmp[, city_f := factor(city, levels = rev(plot_ord$city))]

# The second mark is the point of the chart. Ranking cities by a rate computed
# over each one's OWN record invites reading it as a speed ranking, when much of
# the middle of the order is really record length: on the shared 1951-> window
# Zurich and Karlsruhe each gain three places and Honolulu and Nouméa each lose
# three. A hollow diamond per city carries the like-for-like rate beside the raw
# bar, so the caveat is a number the reader can check rather than a sentence
# asking to be believed. One muted fill for every bar — position plus the bold
# city label already identify each row, so a hue per city would add nothing.
BAR_FILL   <- "#5B7FA6"
POINT_COL  <- "#B9770E"
x_max <- max(c(cmp$slope_dec, cmp$slope_dec_common), na.rm = TRUE)

p <- ggplot(cmp, aes(y = city_f)) +
  geom_col(aes(x = slope_dec, fill = "Own full record"), width = 0.62) +
  geom_point(aes(x = slope_dec_common, colour = "Shared window, 1951 onward"),
             shape = 18, size = 3.4) +
  # Value labels sit in a fixed column to the right of every mark, not at each
  # bar's end: at the top of the order the bar end and the diamond nearly
  # coincide, so an end-anchored label printed straight through the diamond.
  geom_text(aes(x = x_max * 1.08, label = sprintf("+%.2f", slope_dec)),
            hjust = 0, size = 3.5, colour = "#3D4A54") +
  scale_fill_manual(values = c("Own full record" = BAR_FILL), name = NULL) +
  scale_colour_manual(values = c("Shared window, 1951 onward" = POINT_COL), name = NULL) +
  scale_x_continuous(limits = c(0, x_max * 1.20), expand = expansion(mult = c(0, 0)),
                     labels = function(x) sprintf("+%.1f", x)) +
  guides(fill = guide_legend(order = 1), colour = guide_legend(order = 2)) +
  labs(
    title = paste0(title_case(num_word(N_SITES)),
                   " cities, all warming — just not at the same speed"),
    subtitle = paste0("Annual-mean warming rate. Bars use each city's own complete-year record; ",
                      "diamonds use the ", COMMON_YR0, "-onward window every city shares."),
    x = "°C per decade", y = NULL,
    caption = paste0(
      "Source: each city's own report, this repository. Ranked by the raw rate, which is not ",
      "adjusted for record length or baseline era — hence the diamonds.\n",
      "Slope = linear regression on complete-year annual means (≥ ", MIN_DAYS, " valid days/year); ",
      "bars match the “Warming rate” headline number in each city's own section below."
    )
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title    = element_text(face = "bold", size = 17, colour = "#1A2530"),
    plot.subtitle = element_text(size = 11, colour = "#566573", margin = margin(b = 12)),
    plot.caption  = element_text(size = 8, colour = "#7F8C8D", hjust = 0,
                                 margin = margin(t = 14), lineheight = 1.15),
    plot.caption.position = "plot", plot.title.position = "plot",
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_blank(),
    panel.grid.major.x = element_line(colour = "#ECEFF1", linewidth = 0.4),
    axis.text.y = element_text(colour = "#1A2530", face = "bold", size = 12),
    axis.text.x = element_text(colour = "#566573"),
    legend.position = "bottom", legend.margin = margin(t = 2),
    legend.text = element_text(size = 10, colour = "#3D4A54"),
    plot.margin = margin(18, 26, 12, 18),
    plot.background = element_rect(fill = "white", colour = NA)
  )

FIG_PATH <- "outputs/compare/figures/warming_rate.png"
agg_png(FIG_PATH, width = 2400, height = 1300, res = 200, background = "white")
print(p); invisible(dev.off())
message("Wrote ", FIG_PATH)

# GitHub proxies README images and caches them by URL. Because this file's path
# never changes, adding a city can leave the OLD chart on display next to text
# that already says "eleven" — observed twice, and confusing enough both times to
# look like a failed push when the committed bytes were in fact correct. Append a
# short content hash so the URL changes exactly when the image does, which gives
# the proxy a new key to fetch.
#
# Applied only to this figure, deliberately. The per-site climatology PNGs are
# NOT byte-stable across runs (ggrepel places 100+ year labels without a stable
# tie-break), so hashing those would make README.md churn on every rebuild and
# destroy its idempotency. This chart has no repelled labels and re-renders
# identically, verified by building it twice and comparing checksums.
FIG_REF <- sprintf("%s?v=%s", FIG_PATH,
                   substr(unname(tools::md5sum(FIG_PATH)), 1, 8))

# ---- TABLE -------------------------------------------------------------------
# A standing is NOT the same claim from row to row, and the windows are further
# apart than "all the automated sites rank the same year" once suggested: they
# run from Voronezh's 59 midwinter days through Irvine's five months to Nouméa's
# eight. A Jan-May mean and a Jan-Aug mean are different statistics, and
# standardising them flips three of the four "record" badges among the automated
# sites. So the window gets its own column rather than a parenthesis, and the
# prose below says plainly that a rank is comparable within a city, not across.
row_md <- function(r) {
  y <- list(has_ytd = r$has_ytd, is_record = r$is_record, rank = r$ytd_rank, n_years = r$ytd_n)
  standing <- if (!r$has_ytd) "too early to rank" else ytd_standing_text(y)
  win <- if (r$window_days >= 350) sprintf("%d, full year", r$cur_year) else
           sprintf("%d, %s · %d d", r$cur_year, r$window, r$window_days)
  freshness <- if (r$manual_source) sprintf("%s †", r$current_through) else r$current_through
  common <- if (is.na(r$slope_dec_common)) "—" else sprintf("%+.2f", r$slope_dec_common)
  sprintf("| [%s](%s) | %s | %d→%d (%d yr, %d complete) | **%+.2f** | %s | %s | %s | %s |",
          r$city, chapter_anchor(r$city), r$country, r$yr0, r$yr1, r$span_years, r$n_complete,
          r$slope_dec, common, standing, win, freshness)
}
table_rows <- vapply(seq_len(nrow(plot_ord)), function(i) row_md(plot_ord[i]), character(1))

# ---- CONTEXT TABLE — what kind of places these are ---------------------------
# Kept separate from the results table above rather than bolted onto it: that one
# answers "how fast", this one answers "where and what kind of place", and an
# eleven-column table answers neither legibly. Ordered north to south, which is
# the one ordering a reader can check against the numbers in front of them.
geo_ord <- cmp[order(-latitude)]
hemi <- function(lat) sprintf("%.1f°%s", abs(lat), if (lat >= 0) "N" else "S")
geo_rows <- vapply(seq_len(nrow(geo_ord)), function(i) {
  r <- geo_ord[i]
  clim <- if (is.na(r$koppen)) "—" else
    sprintf("**%s** — %s%s", r$koppen, r$koppen_label,
            if (!is.na(r$koppen_near)) " ‡" else "")
  sprintf("| [%s](%s) | %s | %s | %s m | %s |",
          r$city, chapter_anchor(r$city), r$country, hemi(r$latitude),
          format(round(r$elevation_m), big.mark = ","), clim)
}, character(1))
# Only mention the boundary footnote if some site actually sits on one.
near_any <- cmp[!is.na(koppen_near)]
clim_note <- if (nrow(near_any))
  sprintf(paste0("\n‡ Within one baseline period of a class boundary, so reference works using a ",
                 "different 30-year normal may place these differently: %s. Köppen classes are hard ",
                 "thresholds, not gradients.\n"),
          paste(sprintf("%s (%s)", near_any$city, near_any$koppen_near), collapse = "; ")) else ""

# Named exemplars for the record-length caveat, picked from the data rather than
# hardcoded — "a century longer" was wrong (the widest gap is 77 years) and the
# two cities named drifted out of date as sites were added.
longest  <- plot_ord[order(-nyears)][1]
shortest <- plot_ord[order(nyears)][1]

# The New Mexico pair. Santa Fe and Albuquerque are ~90 km apart yet differ by
# more than a factor of two, which a reader can spot unaided; record length does
# not explain it (Santa Fe over the shared window is still far below), so the
# page says what does. Guarded so the paragraph simply disappears if either city
# leaves SITE_ORDER.
nm_note <- if (all(c("santafe", "albuquerque") %in% cmp$site_key)) {
  sf <- cmp[site_key == "santafe"]; ab <- cmp[site_key == "albuquerque"]
  sprintf(paste0(
    "\nThe two New Mexico rows deserve a note, because they look like a contradiction. Santa Fe and ",
    "Albuquerque sit about 90 km apart in the same high-desert climate, yet Santa Fe warms at ",
    "%+.2f °C/decade against Albuquerque's %+.2f. Record length is not the explanation — over the ",
    "shared %d-onward window they are still %+.2f and %+.2f. The difference is in the stations: Santa ",
    "Fe's daily minima have *fallen* while its maxima rose, widening the gap between day and night, ",
    "which is the opposite of the greenhouse signature and a known symptom of station history (a site ",
    "move, a change in reading time) in a record that has not been homogenised. GHCN-Daily is raw. ",
    "Read the slowest bar on this chart as a measurement result, not as evidence that Santa Fe is ",
    "barely warming; its own airport station, and its neighbour here, both give roughly +0.2. See ",
    "Santa Fe's chapter for the numbers.\n"),
    sf$slope_dec, ab$slope_dec, COMMON_YR0, sf$slope_dec_common, ab$slope_dec_common)
} else ""

block <- paste0(
'<!-- BEGIN COMPARE -->

## All ', num_word(N_SITES), ' cities, side by side

Every chapter below uses the same variables, the same completeness rule (≥ ', MIN_DAYS, ' valid
days/year) and the same trend method (least-squares on annual means). The numbers here are those
same headline figures gathered in one place, not recomputed. Two rates are given per city: the raw
one over its own record, and one over ', COMMON_YR0, '–', max(cmp$yr1), ', the longest window every
city shares. Where they disagree, the raw ranking is partly reporting record length.

![Warming rate compared across all ', num_word(N_SITES), ' cities, ranked fastest to slowest, with a shared-window rate alongside](', FIG_REF, ')

<sub>Ranked by the raw rate. ', longest$city, '’s record runs ', longest$nyears - shortest$nyears,
' years longer than ', shortest$city, '’s, so two similar-looking rates can rest on very different
amounts of evidence — the record span and the count of complete years are in the table below.</sub>

| City | Country | Record | °C/decade | ', COMMON_YR0, '→ | Standing | Window ranked | Data current through |
|---|---|---:|---:|---:|---|---|---|
', paste(table_rows, collapse = "\n"), '

† Moscow and Voronezh are manually exported from Roshydromet’s AISORI-M (login-gated, no automated
refresh), so their "current through" date lags the other ', num_word(N_AUTOMATED), ' sites’ automated feeds by
however long it has been since the last hand export. See each city’s own "Why only one station?"
note below.

Each row names the window its standing is measured over, because the rows do not all make the same
claim. The windows run from Voronezh’s 59 midwinter days through Irvine’s five months to the eight
months most sites reach, and Moscow’s row ranks a complete, already-finished ', cmp[site_key == "moscow"]$cur_year, '.
A rank is comparable **within** a city — the same calendar window against that city’s own history —
but not across cities. Standardising every site to the shortest window they share reorders the
standings substantially, and several cities holding a "record" badge here do not hold one there:
a January-to-May mean and a January-to-August mean are different statistics. A "#55 of 84" over two
months of winter is not the same kind of statement as an eight-month "#5 of 76".
', nm_note, '
### What kind of places these are

Warming rates read differently once you know whether a city sits at sea level in the tropics
or on a high desert plateau. North to south:

| City | Country | Latitude | Elevation | Climate (Köppen, last ', KOPPEN_YEARS, ' complete years) |
|---|---|---:|---:|---|
', paste(geo_rows, collapse = "\n"), '

Latitude and elevation are the **reference station\'s**, not the city centre\'s: they are where the
measurements were actually taken, which is the honest thing to print beside a rate derived from
them. Sources are each provider\'s own station metadata, except Moscow and Voronezh — their
AISORI-M export carries no coordinates, so those two come from the WMO station registry.

The climate class is computed from each station\'s own monthly normals rather than looked up, which
has two consequences worth stating. It describes **the station**, not the city: Honolulu Airport,
on the dry leeward side of Oʻahu, classifies drier than windward Honolulu would. And the ',
KOPPEN_YEARS, ' years are each station\'s most recent ', KOPPEN_YEARS, ' *complete* ones, so the
exact span differs by a few years where a record has gaps.
', clim_note, '
## How every chapter is built

The comparison above is only meaningful because every city is measured the same way. That
method is stated here once, rather than repeated in all ', num_word(N_SITES), ' chapters; each chapter adds only
its own source, stations and rebuild command.

- **Variables.** Minimum = `TN`, maximum = `TX`, mean = `(TN+TX)/2`, in °C;
  rainfall = `RR` (daily precipitation, in mm).
- **Annual aggregation.** Arithmetic mean of daily values over each calendar year. The
  long-term trend uses only complete years (≥ ', MIN_DAYS, ' valid days). Where the current
  year is still in progress, the pipeline shows it separately — as a hollow “to date” marker
  on the trend chart, and (for a fair record comparison) against the same calendar window
  (Jan 1 → cutoff) of every prior year. A year enters that comparison only if it has
  ≥ ', MIN_YTD_DAYS, ' valid days in the window *and* covers every month of it: a year holding
  enough days bunched into part of the window is measuring a different season, not a
  different year.
- **Daily climatology.** Each year’s daily mean is smoothed with a centred
  ', SMOOTH_WINDOW, '-day rolling mean (unweighted, computed per year so December never bleeds
  into January) for legibility; leap days are aligned across years. The normal is the
  per-day average over all prior years.
- **Threshold days.** Frost = `TN < 0`, hot day = `TX ≥ ', HOT_TX, '`, very hot =
  `TX ≥ ', VHOT_TX, '`, tropical night = `TN ≥ ', TROPNIGHT, '`, counted per complete year and
  averaged over the first and last complete decade. A fixed threshold means different
  things in different climates: where it falls near the middle of a city’s distribution,
  that chapter says so, because the count then amplifies a modest shift in the mean.
- **Rainfall.** Annual total of daily `RR` over complete years; the trend is a
  least-squares slope with its two-sided p-value. Monthly climatology keeps only months
  with ≥ 27 valid days.
- **Trend.** Slope by linear regression (least squares); the curves on the line charts are
  LOESS smoothings (span = 0.7). Rates are reported per decade.
- **Reproducibility.** A 4-stage R pipeline (`R/00_prepare_data.R` → `R/01_plot.R` →
  `R/02_report.R` → `R/03_readme.R`), driven by `SITE=<site> make all`. See
  [How to run](#how-to-run).

<sub>Figures and numbers above are generated — edit `R/04_compare.R`, not this block.</sub>

<!-- END COMPARE -->'
)

readme <- "README.md"
lines <- readLines(readme, warn = FALSE)
text <- paste(lines, collapse = "\n")

i <- grep("<!-- BEGIN COMPARE -->", lines)
j <- grep("<!-- END COMPARE -->", lines)
if (length(i) != 1 || length(j) != 1)
  stop("README.md must contain exactly one '<!-- BEGIN COMPARE -->' line followed by one ",
       "'<!-- END COMPARE -->' line — found ", length(i), " and ", length(j),
       ". Add the marker pair by hand.")

new_lines <- c(lines[seq_len(i - 1)], strsplit(block, "\n")[[1]], lines[seq(j + 1, length(lines))])
writeLines(new_lines, readme)
cat(sprintf("Wrote README.md COMPARE block (%d lines between the markers)\n", length(strsplit(block, "\n")[[1]])))
