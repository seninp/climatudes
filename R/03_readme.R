#!/usr/bin/env Rscript
# =============================================================================
# Stage 03 — inject the report into README.md
# Renders the same numbers and figures as the HTML report (stage 02) as GitHub
# Markdown, so the README shows the analysis inline on the repository page.
# Run stage 01 first.
#
# Only the block between the BEGIN/END markers in README.md is replaced —
# everything around it (project docs, data source, how to run) is hand-written
# and left untouched. Unlike the HTML report the figures are NOT embedded: the
# README references outputs/figures/*.png, which therefore have to be committed
# for GitHub to render them (see .gitignore).
#
# As in stage 02 the template uses {{TOKEN}} placeholders filled by a single
# gsub pass rather than sprintf, whose format string caps at 8192 bytes.
# =============================================================================

suppressPackageStartupMessages({
  library(data.table)
})

source("R/config.R")

readme     <- "README.md"
annual_csv <- file.path(PATHS$outputs, "annual_temperatures.csv")
stats_rds  <- file.path(PATHS$processed, "trend_stats.rds")

BEGIN <- "<!-- BEGIN REPORT -->"
END   <- "<!-- END REPORT -->"

stopifnot(file.exists(readme), file.exists(annual_csv), file.exists(stats_rds))

stats  <- readRDS(stats_rds)
annual <- fread(annual_csv)

# Figure paths are written into the README as repo-relative POSIX paths, so the
# links resolve both on GitHub and in a local Markdown preview.
fig_series <- "outputs/figures/temperature_series.png"
fig_ytd    <- "outputs/figures/temperature_ytd.png"
fig_clim   <- "outputs/figures/temperature_climatology.png"
fig_rain   <- "outputs/figures/rain_series.png"
fig_rainc  <- "outputs/figures/rain_climatology.png"
for (f in c(fig_series, fig_ytd, fig_clim, fig_rain, fig_rainc))
  if (!file.exists(f)) stop("Missing ", f, " — run stage 01 first (make plots).")

fmt <- function(x, d = 2) formatC(x, format = "f", digits = d)
# First ten complete years (yr0 .. yr0+9), e.g. 1947-1956 — labelled by its real
# span, not floored to "the 1940s" (which the data does not fully cover).
early_span <- sprintf("%d–%d", stats$yr0, stats$yr0 + 9)

# ---- headline numbers table -------------------------------------------------
y <- stats$ytd
ytd_standing <- if (isTRUE(y$is_record))
  sprintf("**#1 of %d — record**", y$n_years) else
  sprintf("**#%d of %d**", y$rank, y$n_years)

# ---- last-decade rows (Toulouse-Blagnac) ------------------------------------
blag <- annual[station == "Toulouse-Blagnac"]
recent <- blag[year >= stats$yr1 - 9, .(year, TN, TX, TMEAN, complete)]
rows_md <- paste(sprintf("| %d%s | %.1f | %.1f | **%.1f** |",
                         recent$year,
                         ifelse(recent$complete, "", " *(to date)*"),
                         recent$TN, recent$TX, recent$TMEAN), collapse = "\n")

# ---- record-days rows (hottest / coldest per station) -----------------------
# The extreme value itself is bolded; the companion value is left plain.
rec_row <- function(label, span, date, tn, tx, bold_col) {
  vals <- c(TN = sprintf("%.1f", tn), TX = sprintf("%.1f", tx))
  vals[[bold_col]] <- sprintf("**%s**", vals[[bold_col]])
  sprintf("| %s | %s | %s | %s | %s |",
          span, label, date, vals[["TN"]], vals[["TX"]])
}
record_rows <- character(0)
for (r in stats$records) {
  span <- sprintf("%s <sub>%d–%d</sub>", r$station, r$span_yr0, r$span_yr1)
  record_rows <- c(record_rows,
    rec_row("Hottest 🔥", span, r$hot$date,  r$hot$tn,  r$hot$tx,  "TX"),
    rec_row("Coldest ❄️", span, r$cold$date, r$cold$tn, r$cold$tx, "TN"))
}
record_rows_md <- paste(record_rows, collapse = "\n")

# ---- hot / cold year sentences ----------------------------------------------
both_sentence <- if (length(stats$both_years) == 0)
  "No single year managed to hit both extremes." else
  sprintf("Years hitting both extremes: %s.", paste(stats$both_years, collapse = ", "))

