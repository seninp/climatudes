#!/usr/bin/env Rscript
# =============================================================================
# Stage 02 — build the report
# Assembles a self-contained, readable HTML report (English) that embeds both
# figures as base64 — no pandoc / external assets. Run stage 01 first.
# Output: outputs/temperature_report.html
#
# The template uses {{TOKEN}} placeholders filled by a single gsub pass, rather
# than sprintf — sprintf caps the format string at 8192 bytes, which a full HTML
# page (plus citation) exceeds.
# =============================================================================

suppressPackageStartupMessages({
  library(base64enc)
  library(data.table)
})

source("R/config.R")

fig_series <- file.path(PATHS$figures, "temperature_series.png")
fig_clim   <- file.path(PATHS$figures, "temperature_climatology.png")
fig_ytd    <- file.path(PATHS$figures, "temperature_ytd.png")
fig_rain   <- file.path(PATHS$figures, "rain_series.png")
fig_rainc  <- file.path(PATHS$figures, "rain_climatology.png")
annual_csv <- file.path(PATHS$outputs, "annual_temperatures.csv")
stats_rds  <- file.path(PATHS$processed, "trend_stats.rds")

stopifnot(file.exists(fig_series), file.exists(fig_clim), file.exists(fig_ytd),
          file.exists(fig_rain), file.exists(fig_rainc),
          file.exists(annual_csv), file.exists(stats_rds))

img_series <- base64encode(fig_series)
img_clim   <- base64encode(fig_clim)
img_ytd    <- base64encode(fig_ytd)
img_rain   <- base64encode(fig_rain)
img_rainc  <- base64encode(fig_rainc)
stats      <- readRDS(stats_rds)
annual     <- fread(annual_csv)

blag <- annual[station == "Toulouse-Blagnac"]

recent <- blag[year >= stats$yr1 - 9,
               .(year, TN = round(TN, 1), TX = round(TX, 1), Mean = round(TMEAN, 1))]
rows_html <- paste(sprintf(
  "<tr><td>%d</td><td>%.1f</td><td>%.1f</td><td><strong>%.1f</strong></td></tr>",
  recent$year, recent$TN, recent$TX, recent$Mean), collapse = "\n")

# ---- record-days table rows (hottest / coldest per station) -----------------
rec_row <- function(label, span, date, tn, tx, colour, val_col) {
  vals <- c(TN = sprintf("%.1f", tn), TX = sprintf("%.1f", tx))
  vals[[val_col]] <- sprintf("<strong style=\"color:%s\">%s</strong>", colour, vals[[val_col]])
  sprintf(paste0("<tr><td>%s</td>",
                 "<td style=\"color:%s;font-weight:600\">%s</td>",
                 "<td>%s</td><td>%s</td><td>%s</td></tr>"),
          span, colour, label, date, vals[["TN"]], vals[["TX"]])
}
record_rows <- character(0)
for (r in stats$records) {
  span <- sprintf("%s<br><span style=\"color:#8A97A0;font-size:0.85em\">%d&ndash;%d</span>",
                  r$station, r$span_yr0, r$span_yr1)
  record_rows <- c(record_rows,
    rec_row("Hottest &#128293;", span, r$hot$date,  r$hot$tn,  r$hot$tx,  "#C0392B", "TX"),
    rec_row("Coldest &#10052;",  span, r$cold$date, r$cold$tn, r$cold$tx, "#1F5FA8", "TN"))
}
record_rows_html <- paste(record_rows, collapse = "\n")

fmt <- function(x, d = 2) formatC(x, format = "f", digits = d)
# The "early" baseline is the first ten complete years (yr0 .. yr0+9), e.g.
# 1947-1956 — NOT "the 1940s" (that floored 1947 to 1940 and misread as a
# 1940-1949 decade the data does not fully cover). Label it as the real span.
early_span <- sprintf("%d&ndash;%d", stats$yr0, stats$yr0 + 9)

