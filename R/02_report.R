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
annual_csv <- file.path(PATHS$outputs, "annual_temperatures.csv")
stats_rds  <- file.path(PATHS$processed, "trend_stats.rds")

stopifnot(file.exists(fig_series), file.exists(fig_clim),
          file.exists(annual_csv), file.exists(stats_rds))

img_series <- base64encode(fig_series)
img_clim   <- base64encode(fig_clim)
stats      <- readRDS(stats_rds)
annual     <- fread(annual_csv)

blag <- annual[station == "Toulouse-Blagnac"]

recent <- blag[year >= stats$yr1 - 9,
               .(year, TN = round(TN, 1), TX = round(TX, 1), Mean = round(TMEAN, 1))]
rows_html <- paste(sprintf(
  "<tr><td>%d</td><td>%.1f</td><td>%.1f</td><td><strong>%.1f</strong></td></tr>",
  recent$year, recent$TN, recent$TX, recent$Mean), collapse = "\n")

fmt <- function(x, d = 2) formatC(x, format = "f", digits = d)
early_decade <- (stats$yr0 %/% 10) * 10

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
      <div class="lab">mean of the last decade<br>(vs {{MEAN_EARLY}}&nbsp;&deg;C in the {{EARLY_DECADE}}s)</div></div>
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
    {{AUZ_YR0}}&rarr;{{AUZ_YR1}} but shows a consistent slope (+{{SLOPE_DEC_AUZ}}&nbsp;&deg;C/decade) and sits almost exactly
    on the regional mean: the local and regional signals are the same.
  </p>

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
    ({{HOT_YEARS}}) &mdash; all of them recent &mdash; while <strong>{{N_COLD}}</strong> years
    dropped below {{COLD_THR}}&nbsp;&deg;C ({{COLD_YEARS}}), all but one before 2000.
    <strong>{{BOTH_SENTENCE}}</strong> The hot extremes and the cold extremes fall in
    different eras, which is itself a fingerprint of the warming trend.
    <span style="color:#8A97A0;">(If the threshold is applied instead to the raw,
    unsmoothed daily mean, 1947 and 1987 each touch both extremes.)</span>
  </div>

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

  <h2>Methodology</h2>
  <ul class="meth">
    <li><strong>Source.</strong> M&eacute;t&eacute;o-France &mdash; daily climatological data
        (<code>RR-T-Vent</code> parameters), published on meteo.data.gouv.fr,
        department&nbsp;31 (Haute-Garonne). Full citation below.</li>
    <li><strong>Variables.</strong> Minimum&nbsp;=&nbsp;<code>TN</code>,
        maximum&nbsp;=&nbsp;<code>TX</code>, mean&nbsp;=&nbsp;<code>(TN+TX)/2</code>
        (field <code>TNTXM</code>), in&nbsp;&deg;C.</li>
    <li><strong>Annual aggregation.</strong> Arithmetic mean of daily values over each
        calendar year. Years with fewer than 330 valid days (including the current,
        partial year) are excluded to avoid seasonal bias.</li>
    <li><strong>Daily climatology.</strong> Each year&rsquo;s daily mean is smoothed
        with a centred {{SMOOTH_WINDOW}}-day rolling mean (unweighted moving average,
        computed per year so December never bleeds into January; the first/last
        {{SMOOTH_HALF}} day(s) keep their raw value) for legibility; leap days are aligned
        across years. The normal is the per-day average over all prior years.</li>
    <li><strong>Trend.</strong> Slope estimated by linear regression (least squares);
        the line-chart curves use LOESS smoothing (span&nbsp;=&nbsp;0.7).</li>
    <li><strong>Reproducibility.</strong> A 3-stage R pipeline
        (<code>R/00_prepare_data.R</code> &rarr; <code>R/01_plot.R</code> &rarr;
        <code>R/02_report.R</code>), driven by <code>make all</code> (R&nbsp;{{R_VERSION}}, ggplot2).</li>
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

# ---- fill placeholders (single gsub pass, no length limit) ------------------
fills <- c(
  YR0             = stats$yr0,
  YR1             = stats$yr1,
  NYEARS          = stats$yr1 - stats$yr0,
  SLOPE_DEC       = fmt(stats$slope_dec_blag),
  SLOPE_DEC_AUZ   = fmt(stats$slope_dec_auz),
  RISE            = fmt(stats$rise_blag, 1),
  MEAN_RECENT     = fmt(stats$mean_recent, 1),
  MEAN_EARLY      = fmt(stats$mean_early, 1),
  EARLY_DECADE    = early_decade,
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
  R_VERSION       = paste(R.version$major, R.version$minor, sep = "."),
  ROWS            = rows_html,
  IMG_SERIES      = img_series,
  IMG_CLIM        = img_clim
)

html <- template
for (key in names(fills)) {
  html <- gsub(paste0("{{", key, "}}"), fills[[key]], html, fixed = TRUE)
}

# safety: warn if any placeholder went unfilled
leftover <- regmatches(html, gregexpr("\\{\\{[A-Z_]+\\}\\}", html))[[1]]
if (length(leftover) > 0)
  warning("Unfilled placeholders: ", paste(unique(leftover), collapse = ", "))

out <- file.path(PATHS$outputs, "temperature_report.html")
writeLines(html, out)
cat(sprintf("Wrote %s (%.0f KB)\n", out, file.size(out) / 1024))