# Data-derived clauses (were frozen prose) — see stage 02 for the rationale.
hot_recent_clause <- if (isTRUE(stats$hot_all_recent)) " — all of them recent —" else " —"
cold_era_clause   <- if (isTRUE(stats$cold_all_but_one)) ", all but one before 2000" else ""
raw_both_sentence <- if (length(stats$raw_both_years) == 0)
  "(On the raw, unsmoothed daily mean, no year touches both extremes.)" else
  sprintf("(If the threshold is applied instead to the raw, unsmoothed daily mean, %s %s touch both extremes.)",
          paste(stats$raw_both_years, collapse = " and "),
          if (length(stats$raw_both_years) == 1) "alone" else "each")

# ---- rainfall + extremes helper values --------------------------------------
rn <- stats$rain
ex <- stats$extremes
rain_slope_disp <- sprintf("%+.0f", rn$slope_dec)

# ---- year-to-date sentence (record vs not) ----------------------------------
ytd_sentence <- if (isTRUE(y$is_record))
  sprintf(paste0("Measured like-for-like, **%d is the warmest %s in %d years** at ",
                 "Toulouse-Blagnac: **%s °C** — +%s °C above the previous record ",
                 "(%d, %s °C) and **+%s °C above the long-term normal** (%s °C). ",
                 "This is exactly the point of the chart: a year still in progress ",
                 "can already stand out against the whole record."),
          stats$cur_year, y$window, y$n_years, fmt(y$cur, 1), fmt(y$cur - y$rec_val, 1),
          y$rec_year, fmt(y$rec_val, 1), fmt(y$cur_anom, 1), fmt(y$normal, 1)) else
  sprintf(paste0("Measured like-for-like over %s, %d currently ranks **#%d of %d** at ",
                 "Toulouse-Blagnac (%s °C). The warmest such window on record remains ",
                 "%d (%s °C)."),
          y$window, stats$cur_year, y$rank, y$n_years, fmt(y$cur, 1),
          y$rec_year, fmt(y$rec_val, 1))

# ---- the report, as Markdown ------------------------------------------------
template <- '## A warming climate, seen from Castanet-Tolosan

*Météo-France daily temperature records, {{YR0}} to {{YR1}} — plus {{CUR_YEAR}} so far.*

Météo-France daily records for the Castanet-Tolosan area tell an unambiguous story:
since the mid-20th century, minimum, maximum and mean temperatures have all risen —
steadily and continuously.

| Headline number | Value |
|---|---:|
| Warming rate, mean temperature (Toulouse-Blagnac) | **+{{SLOPE_DEC}} °C / decade** |
| Total rise over {{NYEARS}} years ({{YR0}} → {{YR1}}) | **+{{RISE}} °C** |
| Mean of the last decade (vs {{MEAN_EARLY}} °C in {{EARLY_SPAN}}) | **{{MEAN_RECENT}} °C** |
| Frost days per year, {{EXT_SPAN0}} → {{EXT_SPAN1}} | **{{FROST_EARLY}} → {{FROST_RECENT}}** |
| Hot days (≥ {{HOT_TX}} °C) per year, {{EXT_SPAN0}} → {{EXT_SPAN1}} | **{{HOT_EARLY}} → {{HOT_RECENT}}** |
| Complete station-years analysed | **{{N_STATION_YEARS}}** |
| {{CUR_YEAR}} year-to-date ({{YTD_WINDOW}}), against {{YTD_NYEARS_PRIOR}} prior years | {{YTD_STANDING}} |

### The long view: annual means

![Annual mean temperatures around Castanet-Tolosan, {{YR0}} to {{YR1}}, all three series rising]({{FIG_SERIES}})

<sub>Annual means of daily temperatures. The thick curves are LOESS smoothings that
highlight the climate trend; the points are annual means. The green series
(Auzeville-Tolosane-INRAE) is the station on the edge of Castanet-Tolosan; it tracks
the long Toulouse-Blagnac reference mean almost exactly.</sub>

At Toulouse-Blagnac — the station with the longest record ({{YR0}}→{{YR1}}) — the annual
mean temperature rises by **+{{SLOPE_DEC}} °C per decade**, about **+{{RISE}} °C** over the
whole period. The local Auzeville-Tolosane-INRAE station, on the edge of
Castanet-Tolosan, only covers {{AUZ_YR0}}→{{AUZ_YR1}}. Its slope over that shorter,
more recent window is steeper (+{{SLOPE_DEC_AUZ}} °C/decade) — but so is Blagnac’s over
the *same* years (+{{SLOPE_DEC_BLAG_AUZWIN}} °C/decade): recent decades warm faster, and
the local station sits almost exactly on the regional mean. The local and regional
signals are the same.