template <- '<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Temperatures around Castanet-Tolosan</title>
<style>
  :root {
    --ink:#1A2530; --muted:#566573; --faint:#8A97A0;
    --accent:#C0392B; --green:#1E8449; --blue:#2471A3;
    --bg:#F7F8FA; --card:#FFFFFF; --line:#E6EAEE;
  }
  * { box-sizing: border-box; }
  body {
    margin:0; background:var(--bg); color:var(--ink);
    font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
    line-height:1.65; -webkit-font-smoothing:antialiased;
  }
  .wrap { max-width:960px; margin:0 auto; padding:48px 24px 80px; }
  header { border-bottom:3px solid var(--accent); padding-bottom:22px; margin-bottom:34px; }
  h1 { font-size:2.0rem; line-height:1.2; margin:0 0 8px; letter-spacing:-0.01em; }
  .sub { color:var(--muted); font-size:1.06rem; margin:0; }
  .eyebrow { text-transform:uppercase; letter-spacing:0.12em; font-size:0.72rem;
             font-weight:700; color:var(--accent); margin:0 0 10px; }
  h2 { font-size:1.28rem; margin:46px 0 12px; padding-top:8px; }
  p { margin:0 0 16px; }
  .lead { font-size:1.12rem; color:#34404A; }
  figure { margin:30px 0; background:var(--card); border:1px solid var(--line);
           border-radius:14px; padding:16px; box-shadow:0 1px 3px rgba(20,30,40,.05); }
  figure img { width:100%; height:auto; display:block; border-radius:6px; }
  figcaption { color:var(--faint); font-size:0.85rem; margin-top:12px; padding:0 4px; }
  .stats { display:grid; grid-template-columns:repeat(auto-fit,minmax(180px,1fr));
           gap:16px; margin:28px 0; }
  .stat { background:var(--card); border:1px solid var(--line); border-radius:12px;
          padding:20px; box-shadow:0 1px 3px rgba(20,30,40,.04); }
  .stat .num { font-size:1.9rem; font-weight:700; line-height:1.1; color:var(--accent); }
  .stat .lab { color:var(--muted); font-size:0.86rem; margin-top:6px; }
  table { width:100%; border-collapse:collapse; margin:18px 0; font-size:0.95rem;
          background:var(--card); border:1px solid var(--line); border-radius:10px; overflow:hidden; }
  th,td { padding:9px 14px; text-align:right; border-bottom:1px solid var(--line); }
  th:first-child,td:first-child { text-align:left; }
  thead th { background:#F0F3F6; color:var(--muted); font-weight:600;
             text-transform:uppercase; font-size:0.72rem; letter-spacing:0.05em; }
  tbody tr:last-child td { border-bottom:none; }
  .note { background:#FFF8F0; border-left:4px solid #E69138; border-radius:0 8px 8px 0;
          padding:14px 18px; margin:24px 0; font-size:0.95rem; color:#5C4A2E; }
  .meth { background:var(--card); border:1px solid var(--line); border-radius:12px;
          padding:8px 22px; margin:18px 0; }
  .meth li { margin:10px 0; color:#3A4750; }
  .src { background:var(--card); border:1px solid var(--line); border-radius:12px;
         padding:16px 22px; margin:18px 0; font-size:0.95rem; }
  footer { margin-top:54px; padding-top:20px; border-top:1px solid var(--line);
           color:var(--faint); font-size:0.83rem; }
  a { color:var(--blue); word-break:break-word; }
  code { background:#EEF1F4; padding:1px 6px; border-radius:5px; font-size:0.88em; }
</style>
</head>
<body>
<div class="wrap">

  <header>
    <p class="eyebrow">Local climate &middot; Haute-Garonne, France</p>
    <h1>A warming climate, seen from Castanet-Tolosan</h1>
    <p class="sub">M&eacute;t&eacute;o-France daily temperature records, {{YR0}} to {{YR1}}</p>
  </header>

  <p class="lead">
    M&eacute;t&eacute;o-France daily records for the Castanet-Tolosan area tell an unambiguous
    story: since the mid-20th century, minimum, maximum and mean temperatures have
    all risen &mdash; steadily and continuously.
  </p>

  <div class="stats">
    <div class="stat"><div class="num">+{{SLOPE_DEC}}&nbsp;&deg;C</div>
      <div class="lab">per decade (mean temperature, Toulouse-Blagnac)</div></div>
    <div class="stat"><div class="num">+{{RISE}}&nbsp;&deg;C</div>
      <div class="lab">total rise over {{NYEARS}} years ({{YR0}} &rarr; {{YR1}})</div></div>
    <div class="stat"><div class="num">{{MEAN_RECENT}}&nbsp;&deg;C</div>
      <div class="lab">mean of the last decade<br>(vs {{MEAN_EARLY}}&nbsp;&deg;C in {{EARLY_SPAN}})</div></div>
    <div class="stat"><div class="num">{{N_STATION_YEARS}}</div>
      <div class="lab">complete station-years analysed</div></div>
  </div>

  <h2>The long view: annual means</h2>
  <figure>
    <img src="data:image/png;base64,{{IMG_SERIES}}" alt="Annual temperature series, Castanet-Tolosan area, {{YR0}}-{{YR1}}">
    <figcaption>
      Annual means of daily temperatures. The thick curves are LOESS smoothings that
      highlight the climate trend; the points are annual means. The green series
      (Auzeville-Tolosane-INRAE) is the station on the edge of Castanet-Tolosan; it
      tracks the long Toulouse-Blagnac reference mean almost exactly.
    </figcaption>
  </figure>

  <p>
    At Toulouse-Blagnac &mdash; the station with the longest record ({{YR0}}&rarr;{{YR1}}) &mdash; the annual
    mean temperature rises by <strong>+{{SLOPE_DEC}}&nbsp;&deg;C per decade</strong>, about
    <strong>+{{RISE}}&nbsp;&deg;C</strong> over the whole period. The local
    Auzeville-Tolosane-INRAE station, on the edge of Castanet-Tolosan, only covers
    {{AUZ_YR0}}&rarr;{{AUZ_YR1}}. Its slope over that shorter, more recent window is
    steeper (+{{SLOPE_DEC_AUZ}}&nbsp;&deg;C/decade) &mdash; but so is Blagnac&rsquo;s over the
    <em>same</em> years (+{{SLOPE_DEC_BLAG_AUZWIN}}&nbsp;&deg;C/decade): recent decades
    warm faster, and the local station tracks the regional one almost exactly. The
    local and regional signals are the same.
  </p>

  <h2>This year, against every year before it</h2>
  <figure>
    <img src="data:image/png;base64,{{IMG_YTD}}" alt="Per-year departure of the same-window mean temperature from the long-term normal, current year highlighted as the largest">
    <figcaption>
      Each bar is a year&rsquo;s mean over the <em>same window</em> &mdash;
      <strong>{{YTD_WINDOW}}</strong> &mdash; shown as its departure from the long-term
      normal ({{YTD_NORMAL}}&nbsp;&deg;C): red above, blue below. Comparing each year over
      the identical part-of-year is the only fair way to place a year that is still in
      progress against history. The bars swing from blue to red over the decades &mdash;
      the warming &mdash; and <strong>{{CUR_YEAR}}</strong> is the tallest of all.
    </figcaption>
  </figure>
  <p>{{YTD_SENTENCE}}</p>
  <div class="note">
    A partial year cannot be compared to other years&rsquo; <em>full-year</em> means &mdash;
    it is still missing the warm late-summer and autumn tail. That is why {{CUR_YEAR}}
    appears on the long-view chart above only as a marked, hollow &ldquo;to&nbsp;date&rdquo;
    point (seasonally incomplete, so lower than its eventual annual figure), while its
    real, like-for-like standing is the chart here.
  </div>

  <h2>Every year, day by day</h2>
  <figure>
    <img src="data:image/png;base64,{{IMG_CLIM}}" alt="Daily temperature climatology, every year January to December, with hot years in red and cold years in blue">
    <figcaption>
      Each thin line is a single year&rsquo;s daily mean temperature from January to
      December ({{CLIM_YR0}}&ndash;{{CLIM_YR1}}, {{CLIM_NYEARS}} years), smoothed with a centred
      <strong>{{SMOOTH_WINDOW}}-day rolling mean</strong> (each day = the average of itself
      &plusmn;{{SMOOTH_HALF}} day(s)) to tame day-to-day jitter while keeping the shape.
      The dark line is the long-term daily normal; the
      bold red line is <strong>{{CUR_YEAR}} so far</strong>. Years whose smoothed daily mean ever
      rose above <strong>+{{HOT_THR}}&nbsp;&deg;C</strong> are highlighted in red and labelled;
      years that ever fell below <strong>{{COLD_THR}}&nbsp;&deg;C</strong> in blue.
    </figcaption>
  </figure>

  <div class="note">
    <strong>Hottest and coldest years.</strong> Measured on the smoothed daily-mean
    curve, <strong>{{N_HOT}}</strong> years pushed above +{{HOT_THR}}&nbsp;&deg;C
    ({{HOT_YEARS}}){{HOT_RECENT_CLAUSE}} while <strong>{{N_COLD}}</strong> years
    dropped below {{COLD_THR}}&nbsp;&deg;C ({{COLD_YEARS}}){{COLD_ERA_CLAUSE}}.
    <strong>{{BOTH_SENTENCE}}</strong> The hot extremes and the cold extremes fall in
    different eras, which is itself a fingerprint of the warming trend.
    <span style="color:#8A97A0;">{{RAW_BOTH_SENTENCE}}</span>
  </div>

  <h2>The record days</h2>
  <p>
    The single most extreme days in each station&rsquo;s record. &ldquo;Hottest&rdquo;
    is the highest daily maximum (TX), &ldquo;coldest&rdquo; the lowest daily minimum (TN).
  </p>
  <table>
    <thead><tr>
      <th>Station (record span)</th><th>Extreme</th><th>Date</th>
      <th>Min (TN)</th><th>Max (TX)</th>
    </tr></thead>
    <tbody>
{{RECORD_ROWS}}
    </tbody>
  </table>
  <p style="color:#8A97A0; font-size:0.9rem;">
    The all-time heat (Aug 2023) is recent at both stations, while the deepest cold
    is decades old (Feb 1956 at Blagnac) &mdash; the same warming signature seen above.
  </p>

  <div class="note">
    <strong>Why Auzeville?</strong> The M&eacute;t&eacute;o-France dataset for department&nbsp;31
    contains no station literally named &ldquo;Castanet-Tolosan&rdquo;. The
    <em>Auzeville-Tolosane-INRAE</em> station (no.&nbsp;31035001), on the INRAE/ENSAT
    campus, sits right on the Castanet-Tolosan boundary &mdash; the most representative
    local record. Toulouse-Blagnac (no.&nbsp;31069001) provides the historical depth
    needed to see the underlying trend and to draw the day-by-day climatology.
  </div>

  <h2>The last decade (Toulouse-Blagnac)</h2>
  <table>
    <thead><tr><th>Year</th><th>Min (TN)</th><th>Max (TX)</th><th>Mean</th></tr></thead>
    <tbody>
{{ROWS}}
    </tbody>
  </table>

  <h2>Frost days halved, hot days doubled</h2>
  <p>
    A degree of warming is abstract; the count of extreme days is not. Comparing
    Toulouse-Blagnac&rsquo;s first complete decade ({{EXT_SPAN0}}) with its last
    ({{EXT_SPAN1}}), the everyday texture of the year has changed sharply:
  </p>
  <div class="stats">
    <div class="stat"><div class="num" style="color:var(--blue)">{{FROST_EARLY}}&nbsp;&rarr;&nbsp;{{FROST_RECENT}}</div>
      <div class="lab">frost days per year<br>(min below&nbsp;0&nbsp;&deg;C) &mdash; roughly halved</div></div>
    <div class="stat"><div class="num">{{HOT_EARLY}}&nbsp;&rarr;&nbsp;{{HOT_RECENT}}</div>
      <div class="lab">hot days per year<br>(max&nbsp;&ge;&nbsp;{{HOT_TX}}&nbsp;&deg;C) &mdash; roughly doubled</div></div>
    <div class="stat"><div class="num">{{VHOT_EARLY}}&nbsp;&rarr;&nbsp;{{VHOT_RECENT}}</div>
      <div class="lab">very hot days per year<br>(max&nbsp;&ge;&nbsp;{{VHOT_TX}}&nbsp;&deg;C)</div></div>
    <div class="stat"><div class="num">{{TROP_EARLY}}&nbsp;&rarr;&nbsp;{{TROP_RECENT}}</div>
      <div class="lab">tropical nights per year<br>(min&nbsp;&ge;&nbsp;{{TROP_TX}}&nbsp;&deg;C)</div></div>
  </div>
  <p style="color:#8A97A0; font-size:0.9rem;">
    Counts of days per year crossing each threshold, averaged over the first and
    last complete decades of the record. Frost is retreating just as heat advances
    &mdash; the same warming, read off the calendar instead of the thermometer.
  </p>

  <h2>What about the rain?</h2>
  <p>
    Temperature is only half of a climate. Rainfall, it turns out, tells a very
    different &mdash; and much quieter &mdash; story: over the same {{RAIN_NYEARS}}&nbsp;years,
    annual precipitation at Toulouse-Blagnac shows <strong>no statistically
    significant trend</strong>.
  </p>
  <figure>
    <img src="data:image/png;base64,{{IMG_RAIN}}" alt="Annual rainfall totals, Toulouse-Blagnac and Auzeville, {{RAIN_YR0}}-{{RAIN_YR1}}, with a flat trend">
    <figcaption>
      Annual total precipitation. The dashed line is Toulouse-Blagnac&rsquo;s
      long-term mean ({{RAIN_MEAN}}&nbsp;mm/yr); the thick curves are LOESS
      smoothings. The year-to-year swings are large &mdash; from
      {{DRIEST_MM}}&nbsp;mm ({{DRIEST_YEAR}}) to {{WETTEST_MM}}&nbsp;mm
      ({{WETTEST_YEAR}}) &mdash; but the long-run slope
      ({{RAIN_SLOPE}}&nbsp;mm/decade) is flat and not significant (p&nbsp;=&nbsp;{{RAIN_P}}).
    </figcaption>
  </figure>
  <p>
    That contrast is the point. The very same daily records that show an
    unmistakable, statistically strong warming signal show <em>no</em> comparable
    signal in how much it rains. A dataset that manufactured trends would have
    produced one here too; this one does not.
  </p>
  <figure>
    <img src="data:image/png;base64,{{IMG_RAINC}}" alt="Monthly rainfall through the year at Toulouse-Blagnac, one line per year, with the long-term normal and the current year">
    <figcaption>
      Rain through the year: each grey line is one year&rsquo;s monthly totals,
      the dark line the long-term monthly normal, the bold blue line
      {{CUR_YEAR}} so far. {{WET_MONTH}} is the wettest month on average
      ({{WET_MONTH_MM}}&nbsp;mm), {{DRY_MONTH}} the driest
      ({{DRY_MONTH_MM}}&nbsp;mm) &mdash; but the spread between years dwarfs the
      seasonal cycle, which is exactly why no annual trend emerges.
    </figcaption>
  </figure>

  <h2>Methodology</h2>
  <ul class="meth">
    <li><strong>Source.</strong> M&eacute;t&eacute;o-France &mdash; daily climatological data
        (<code>RR-T-Vent</code> parameters), published on meteo.data.gouv.fr,
        department&nbsp;31 (Haute-Garonne). Full citation below.</li>
    <li><strong>Variables.</strong> Minimum&nbsp;=&nbsp;<code>TN</code>,
        maximum&nbsp;=&nbsp;<code>TX</code>, mean&nbsp;=&nbsp;<code>(TN+TX)/2</code>
        (field <code>TNTXM</code>), in&nbsp;&deg;C; rainfall&nbsp;=&nbsp;<code>RR</code>
        (daily precipitation, in&nbsp;mm).</li>
    <li><strong>Threshold days.</strong> Frost&nbsp;=&nbsp;<code>TN&nbsp;&lt;&nbsp;0</code>,
        hot&nbsp;day&nbsp;=&nbsp;<code>TX&nbsp;&ge;&nbsp;{{HOT_TX}}</code>,
        very&nbsp;hot&nbsp;=&nbsp;<code>TX&nbsp;&ge;&nbsp;{{VHOT_TX}}</code>,
        tropical&nbsp;night&nbsp;=&nbsp;<code>TN&nbsp;&ge;&nbsp;{{TROP_TX}}</code>,
        counted per complete year and averaged over the first/last complete decade.</li>
    <li><strong>Rainfall.</strong> Annual total of daily <code>RR</code> over complete
        years; the trend is a least-squares slope with its two-sided p-value.
        Monthly climatology keeps only months with&nbsp;&ge;&nbsp;27 valid days.</li>
    <li><strong>Annual aggregation.</strong> Arithmetic mean of daily values over each
        calendar year. The long-term trend uses only complete years (&ge;&nbsp;330 valid
        days). The in-progress year is shown separately &mdash; as a hollow
        &ldquo;to&nbsp;date&rdquo; marker on the trend chart, and (for a fair record
        comparison) against the same calendar window (Jan&nbsp;1&nbsp;&rarr;&nbsp;cutoff)
        of every prior year.</li>
    <li><strong>Daily climatology.</strong> Each year&rsquo;s daily mean is smoothed
        with a centred {{SMOOTH_WINDOW}}-day rolling mean (unweighted moving average,
        computed per year so December never bleeds into January; the first/last
        {{SMOOTH_HALF}} day(s) keep their raw value) for legibility; leap days are aligned
        across years. The normal is the per-day average over all prior years.</li>
    <li><strong>Trend.</strong> Slope estimated by linear regression (least squares);
        the line-chart curves use LOESS smoothing (span&nbsp;=&nbsp;0.7).</li>
    <li><strong>Reproducibility.</strong> A 4-stage R pipeline
        (<code>R/00_prepare_data.R</code> &rarr; <code>R/01_plot.R</code> &rarr;
        <code>R/02_report.R</code> &rarr; <code>R/03_readme.R</code>), driven by
        <code>make all</code> (R&nbsp;{{R_VERSION}}, ggplot2).</li>
  </ul>

  <h2>Data source &amp; citation</h2>
  <div class="src">
    M&eacute;t&eacute;o-France &mdash; <em>Donn&eacute;es climatologiques de base&nbsp;&ndash; quotidiennes</em>,
    department&nbsp;31 (Haute-Garonne), <code>RR-T-Vent</code> files.
    Published under the <em>Licence Ouverte / Open Licence (Etalab&nbsp;2.0)</em>
    on the M&eacute;t&eacute;o-France open-data portal:<br>
    <a href="https://meteo.data.gouv.fr/datasets/6569b51ae64326786e4e8e1a">https://meteo.data.gouv.fr/datasets/6569b51ae64326786e4e8e1a</a>
  </div>

  <footer>
    Data &copy; M&eacute;t&eacute;o-France, <em>Licence Ouverte / Open Licence (Etalab&nbsp;2.0)</em> &mdash;
    <a href="https://meteo.data.gouv.fr/datasets/6569b51ae64326786e4e8e1a">meteo.data.gouv.fr/datasets/6569b51ae64326786e4e8e1a</a>.<br>
    Analysis and charts built with R&nbsp;+&nbsp;ggplot2.
    Stations: Auzeville-Tolosane-INRAE (31035001) and Toulouse-Blagnac (31069001).
    Period covered: {{YR0}}&ndash;{{YR1}}.
  </footer>

</div>
</body>
</html>'

# ---- hot / cold year sentences ----------------------------------------------
both_sentence <- if (length(stats$both_years) == 0)
  "No single year managed to hit both extremes." else
  sprintf("Years hitting both extremes: %s.", paste(stats$both_years, collapse = ", "))

# These three clauses used to be frozen prose ("all of them recent", "all but one
# before 2000", "1947 and 1987"). They are now derived from the data every run, so
# a future record can never silently falsify them.
hot_recent_clause <- if (isTRUE(stats$hot_all_recent)) " &mdash; all of them recent &mdash;" else " &mdash;"
cold_era_clause   <- if (isTRUE(stats$cold_all_but_one)) ", all but one before 2000" else ""
raw_both_sentence <- if (length(stats$raw_both_years) == 0)
  "(On the raw, unsmoothed daily mean, no year touches both extremes.)" else
  sprintf("(If the threshold is applied instead to the raw, unsmoothed daily mean, %s %s touch both extremes.)",
          paste(stats$raw_both_years, collapse = " and "),
          if (length(stats$raw_both_years) == 1) "alone" else "each")

# ---- year-to-date sentence (record vs not) ----------------------------------
y <- stats$ytd
ytd_sentence <- if (isTRUE(y$is_record))
  sprintf(paste0("Measured like-for-like, <strong>%d is the warmest %s in %d years</strong> ",
                 "at Toulouse-Blagnac: <strong>%s&nbsp;&deg;C</strong> &mdash; +%s&nbsp;&deg;C above the ",
                 "previous record (%d, %s&nbsp;&deg;C) and <strong>+%s&nbsp;&deg;C above the long-term ",
                 "normal</strong> (%s&nbsp;&deg;C). This is exactly the point of the chart: ",
                 "a year still in progress can already stand out against the whole record."),
          stats$cur_year, y$window, y$n_years, fmt(y$cur, 1), fmt(y$cur - y$rec_val, 1),
          y$rec_year, fmt(y$rec_val, 1), fmt(y$cur_anom, 1), fmt(y$normal, 1)) else
  sprintf(paste0("Measured like-for-like over %s, %d currently ranks <strong>#%d of %d</strong> ",
                 "at Toulouse-Blagnac (%s&nbsp;&deg;C). The warmest such window on record remains ",
                 "%d (%s&nbsp;&deg;C)."),
          y$window, stats$cur_year, y$rank, y$n_years, fmt(y$cur, 1),
          y$rec_year, fmt(y$rec_val, 1))

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
  SMOOTH_WINDOW   = stats$smooth_window,
  SMOOTH_HALF     = (stats$smooth_window - 1) %/% 2,
  HOT_YEARS       = paste(stats$hot_years,  collapse = ", "),
  COLD_YEARS      = paste(stats$cold_years, collapse = ", "),
  BOTH_SENTENCE   = both_sentence,
  HOT_RECENT_CLAUSE = hot_recent_clause,
  COLD_ERA_CLAUSE   = cold_era_clause,
  RAW_BOTH_SENTENCE = raw_both_sentence,
  R_VERSION       = paste(R.version$major, R.version$minor, sep = "."),
  ROWS            = rows_html,
  RECORD_ROWS     = record_rows_html,
  IMG_SERIES      = img_series,
  IMG_CLIM        = img_clim,
  IMG_YTD         = img_ytd,
  IMG_RAIN        = img_rain,
  IMG_RAINC       = img_rainc,
  YTD_WINDOW      = stats$ytd$window,
  YTD_NORMAL      = fmt(stats$ytd$normal, 1),
  YTD_SENTENCE    = ytd_sentence,
  # extremes (threshold-day counts)
  EXT_SPAN0       = sprintf("%d&ndash;%d", stats$extremes$yr0, stats$extremes$yr0 + 9),
  EXT_SPAN1       = sprintf("%d&ndash;%d", stats$extremes$yr1 - 9, stats$extremes$yr1),
  HOT_TX          = stats$extremes$hot_thr,
  VHOT_TX         = stats$extremes$vhot_thr,
  TROP_TX         = stats$extremes$trop_thr,
  FROST_EARLY     = stats$extremes$frost_early,  FROST_RECENT = stats$extremes$frost_recent,
  HOT_EARLY       = stats$extremes$hot_early,    HOT_RECENT   = stats$extremes$hot_recent,
  VHOT_EARLY      = stats$extremes$vhot_early,   VHOT_RECENT  = stats$extremes$vhot_recent,
  TROP_EARLY      = stats$extremes$trop_early,   TROP_RECENT  = stats$extremes$trop_recent,
  # rainfall
  RAIN_YR0        = stats$rain$yr0,     RAIN_YR1 = stats$rain$yr1,
  RAIN_NYEARS     = stats$rain$n_years, RAIN_MEAN = stats$rain$mean_blag,
  RAIN_SLOPE      = sprintf("%+.0f", stats$rain$slope_dec),
  RAIN_P          = fmt(stats$rain$p, 2),
  WETTEST_YEAR    = stats$rain$wettest_year, WETTEST_MM = stats$rain$wettest_mm,
  DRIEST_YEAR     = stats$rain$driest_year,  DRIEST_MM  = stats$rain$driest_mm,
  WET_MONTH       = stats$rain$wet_month, WET_MONTH_MM = stats$rain$wet_month_mm,
  DRY_MONTH       = stats$rain$dry_month, DRY_MONTH_MM = stats$rain$dry_month_mm
)

html <- template
for (key in names(fills)) {
  html <- gsub(paste0("{{", key, "}}"), fills[[key]], html, fixed = TRUE)
}

# safety: warn if any placeholder went unfilled
leftover <- regmatches(html, gregexpr("\\{\\{[A-Z_0-9]+\\}\\}", html))[[1]]
if (length(leftover) > 0)
  warning("Unfilled placeholders: ", paste(unique(leftover), collapse = ", "))

out <- file.path(PATHS$outputs, "temperature_report.html")
writeLines(html, out)
cat(sprintf("Wrote %s (%.0f KB)\n", out, file.size(out) / 1024))
