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

SITE_ORDER <- c("castanet", "zurich", "karlsruhe", "santafe", "honolulu", "noumea", "moscow", "voronezh", "irvine", "albuquerque")

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
    manual_source = identical(site$source, "meteoru")
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

N_SITES     <- nrow(cmp)
N_AUTOMATED <- sum(!cmp$manual_source)
N_MANUAL    <- sum(cmp$manual_source)
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

agg_png("outputs/compare/figures/warming_rate.png",
        width = 2400, height = 1300, res = 200, background = "white")
print(p); invisible(dev.off())
message("Wrote outputs/compare/figures/warming_rate.png")

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

![Warming rate compared across all ', num_word(N_SITES), ' cities, ranked fastest to slowest, with a shared-window rate alongside](outputs/compare/figures/warming_rate.png)

<sub>Ranked by the raw rate. ', longest$city, '’s record runs ', longest$nyears - shortest$nyears,
' years longer than ', shortest$city, '’s, so two similar-looking rates can rest on very different
amounts of evidence — the record span and the count of complete years are in the table below.</sub>

| City | Country | Record | °C/decade | ', COMMON_YR0, '→ | Standing | Window ranked | Data current through |
|---|---|---:|---:|---:|---|---|---|
', paste(table_rows, collapse = "\n"), '

† Moscow and Voronezh are manually exported from Roshydromet’s AISORI-M (login-gated, no automated
refresh), so their "current through" date lags the automated feeds by however long it has been since
the last hand export. See each city’s own "Why only one station?" note below.

Each row names the window its standing is measured over, because the rows do not all make the same
claim. The windows run from Voronezh’s 59 midwinter days through Irvine’s five months to the eight
months most sites reach, and Moscow’s row ranks a complete, already-finished ', cmp[site_key == "moscow"]$cur_year, '.
A rank is comparable **within** a city — the same calendar window against that city’s own history —
but not across cities. Standardising every site to the shortest window they share reorders the
standings substantially, and several cities holding a "record" badge here do not hold one there:
a January-to-May mean and a January-to-August mean are different statistics. A "#55 of 84" over two
months of winter is not the same kind of statement as an eight-month "#5 of 76".
', nm_note, '
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