### This year, against every year before it

![Per-year mean over the same Jan-to-cutoff window, as a departure from the long-term normal, with {{CUR_YEAR}} the largest bar]({{FIG_YTD}})

<sub>Each bar is a year’s mean over the <em>same window</em> — <strong>{{YTD_WINDOW}}</strong> —
shown as its departure from the long-term normal ({{YTD_NORMAL}} °C): red above, blue
below. Comparing each year over the identical part-of-year is the only fair way to place
a year that is still in progress against history. The bars swing from blue to red over
the decades — the warming.</sub>

{{YTD_SENTENCE}}

> [!NOTE]
> A partial year cannot be compared to other years’ *full-year* means — it is still
> missing the warm late-summer and autumn tail. That is why {{CUR_YEAR}} appears on the
> long-view chart above only as a marked, hollow “to date” point (seasonally incomplete,
> so lower than its eventual annual figure), while its real, like-for-like standing is
> the chart here.

### Every year, day by day

![Daily temperature climatology, every year January to December, hot years red and cold years blue]({{FIG_CLIM}})

<sub>Each thin line is a single year’s daily mean temperature from January to December
({{CLIM_YR0}}–{{CLIM_YR1}}, {{CLIM_NYEARS}} years), smoothed with a centred
<strong>{{SMOOTH_WINDOW}}-day rolling mean</strong> (each day = the average of itself
±{{SMOOTH_HALF}} day(s)) to tame day-to-day jitter while keeping the shape. The dark line
is the long-term daily normal; the bold red line is <strong>{{CUR_YEAR}} so far</strong>.
Years whose smoothed daily mean ever rose above <strong>+{{HOT_THR}} °C</strong> are
highlighted in red and labelled; years that ever fell below
<strong>{{COLD_THR}} °C</strong> in blue.</sub>

> [!NOTE]
> **Hottest and coldest years.** Measured on the smoothed daily-mean curve,
> **{{N_HOT}}** years pushed above +{{HOT_THR}} °C ({{HOT_YEARS}}){{HOT_RECENT_CLAUSE}}
> while **{{N_COLD}}** years dropped below {{COLD_THR}} °C ({{COLD_YEARS}}){{COLD_ERA_CLAUSE}}.
> {{BOTH_SENTENCE}} The hot extremes and the cold extremes fall in different
> eras, which is itself a fingerprint of the warming trend. <sub>{{RAW_BOTH_SENTENCE}}</sub>

### The record days

The single most extreme days in each station’s record. “Hottest” is the highest daily
maximum (TX), “coldest” the lowest daily minimum (TN).

| Station (record span) | Extreme | Date | Min (TN) | Max (TX) |
|---|---|---|---:|---:|
{{RECORD_ROWS}}

The all-time heat (Aug 2023) is recent at both stations, while the deepest cold is
decades old (Feb 1956 at Blagnac) — the same warming signature seen above.

### The last decade (Toulouse-Blagnac)

| Year | Min (TN) | Max (TX) | Mean |
|---|---:|---:|---:|
{{ROWS}}

### Frost days halved, hot days doubled

A degree of warming is abstract; the count of extreme days is not. Comparing
Toulouse-Blagnac’s first complete decade ({{EXT_SPAN0}}) with its last ({{EXT_SPAN1}}),
the everyday texture of the year has changed sharply:

| Threshold days per year | {{EXT_SPAN0}} | {{EXT_SPAN1}} |
|---|---:|---:|
| Frost days (min < 0 °C) | {{FROST_EARLY}} | **{{FROST_RECENT}}** |
| Hot days (max ≥ {{HOT_TX}} °C) | {{HOT_EARLY}} | **{{HOT_RECENT}}** |
| Very hot days (max ≥ {{VHOT_TX}} °C) | {{VHOT_EARLY}} | **{{VHOT_RECENT}}** |
| Tropical nights (min ≥ {{TROP_TX}} °C) | {{TROP_EARLY}} | **{{TROP_RECENT}}** |

<sub>Counts of days per year crossing each threshold, averaged over the first and last
complete decades. Frost is retreating just as heat advances — the same warming, read
off the calendar instead of the thermometer.</sub>

