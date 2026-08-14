#!/usr/bin/env Rscript
# =============================================================================
# Stage 04 — cross-site comparison (run after every site's stage 01)
# Reads every site's trend_stats.rds and SITE list, and produces:
#   * outputs/compare/figures/warming_rate.png   — ranked bar chart
#   * README.md, spliced between <!-- BEGIN COMPARE --> / <!-- END COMPARE -->
#
# Unlike stages 00-03 this is NOT parameterized by SITE — it always covers
# every site in SITE_ORDER below, hand-maintained (not discovered from
# R/sites/*.R) so a new 9th site is a deliberate addition here, not a silent
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

SITE_ORDER <- c("castanet", "zurich", "karlsruhe", "santafe", "honolulu", "noumea", "moscow", "voronezh")

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
    yr0 = stats$yr0, yr1 = stats$yr1, nyears = stats$yr1 - stats$yr0,
    slope_dec = stats$slope_dec_ref,
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

dir.create("outputs/compare/figures", recursive = TRUE, showWarnings = FALSE)

# ---- FIGURE — warming rate, ranked ------------------------------------------
# Fastest at TOP: ggplot2 places factor level 1 at the BOTTOM of a discrete
# y-axis, so the level order must be the REVERSE of display order, or the
# chart silently renders upside-down from what "ranked fastest to slowest"
# (in the caption below and in the table) claims.
plot_ord <- cmp[order(-slope_dec)]
cmp[, city_f := factor(city, levels = rev(plot_ord$city))]

# One flat, muted fill for every bar. Position (already ranked) plus the bold
# city label on the y-axis fully identify each bar — a distinct saturated hue
# per bar would add no information a reader depends on, i.e. exactly the
# "categorical hues when the story is one number" anti-pattern.
BAR_FILL <- "#5B7FA6"

# End label is deliberately just the rate — record span/length is already in
# the table right below the figure, so it isn't repeated here (repeating it
# on the longest bar was also overflowing the canvas — see the render check).
p <- ggplot(cmp, aes(x = slope_dec, y = city_f)) +
  geom_col(width = 0.62, fill = BAR_FILL) +
  geom_text(aes(label = sprintf("+%.2f °C/decade", slope_dec)),
            hjust = 0, nudge_x = max(cmp$slope_dec) * 0.02,
            size = 3.6, colour = "#3D4A54") +
  scale_x_continuous(limits = c(0, max(cmp$slope_dec) * 1.32), expand = expansion(mult = c(0, 0)),
                     labels = function(x) sprintf("+%.1f", x)) +
  labs(
    title = "Eight cities, all warming — just not at the same speed",
    subtitle = "Annual-mean warming rate, least-squares slope over each city's own complete-year record",
    x = "°C per decade", y = NULL,
    caption = paste0(
      "Source: each city's own report, this repository. Records span different years and lengths ",
      "(see the table below) — a raw rate is not adjusted for record length or baseline era.\n",
      "Slope = linear regression on complete-year annual means (≥ ", MIN_DAYS, " valid days/year); ",
      "matches the “Warming rate” headline number in each city's own section below."
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
    plot.margin = margin(18, 26, 12, 18),
    plot.background = element_rect(fill = "white", colour = NA)
  )

agg_png("outputs/compare/figures/warming_rate.png",
        width = 2400, height = 1300, res = 200, background = "white")
print(p); invisible(dev.off())
message("Wrote outputs/compare/figures/warming_rate.png")

# ---- TABLE -------------------------------------------------------------------
# "This year's standing" is NOT the same claim for every row: the six
# automated sites all rank the SAME in-progress year (2026) over roughly
# comparable multi-month windows, but Moscow's window is a complete,
# already-finished past year (2025) and Voronezh's is a 59-day midwinter
# fragment -- ranking those alongside "#5 of 76" for an 8-month window would
# read as more comparable than it is. Every row therefore names its own year
# and window explicitly, not just the two outliers, so no row's claim is
# unlabelled.
window_note <- function(r) {
  if (r$window_days >= 350) sprintf("%d, full year", r$cur_year) else
    sprintf("%d, %s", r$cur_year, r$window)
}
row_md <- function(r) {
  y <- list(has_ytd = r$has_ytd, is_record = r$is_record, rank = r$ytd_rank, n_years = r$ytd_n)
  standing <- if (!r$has_ytd) "too early to rank" else
    sprintf("%s (%s)", ytd_standing_text(y), window_note(r))
  freshness <- if (r$manual_source) sprintf("%s †", r$current_through) else r$current_through
  sprintf("| %s | %s | %d→%d (%d yr) | **%+.2f °C/decade** | %s | %s |",
          r$city, r$country, r$yr0, r$yr1, r$nyears, r$slope_dec, standing, freshness)
}
table_rows <- vapply(seq_len(nrow(plot_ord)), function(i) row_md(plot_ord[i]), character(1))

block <- paste0(
'<!-- BEGIN COMPARE -->

## All eight cities, side by side

Every chapter below uses the same variables, the same completeness rule (>= ', MIN_DAYS, ' valid
days/year) and the same trend method (least-squares on annual means) — the numbers below are those
same headline figures, gathered in one place rather than recomputed. These are raw warming rates:
they are not adjusted for the very different length and era of each record. The record span in the
table is the honest caveat, not a footnote to skip.

![Warming rate compared across all eight cities, ranked fastest to slowest](outputs/compare/figures/warming_rate.png)

<sub>Ranked fastest to slowest. Record span and length for each city are in the table below, not
repeated on the bars — Santa Fe’s and Karlsruhe’s records run a century longer than Honolulu’s or
Nouméa’s, so the same-looking rate rests on very different amounts of evidence.</sub>

| City | Country | Record | Warming rate | Standing | Data current through |
|---|---|---:|---:|---|---|
', paste(table_rows, collapse = "\n"), '

† Moscow and Voronezh are manually exported from Roshydromet’s AISORI-M (login-gated, no automated
refresh) — their "current through" date is not "today" the way the other six sites’ automated feeds
are; see each city’s own "Why only one station?" note in its chapter below.

Each row’s standing also names its own year and window in parentheses, since they are not all the
same claim: the six automated sites all rank 2026 over comparable multi-month windows, but Moscow’s
row ranks a complete, already-finished 2025 and Voronezh’s ranks a 59-day midwinter fragment — a
"#55 of 84" over two months of winter is not the same kind of statement as an 8-month "#5 of 76".

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