### What about the rain?

Temperature is only half of a climate. Rainfall tells a very different — and much
quieter — story: over the same {{RAIN_NYEARS}} years, annual precipitation at
Toulouse-Blagnac shows **no statistically significant trend**.

![Annual rainfall totals around Castanet-Tolosan, with a flat long-term trend]({{FIG_RAIN}})

<sub>Annual total precipitation. The dashed line is Toulouse-Blagnac’s long-term mean
({{RAIN_MEAN}} mm/yr); the thick curves are LOESS smoothings. The year-to-year swings are
large — from {{DRIEST_MM}} mm ({{DRIEST_YEAR}}) to {{WETTEST_MM}} mm ({{WETTEST_YEAR}}) —
but the long-run slope ({{RAIN_SLOPE}} mm/decade) is flat and not significant
(p = {{RAIN_P}}).</sub>

That contrast is the point. The very same daily records that show an unmistakable,
statistically strong warming signal show *no* comparable signal in how much it rains. A
dataset that manufactured trends would have produced one here too; this one does not.

![Monthly rainfall through the year at Toulouse-Blagnac, one line per year]({{FIG_RAINC}})

<sub>Rain through the year: each grey line is one year’s monthly totals, the dark line the
long-term monthly normal, the bold blue line {{CUR_YEAR}} so far. {{WET_MONTH}} is the
wettest month on average ({{WET_MONTH_MM}} mm), {{DRY_MONTH}} the driest
({{DRY_MONTH_MM}} mm) — but the spread between years dwarfs the seasonal cycle, which is
exactly why no annual trend emerges.</sub>

### Methodology

- **Variables.** Minimum = `TN`, maximum = `TX`, mean = `(TN+TX)/2` (field `TNTXM`), in °C;
  rainfall = `RR` (daily precipitation, in mm).
- **Annual aggregation.** Arithmetic mean of daily values over each calendar year. The
  long-term trend uses only complete years (≥ {{MIN_DAYS}} valid days). The in-progress
  year is shown separately — as a hollow “to date” marker on the trend chart, and (for a
  fair record comparison) against the same calendar window (Jan 1 → cutoff) of every
  prior year, keeping only years with ≥ {{MIN_YTD_DAYS}} valid days in that window.
- **Daily climatology.** Each year’s daily mean is smoothed with a centred
  {{SMOOTH_WINDOW}}-day rolling mean (unweighted moving average, computed per year so
  December never bleeds into January; the first/last {{SMOOTH_HALF}} day(s) keep their raw
  value) for legibility; leap days are aligned across years. The normal is the per-day
  average over all prior years.
- **Threshold days.** Frost = `TN < 0`, hot day = `TX ≥ {{HOT_TX}}`, very hot =
  `TX ≥ {{VHOT_TX}}`, tropical night = `TN ≥ {{TROP_TX}}`, counted per complete year and
  averaged over the first/last complete decade.
- **Rainfall.** Annual total of daily `RR` over complete years; the trend is a
  least-squares slope with its two-sided p-value. Monthly climatology keeps only months
  with ≥ 27 valid days.
- **Trend.** Slope estimated by linear regression (least squares); the line-chart curves
  use LOESS smoothing (span = 0.7).
- **Reproducibility.** A 4-stage R pipeline (`R/00_prepare_data.R` → `R/01_plot.R` →
  `R/02_report.R` → `R/03_readme.R`), driven by `make all`. The figures above and the
  numbers in this section are regenerated from the source data on every run — see
  [Data source](#data-source) below for the full citation.

<sub>Figures and numbers above are generated — edit `R/03_readme.R`, not this block.</sub>'

# ---- fill placeholders (single gsub pass, no length limit) ------------------
fills <- c(
  YR0             = stats$yr0,
  YR1             = stats$yr1,
  NYEARS          = stats$yr1 - stats$yr0,
  SLOPE_DEC       = fmt(stats$slope_dec_blag),
  SLOPE_DEC_AUZ   = fmt(stats$slope_dec_auz),
  SLOPE_DEC_BLAG_AUZWIN = fmt(stats$slope_dec_blag_auzwin),
  RISE            = fmt(stats$rise_blag, 1),
  MEAN_RECENT     = fmt(stats$mean_recent, 1),
  MEAN_EARLY      = fmt(stats$mean_early, 1),
  EARLY_SPAN      = early_span,
  N_STATION_YEARS = stats$n_station_years,
  AUZ_YR0         = stats$auz_yr0,
  AUZ_YR1         = stats$auz_yr1,
  CLIM_YR0        = stats$clim_yr0,
  CLIM_YR1        = stats$clim_yr1,
  CLIM_NYEARS     = stats$clim_nyears,
  CUR_YEAR        = stats$cur_year,
  HOT_THR         = stats$hot_thr,
  COLD_THR        = stats$cold_thr,
  N_HOT           = length(stats$hot_years),
  N_COLD          = length(stats$cold_years),
  HOT_YEARS       = paste(stats$hot_years,  collapse = ", "),
  COLD_YEARS      = paste(stats$cold_years, collapse = ", "),
  BOTH_SENTENCE   = both_sentence,
  HOT_RECENT_CLAUSE = hot_recent_clause,
  COLD_ERA_CLAUSE   = cold_era_clause,
  RAW_BOTH_SENTENCE = raw_both_sentence,
  SMOOTH_WINDOW   = stats$smooth_window,
  SMOOTH_HALF     = (stats$smooth_window - 1) %/% 2,
  MIN_DAYS        = MIN_DAYS,
  MIN_YTD_DAYS    = MIN_YTD_DAYS,
  ROWS            = rows_md,
  RECORD_ROWS     = record_rows_md,
  FIG_SERIES      = fig_series,
  FIG_YTD         = fig_ytd,
  FIG_CLIM        = fig_clim,
  FIG_RAIN        = fig_rain,
  FIG_RAINC       = fig_rainc,
  YTD_WINDOW      = y$window,
  YTD_NYEARS      = y$n_years,
  YTD_NYEARS_PRIOR = y$n_years - 1,
  YTD_NORMAL      = fmt(y$normal, 1),
  YTD_STANDING    = ytd_standing,
  YTD_SENTENCE    = ytd_sentence,
  # extremes (threshold-day counts)
  EXT_SPAN0       = sprintf("%d–%d", ex$yr0, ex$yr0 + 9),
  EXT_SPAN1       = sprintf("%d–%d", ex$yr1 - 9, ex$yr1),
  HOT_TX          = ex$hot_thr,  VHOT_TX = ex$vhot_thr, TROP_TX = ex$trop_thr,
  FROST_EARLY     = ex$frost_early, FROST_RECENT = ex$frost_recent,
  HOT_EARLY       = ex$hot_early,   HOT_RECENT   = ex$hot_recent,
  VHOT_EARLY      = ex$vhot_early,  VHOT_RECENT  = ex$vhot_recent,
  TROP_EARLY      = ex$trop_early,  TROP_RECENT  = ex$trop_recent,
  # rainfall
  RAIN_NYEARS     = rn$n_years, RAIN_MEAN = rn$mean_blag,
  RAIN_SLOPE      = rain_slope_disp, RAIN_P = fmt(rn$p, 2),
  WETTEST_YEAR    = rn$wettest_year, WETTEST_MM = rn$wettest_mm,
  DRIEST_YEAR     = rn$driest_year,  DRIEST_MM  = rn$driest_mm,
  WET_MONTH       = rn$wet_month, WET_MONTH_MM = rn$wet_month_mm,
  DRY_MONTH       = rn$dry_month, DRY_MONTH_MM = rn$dry_month_mm
)

block <- template
for (key in names(fills)) {
  block <- gsub(paste0("{{", key, "}}"), fills[[key]], block, fixed = TRUE)
}

# safety: warn if any placeholder went unfilled
leftover <- regmatches(block, gregexpr("\\{\\{[A-Z_0-9]+\\}\\}", block))[[1]]
if (length(leftover) > 0)
  warning("Unfilled placeholders: ", paste(unique(leftover), collapse = ", "))

# ---- splice the block into README.md between the markers --------------------
lines <- readLines(readme, warn = FALSE)
i <- which(lines == BEGIN)
j <- which(lines == END)
if (length(i) != 1L || length(j) != 1L || j <= i)
  stop("README.md must contain exactly one '", BEGIN, "' line followed by one '", END,
       "' line — found ", length(i), " and ", length(j), ".")

out <- c(lines[seq_len(i)],
         "",
         strsplit(block, "\n", fixed = TRUE)[[1]],
         "",
         lines[j:length(lines)])
writeLines(out, readme)

cat(sprintf("Wrote %s report block (%d lines between the markers)\n",
            readme, length(out) - (length(lines) - (j - i - 1))))
