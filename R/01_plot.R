#!/usr/bin/env Rscript
# =============================================================================
# Stage 01 — build the figures (generic across sites; SITE env var selects one)
# Reads the processed daily CSVs and produces:
#   * <figures>/temperature_series.png      — annual series, first->current
#   * <figures>/temperature_climatology.png — every year day-by-day
#   * <figures>/temperature_ytd.png         — year-to-date race
#   * <figures>/rain_series.png             — annual rainfall totals
#   * <figures>/rain_climatology.png        — monthly rainfall seasonal cycle
#   * <outputs>/annual_temperatures.csv     — the annual table
#   * <outputs>/annual_rainfall.csv         — annual rainfall totals
#   * <processed>/trend_stats.rds           — numbers reused by the report
# =============================================================================

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(scales)
  library(ragg)
})

source("R/lib/common.R")
source("R/lib/narrative.R")
site_key <- Sys.getenv("SITE", "castanet")
source(sprintf("R/sites/%s.R", site_key))   # defines SITE

PATHS <- SITE$paths
STATIONS <- SITE$stations
CLIMATOLOGY_STATION <- SITE$reference_station
# A site may have no second station at all (Moscow/Voronezh: a single WMO
# index, manually exported from AISORI-M) — distinct from local_has_temp =
# FALSE, which still implies a real rain-only local station.
HAS_LOCAL <- !is.null(SITE$local_station)
dir.create(PATHS$figures, recursive = TRUE, showWarnings = FALSE)

# ---- read the small gzipped station extract produced by stage 00 ------------
extract_gz <- file.path(PATHS$processed, STATION_EXTRACT)
if (!file.exists(extract_gz))
  stop("Missing ", extract_gz, " — run stage 00 first (SITE=", site_key, " make prepare).")

dat <- read_gz(extract_gz, colClasses = list(character = "NUM_POSTE"))
dat[, station := factor(STATIONS[NUM_POSTE], levels = STATIONS)]
dat[, year  := AAAAMMJJ %/% 10000L]
dat[, month := (AAAAMMJJ %/% 100L) %% 100L]
dat[, day   := AAAAMMJJ %% 100L]

message(sprintf("Loaded %d daily rows for %d stations (%d..%d).",
                nrow(dat), uniqueN(dat$station), min(dat$year), max(dat$year)))

# =============================================================================
# PLOT 1 — annual means, first available year -> current year
# =============================================================================

annual_all <- dat[, .(
  n_tn = sum(!is.na(TN)),
  n_tx = sum(!is.na(TX)),
  n_tm = sum(!is.na(TNTXM)),
  TN    = mean(TN,    na.rm = TRUE),
  TX    = mean(TX,    na.rm = TRUE),
  TMEAN = mean(TNTXM, na.rm = TRUE)
), by = .(station, year)]

annual_all[, complete := n_tn >= MIN_DAYS & n_tx >= MIN_DAYS & n_tm >= MIN_DAYS]
setorder(annual_all, station, year)

# The in-progress (usually partial) year, e.g. 2026 — defined ONCE here, from the
# full extract, and used by all three figures and the report. Do not recompute it
# from a station subset: if one station's feed ran ahead of another's, the figures
# and the report prose would silently disagree about which year is "current".
cur_year <- max(dat$year)

# Complete years drive the trend, lines, LOESS and all long-term stats — a partial
# year's mean is seasonally biased (missing the warm late-summer tail) and must not
# enter the annual trend.
annual <- annual_all[complete == TRUE]

# The annual TABLE, however, keeps every complete year PLUS the in-progress year
# (flagged via `complete`), so a record-breaking year in progress stays visible.
# Its true, like-for-like standing is shown by the year-to-date figure below.
annual_out <- annual_all[complete == TRUE | year == cur_year]
fwrite(annual_out, file.path(PATHS$outputs, "annual_temperatures.csv"))
message(sprintf("Annual table: %d complete station-years (%d..%d)%s.",
                nrow(annual), min(annual$year), max(annual$year),
                if (any(!annual_out$complete))
                  sprintf(" + %d partial (in progress)", sum(!annual_out$complete)) else ""))

ref   <- annual[station == SITE$reference_station]
local <- if (SITE$local_has_temp) annual[station == SITE$local_station] else annual[0]

# current partial-year row (for the hollow "to date" marker on plot 1)
ref_cur <- annual_all[station == SITE$reference_station & year == cur_year & complete == FALSE]

# Whether `cur_year` is a genuinely in-progress partial year (every site so far
# except Moscow, whose manual export's last year, 2025, is already complete —
# nrow(ref_cur) == 0 means no incomplete row exists for it). Prose that says
# "so far" / "still in progress" / draws a hollow to-date marker must check
# this rather than assume it, the way every site up to now allowed it to.
YEAR_COMPLETE <- nrow(ref_cur) == 0

L_TX   <- sprintf("%s — daily maximum (TX)", SITE$reference_station)
L_MEAN <- sprintf("%s — daily mean",         SITE$reference_station)
L_TN   <- sprintf("%s — daily minimum (TN)", SITE$reference_station)
series_levels <- c(L_TX, L_MEAN, L_TN)
pal <- c(COL$tx, COL$mean, COL$tn)
shp <- c(16, 16, 16)

mk <- function(d, col, label) data.table(year = d$year, value = d[[col]], series = label)
plotdat_list <- list(mk(ref, "TX", L_TX), mk(ref, "TMEAN", L_MEAN), mk(ref, "TN", L_TN))

if (SITE$local_has_temp) {
  L_LOCAL <- sprintf("%s — mean", SITE$local_station)
  series_levels <- c(series_levels, L_LOCAL)
  plotdat_list  <- c(plotdat_list, list(mk(local, "TMEAN", L_LOCAL)))
  pal <- c(pal, COL$auz)
  shp <- c(shp, 18)
}
names(pal) <- series_levels
names(shp) <- series_levels

plotdat <- rbindlist(plotdat_list)
plotdat[, series := factor(series, levels = series_levels)]

# ---- linear-trend statistics ------------------------------------------------
fit_ref <- lm(TMEAN ~ year, data = ref)
slope_dec_ref <- unname(coef(fit_ref)[2]) * 10
yr0 <- min(ref$year); yr1 <- max(ref$year)
rise_ref <- unname(coef(fit_ref)[2]) * (yr1 - yr0)
n_years_ref <- nrow(ref)   # COMPLETE years, not the yr1-yr0 span

# Slope over the window every site shares (COMMON_YR0, R/lib/common.R), so the
# cross-site comparison can show a like-for-like rate beside each city's own.
# Without it the ranked chart reads as a speed ranking when much of its middle
# is really record length: Zurich and Karlsruhe each gain 3 places on the common
# window, Honolulu and Nouméa each lose 3.
ref_common <- ref[year >= COMMON_YR0]
slope_dec_ref_common <- if (nrow(ref_common) >= 20)
  unname(coef(lm(TMEAN ~ year, data = ref_common))[2]) * 10 else NA_real_

# Separate TN and TX trends. A station whose nights cool while its days warm is
# showing a widening diurnal range, which is the opposite of the greenhouse
# signature and a standard red flag for station-history artifacts (site moves,
# observation-time drift) in an unadjusted record. Computed, not asserted, so
# the caveat in R/lib/narrative.R fires only where the data actually shows it.
slope_dec_tn <- unname(coef(lm(TN ~ year, data = ref))[2]) * 10
slope_dec_tx <- unname(coef(lm(TX ~ year, data = ref))[2]) * 10
dtr_early <- mean(ref[year <= yr0 + 9]$TX - ref[year <= yr0 + 9]$TN)
dtr_recent <- mean(ref[year >= yr1 - 9]$TX - ref[year >= yr1 - 9]$TN)

if (SITE$local_has_temp) {
  fit_local <- lm(TMEAN ~ year, data = local)
  slope_dec_local <- unname(coef(fit_local)[2]) * 10

  # Reference station's slope over the SAME window as the local station — so the
  # two local/regional slopes are compared like-for-like (recent decades warm
  # faster, so this is the honest number to set beside the local one, not the
  # whole-period slope).
  local_span <- range(local$year)
  slope_dec_ref_localwin <- unname(
    coef(lm(TMEAN ~ year, data = ref[year >= local_span[1] & year <= local_span[2]]))[2]) * 10
  local_yr0 <- local_span[1]; local_yr1 <- local_span[2]
} else {
  slope_dec_local <- NA_real_
  slope_dec_ref_localwin <- NA_real_
  local_yr0 <- NA_integer_; local_yr1 <- NA_integer_
}

trend_txt <- sprintf(
  "%s, annual mean temperature\n+%.2f °C / decade  ·  +%.1f °C over %d years (%d–%d)",
  SITE$reference_station, slope_dec_ref, rise_ref, yr1 - yr0, yr0, yr1)

x_breaks <- seq(1860, 2030, by = 10)

stations_line_temp <- if (SITE$local_has_temp)
  sprintf("Stations: %s (%s) and %s (%s, long-term reference).",
          SITE$local_station, station_id(SITE, SITE$local_station),
          SITE$reference_station, station_id(SITE, SITE$reference_station)) else
  sprintf("Station: %s (%s, long-term reference).",
          SITE$reference_station, station_id(SITE, SITE$reference_station))

p1 <- ggplot() +
  geom_ribbon(data = ref, aes(year, ymin = TN, ymax = TX),
              fill = COL$tx, alpha = 0.05) +
  geom_line(data = plotdat, aes(year, value, colour = series, group = series),
            alpha = 0.28, linewidth = 0.4) +
  geom_point(data = plotdat, aes(year, value, colour = series, shape = series),
             size = 1.5, alpha = 0.85) +
  geom_smooth(data = plotdat, aes(year, value, colour = series, group = series),
              method = "loess", formula = y ~ x, se = FALSE,
              linewidth = 1.3, span = 0.7) +
  annotate("label", x = yr0 + 0.5, y = max(ref$TX) + 1.2,
           label = trend_txt, hjust = 0, vjust = 1,
           size = 3.2, colour = "#3D4A54", lineheight = 0.98, fontface = "italic",
           fill = "white", alpha = 0.7, label.padding = unit(0.4, "lines")) +
  scale_colour_manual(values = pal, name = NULL, breaks = series_levels) +
  scale_shape_manual(values = shp, name = NULL, breaks = series_levels) +
  scale_x_continuous(breaks = x_breaks, limits = c(yr0, max(yr1, cur_year)),
                     expand = expansion(mult = c(0.01, 0.04))) +
  scale_y_continuous(breaks = seq(-15, 30, 2),
                     limits = c(min(ref$TN) - 0.5, max(ref$TX) + 1.6),
                     labels = deg_label) +
  guides(colour = guide_legend(nrow = 2, byrow = TRUE,
                               override.aes = list(alpha = 1, linewidth = 1.4)),
         shape = guide_legend(nrow = 2, byrow = TRUE)) +
  labs(
    title = sprintf("Temperatures around %s (%s, %s)", SITE$city, SITE$region, SITE$country),
    subtitle = sprintf("Annual means of daily temperatures, %d → %d  ·  a clear and continuous warming",
                       yr0, yr1),
    x = NULL, y = NULL,
    caption = paste0(
      caption_source_line(SITE$citation), "\n",
      "Min = TN, Max = TX, Mean = (TN+TX)/2.  ", stations_line_temp, "\n",
      sprintf("Incomplete years (< %d days) excluded. Curves: LOESS smoothing.", MIN_DAYS)
    )
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title    = element_text(face = "bold", size = 17, colour = "#1A2530"),
    plot.subtitle = element_text(size = 12, colour = "#566573", margin = margin(b = 12)),
    plot.caption  = element_text(size = 8, colour = "#7F8C8D", hjust = 0,
                                 margin = margin(t = 14), lineheight = 1.05),
    plot.caption.position = "plot", plot.title.position = "plot",
    legend.position = "bottom", legend.text = element_text(size = 10),
    legend.key.width = unit(1.6, "lines"),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(colour = "#ECEFF1", linewidth = 0.4),
    axis.text = element_text(colour = "#566573"),
    plot.margin = margin(18, 22, 12, 18),
    plot.background = element_rect(fill = "white", colour = NA)
  )

# current, in-progress year: a hollow "to date" marker (Jan 1 -> latest day), kept
# visually distinct because a partial-year mean is NOT comparable to full years —
# its true, like-for-like standing is the year-to-date figure. Drawn in the
# "current year" red used for the climatology, so the eye links the two charts.
if (nrow(ref_cur)) {
  p1 <- p1 +
    geom_point(data = ref_cur, aes(year, TMEAN),
               shape = 23, size = 3, fill = "white", colour = COL$tx, stroke = 1.2) +
    annotate("text", x = ref_cur$year, y = ref_cur$TMEAN - 0.75,
             label = sprintf("%d\nto date", cur_year),
             colour = COL$tx, size = 3, fontface = "italic",
             hjust = 0.7, vjust = 1, lineheight = 0.95)
}

agg_png(file.path(PATHS$figures, "temperature_series.png"),
        width = 2400, height = 1400, res = 200, background = "white")
print(p1); invisible(dev.off())
message("Wrote temperature_series.png")

# =============================================================================
# PLOT 2 — daily climatology "spaghetti": one line per year (Jan->Dec),
#          current year drawn bold, long-term daily normal as reference
# =============================================================================

clim <- dat[station == CLIMATOLOGY_STATION & !is.na(TNTXM)]
clim[, leap := (year %% 4 == 0 & (year %% 100 != 0 | year %% 400 == 0))]
clim[, doy := as.integer(strftime(as.Date(sprintf("%04d-%02d-%02d", year, month, day)), "%j"))]
# align Feb-29 slot: shift non-leap years' days from Mar 1 (doy>=60) up by 1
clim[leap == FALSE & doy >= 60, doy := doy + 1L]
clim[, tmean := TNTXM]

setorder(clim, year, doy)
clim[, tsmooth := frollmean(tmean, SMOOTH_WINDOW, align = "center", na.rm = TRUE), by = year]
clim[is.na(tsmooth), tsmooth := tmean]

# cur_year comes from the top of the script (all stations). The climatology station
# should reach the same year; if its feed lags behind the other station's, stop
# rather than draw an empty "current year" line.
if (max(clim$year) != cur_year)
  stop(sprintf("%s data ends in %d but the extract reaches %d — refresh the raw files (make prepare).",
               CLIMATOLOGY_STATION, max(clim$year), cur_year))

# `cur_year` is excluded from "previous years" for every site EXCEPT the one
# whose cur_year is already a complete, finished calendar year (Moscow's manual
# export, 2025) — for that site, excluding it dropped a real complete year from
# the hot/cold-year classification, the climatology date range and the
# long-term normal. It is still drawn separately, bold, as `this_year` either
# way; for YEAR_COMPLETE sites it therefore also appears once, thin, inside
# `prev_years` — invisible, since the bold trace is drawn on top of it.
prev_years <- if (YEAR_COMPLETE) clim[year <= cur_year] else clim[year < cur_year]
this_year  <- clim[year == cur_year]

normal <- prev_years[, .(tnorm = mean(tsmooth, na.rm = TRUE)), by = doy]
setorder(normal, doy)

month_starts <- c(1, 32, 61, 92, 122, 153, 183, 214, 245, 275, 306, 336)
month_labs   <- month.abb
n_years <- uniqueN(prev_years$year)

# ---- classify each PAST year by whether its smoothed daily-mean curve --------
# crosses the +30 °C ("hot") or -5 °C ("cold") line that the chart actually draws
HOT_THR  <-  30
COLD_THR <- -5
yr_ext <- prev_years[, .(ymax = max(tsmooth, na.rm = TRUE),
                         ymin = min(tsmooth, na.rm = TRUE)), by = year]
hot_years  <- sort(yr_ext[ymax > HOT_THR,  year])
cold_years <- sort(yr_ext[ymin < COLD_THR, year])
both_years <- intersect(hot_years, cold_years)
message(sprintf("Hot years (>%d°C): %s", HOT_THR, paste(hot_years, collapse=", ")))
message(sprintf("Cold years (<%d°C): %s", COLD_THR, paste(cold_years, collapse=", ")))
message(sprintf("Years doing BOTH: %s",
                if (length(both_years)) paste(both_years, collapse=", ") else "none"))

# Same thresholds on the RAW (unsmoothed) daily mean — a few volatile early years
# cross both lines once the smoothing is removed. Computed, not hard-coded, so the
# report's footnote can never drift from the data.
raw_ext <- prev_years[, .(ymax = max(tmean, na.rm = TRUE),
                          ymin = min(tmean, na.rm = TRUE)), by = year]
raw_both_years <- sort(intersect(raw_ext[ymax > HOT_THR, year],
                                  raw_ext[ymin < COLD_THR, year]))
# Flags behind the two hand-written clauses, so they self-check on every run.
hot_all_recent   <- length(hot_years)  > 0 && min(hot_years) >= 2000
cold_all_but_one <- length(cold_years) > 1 && sum(cold_years >= 2000) <= 1

hot_lines  <- prev_years[year %in% hot_years]
cold_lines <- prev_years[year %in% cold_years]

# label anchors: each hot year at its own peak; each cold year at its own trough
hot_lab <- hot_lines[, .SD[which.max(tsmooth)], by = year][, .(year, doy, tsmooth)]
cold_lab <- cold_lines[, .SD[which.min(tsmooth)], by = year][, .(year, doy, tsmooth)]

COL_HOT  <- "#C0392B"
COL_COLD <- "#1F5FA8"

both_txt <- if (length(both_years) == 0) "No year did both." else
  sprintf("Year(s) doing both: %s.", paste(both_years, collapse = ", "))

p2 <- ggplot() +
  # one line per past year — pronounced enough to read the spread, still subordinate to the current year
  geom_line(data = prev_years, aes(doy, tsmooth, group = year),
            colour = COL$spaghetti, alpha = 0.22, linewidth = 0.35) +
  # reference threshold lines
  geom_hline(yintercept = HOT_THR,  colour = COL_HOT,  linewidth = 0.35,
             linetype = "dashed", alpha = 0.55) +
  geom_hline(yintercept = COLD_THR, colour = COL_COLD, linewidth = 0.35,
             linetype = "dashed", alpha = 0.55) +
  # highlight: years that ever exceeded +30 °C (thin red) and below -5 °C (thin blue)
  geom_line(data = cold_lines, aes(doy, tsmooth, group = year),
            colour = COL_COLD, linewidth = 0.32, alpha = 0.55) +
  geom_line(data = hot_lines, aes(doy, tsmooth, group = year),
            colour = COL_HOT, linewidth = 0.32, alpha = 0.55) +
  # year labels (repelled to avoid overlap)
  ggrepel::geom_text_repel(
    data = cold_lab, aes(doy, tsmooth, label = year),
    colour = COL_COLD, size = 2.7, fontface = "bold",
    direction = "y", nudge_y = -1.6, segment.size = 0.2,
    segment.colour = COL_COLD, segment.alpha = 0.5, min.segment.length = 0,
    box.padding = 0.18, max.overlaps = Inf, seed = 1) +
  ggrepel::geom_text_repel(
    data = hot_lab, aes(doy, tsmooth, label = year),
    colour = COL_HOT, size = 2.7, fontface = "bold",
    direction = "y", nudge_y = 1.6, segment.size = 0.2,
    segment.colour = COL_HOT, segment.alpha = 0.5, min.segment.length = 0,
    box.padding = 0.18, max.overlaps = Inf, seed = 1) +
  # long-term daily normal
  geom_line(data = normal, aes(doy, tnorm),
            colour = COL$normal, linewidth = 1.0, alpha = 0.95) +
  # current year, bold
  geom_line(data = this_year, aes(doy, tsmooth),
            colour = COL$tx, linewidth = 1.6) +
  annotate("text", x = max(this_year$doy) + 3, y = tail(this_year$tsmooth, 1),
           label = as.character(cur_year), hjust = 0, vjust = 0.5,
           colour = COL$tx, fontface = "bold", size = 4) +
  scale_x_continuous(breaks = month_starts, labels = month_labs,
                     expand = expansion(mult = c(0.01, 0.05))) +
  scale_y_continuous(breaks = seq(-10, 40, 5), labels = deg_label) +
  labs(
    title = sprintf("Every year, day by day — %s", CLIMATOLOGY_STATION),
    subtitle = sprintf(
      "Daily mean temperature, %d–%d (%d years), smoothed with a centred %d-day rolling mean.  Bold red = %d so far; dark line = long-term normal.\nYears whose smoothed daily mean ever rose above +30 °C are drawn red; those that ever fell below −5 °C, blue.  %s",
      min(prev_years$year), max(prev_years$year), n_years, SMOOTH_WINDOW, cur_year, both_txt),
    x = NULL, y = NULL,
    caption = paste0(
      caption_source_line(SITE$citation), "\n",
      sprintf("Station: %s (%s).  ", SITE$reference_station, station_id(SITE, SITE$reference_station)),
      sprintf("Daily mean = (TN+TX)/2, smoothed with a centred %d-day rolling mean; thresholds apply to this smoothed daily mean.  Leap days aligned across years.", SMOOTH_WINDOW)
    )
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title    = element_text(face = "bold", size = 17, colour = "#1A2530"),
    plot.subtitle = element_text(size = 11, colour = "#566573", margin = margin(b = 12)),
    plot.caption  = element_text(size = 8, colour = "#7F8C8D", hjust = 0,
                                 margin = margin(t = 14), lineheight = 1.05),
    plot.caption.position = "plot", plot.title.position = "plot",
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_line(colour = "#EDF0F2", linewidth = 0.4),
    panel.grid.major.y = element_line(colour = "#ECEFF1", linewidth = 0.4),
    axis.text = element_text(colour = "#566573"),
    plot.margin = margin(18, 22, 12, 18),
    plot.background = element_rect(fill = "white", colour = NA)
  )

agg_png(file.path(PATHS$figures, "temperature_climatology.png"),
        width = 2400, height = 1250, res = 200, background = "white")
print(p2); invisible(dev.off())
message("Wrote temperature_climatology.png")

# =============================================================================
# PLOT 3 — the year so far vs the SAME window of every year (year-to-date race)
# The only fair way to place an in-progress year against history: compare each
# year over the identical calendar window (Jan 1 -> the current year's last day).
# =============================================================================

refd <- dat[station == CLIMATOLOGY_STATION & !is.na(TNTXM)]
cutM <- max(refd[year == cur_year]$month)
cutD <- max(refd[year == cur_year & month == cutM]$day)
in_window <- function(m, d) (m < cutM) | (m == cutM & d <= cutD)
win_lab  <- sprintf("Jan 1 – %s %d", month.abb[cutM], cutD)   # e.g. "Jan 1 – Jul 9"

# MIN_YTD_DAYS (150) was picked assuming a typical cutoff deep in the year
# (the six original sites all cut off in July/August, ~200+ days in) — a
# fixed floor of "150 real days," full stop. For a site whose current year
# stops much earlier (Voronezh's 2026 export ends 2026-02-28 — a 59-day
# window), 150 is unreachable by ANY year, not just the current one, which
# would empty `ytd` entirely. Scale the floor to the window itself (never
# ABOVE 150, so every already-shipped site is unaffected: their windows are
# all well over 150/0.85 days long).
cutoff_doy <- as.integer(strftime(as.Date(sprintf("2001-%02d-%02d", cutM, cutD)), "%j"))
YTD_MIN_DAYS <- min(MIN_YTD_DAYS, floor(0.85 * cutoff_doy))

# A year also has to COVER the window, not merely have enough days somewhere
# inside it — see MIN_YTD_MONTH_FRAC in R/lib/common.R for the Albuquerque 1931
# case this rejects. Coverage is measured per calendar month against the days
# the window actually contains, since the cutoff month is partial by definition.
# (Feb is counted as 28 days, so a leap year reads slightly over 100% — harmless.)
MONTH_LEN <- c(31L, 28L, 31L, 30L, 31L, 30L, 31L, 31L, 30L, 31L, 30L, 31L)
win_ref <- data.table(month = rep(1:12, times = MONTH_LEN),
                      day   = unlist(lapply(MONTH_LEN, seq_len)))
win_ref <- win_ref[in_window(month, day)]
win_month_len <- win_ref[, .(win_len = .N), by = month]

cover <- refd[in_window(month, day), .(nd = .N), by = .(year, month)]
cover <- merge(cover, win_month_len, by = "month")
# A month absent entirely is absent from `cover`, so the count test catches it.
spread <- cover[, .(covered_months = .N, min_frac = min(nd / win_len)), by = year]
spread_ok <- spread[covered_months == nrow(win_month_len) &
                      min_frac >= MIN_YTD_MONTH_FRAC]$year

ytd_all <- refd[in_window(month, day), .(ytd = mean(TNTXM), n = .N), by = year]
ytd <- ytd_all[n >= YTD_MIN_DAYS & year %in% spread_ok]
dropped <- setdiff(ytd_all[n >= YTD_MIN_DAYS]$year, ytd$year)
if (length(dropped))
  message(sprintf("  YTD: dropped %s — enough days, but not spread across %s",
                  paste(dropped, collapse = ", "), win_lab))
setorder(ytd, year)
ytd[, is_cur := year == cur_year]

if (nrow(ytd) == 0)
  stop(sprintf(paste0("YTD window (%s) has no year — including the current one — with >= %d ",
                       "valid days; %s's data may have real gaps even within this short window. ",
                       "Not something to render around silently — investigate the source data."),
               win_lab, YTD_MIN_DAYS, CLIMATOLOGY_STATION))

# Even the scaled floor above can leave `ytd` without the current year (e.g.
# real gaps in its own window) — degrade to "too early to rank" rather than
# crash on a current year absent from `ytd`.
HAS_YTD <- cur_year %in% ytd$year

if (HAS_YTD) {
  cur_ytd  <- ytd[year == cur_year]$ytd
  best_oth <- ytd[year != cur_year][order(-ytd)][1]   # warmest of all OTHER years
  ytd_rank <- match(cur_year, ytd[order(-ytd)]$year)
  delta    <- cur_ytd - best_oth$ytd                  # + if the current year is the record
  is_record <- ytd_rank == 1L

  message(sprintf("YTD (%s): %d = %.2f°C, rank %d/%d%s",
                  win_lab, cur_year, cur_ytd, ytd_rank, nrow(ytd),
                  if (is_record) sprintf(" — RECORD, +%.2f°C over %d", delta, best_oth$year) else
                    sprintf(" — record held by %d (%.2f°C)", best_oth$year, best_oth$ytd)))
} else {
  cur_ytd   <- NA_real_
  best_oth  <- ytd[order(-ytd)][1]   # still the record holder among the years that DO qualify
  ytd_rank  <- NA_integer_
  delta     <- NA_real_
  is_record <- FALSE
  n_window_days <- nrow(refd[year == cur_year][in_window(month, day)])

  message(sprintf("YTD (%s): %d has only %d valid day(s) in this window (< %d) — too early to rank.",
                  win_lab, cur_year, n_window_days, YTD_MIN_DAYS))
}

# each year's window mean as a DEPARTURE from the long-term (prior-years) normal —
# blue below, red above; the warming shows as the swing from blue to red, and the
# current year stands out as the tallest bar (no floating point, real time axis).
normal   <- mean(ytd[year != cur_year]$ytd)
ytd[, anom := ytd - normal]
cur_anom <- if (HAS_YTD) ytd[year == cur_year]$anom else NA_real_
delta_disp <- round(cur_ytd, 1) - round(best_oth$ytd, 1)   # matches the report's rounding
norm_yr1 <- max(ytd[is_cur == FALSE]$year)

# Display-only roundings — deg_label() has no digits control (unlike the old
# "%.1f" sprintf it replaces below), so unrounded floats would otherwise bake
# into the chart as e.g. "+2.446988 °C" instead of "+2.4 °C". cur_anom itself
# stays unrounded where used for bar/label y-position.
cur_anom_disp  <- round(cur_anom, 1)
best_oth_disp  <- round(best_oth$ytd, 1)

# Title/subtitle must branch on is_record: an in-progress year is not always the
# warmest on record (e.g. Karlsruhe 2026 ranks #2, behind 2007) — a hard-coded
# "is the warmest on record" + unconditional "+" sign previously printed a false
# record claim and a garbled "+-0.3 °C" whenever the current year fell short.
# A THIRD case — too little of the current year recorded yet to rank at all
# (HAS_YTD == FALSE) — must come first, since is_record/cur_anom_disp/etc. are
# NA in that case and would otherwise print "NA °C".
title_txt <- if (!HAS_YTD)
  sprintf("Too early in %d to compare — %s", cur_year, CLIMATOLOGY_STATION) else
  if (is_record)
  sprintf("The year so far, warmer than any before it — %s", CLIMATOLOGY_STATION) else
  sprintf("The year so far, among the warmest on record — %s", CLIMATOLOGY_STATION)

subtitle_lead <- if (!HAS_YTD)
  sprintf("Only %d day(s) of %d recorded in this data so far — short of the %d needed for a fair like-for-like comparison against history. Check back once more of the year is recorded.",
          n_window_days, cur_year, YTD_MIN_DAYS) else
  if (is_record)
  sprintf("%d is the warmest such period on record: %s above normal, %s over the previous record (%d).",
          cur_year, deg_label(cur_anom_disp, signed = TRUE), deg_label(delta_disp, signed = TRUE), best_oth$year) else
  sprintf("%d ranks #%d of %d for this period: %s above normal, %s behind the record (%d, %s).",
          cur_year, ytd_rank, nrow(ytd), deg_label(cur_anom_disp, signed = TRUE), deg_label(abs(delta_disp)),
          best_oth$year, deg_label(best_oth_disp))

p3 <- ggplot(ytd, aes(year, anom, fill = anom > 0)) +
  geom_col(width = 0.72, alpha = 0.85) +
  geom_hline(yintercept = 0, colour = "#8A97A0", linewidth = 0.4)

# Current-year highlight bar + label only when it actually qualifies (HAS_YTD)
# — otherwise `ytd[is_cur == TRUE]` is empty and cur_anom is NA, so there is
# nothing honest to highlight yet.
if (HAS_YTD) {
  # Every OTHER bar's colour follows its own sign (scale_fill_manual below); the
  # current-year highlight must too — it was previously hardcoded red regardless
  # of sign, which drew a below-normal current year (Voronezh, 2026: -0.9 °C) in
  # the "warmer than normal" colour, directly contradicting the chart's own
  # "Red = warmer, blue = cooler" legend.
  cur_below   <- isTRUE(cur_anom <= 0)
  cur_fill    <- if (cur_below) COL$tn else COL$tx
  cur_border  <- if (cur_below) "#154360" else "#7B241C"
  cur_vjust   <- if (cur_below) 1.35 else -0.35   # label sits just outside the bar's tip either way
  p3 <- p3 +
    geom_col(data = ytd[is_cur == TRUE], aes(year, anom),
             fill = cur_fill, colour = cur_border, linewidth = 0.4, width = 0.92) +
    annotate("text", x = cur_year, y = cur_anom, vjust = cur_vjust, hjust = 0.65,
             label = sprintf("%d\n%s", cur_year, deg_label(cur_anom_disp, signed = TRUE)),
             colour = cur_fill, fontface = "bold", size = 3.7, lineheight = 0.92)
}

p3 <- p3 +
  scale_fill_manual(values = c(`TRUE` = COL$tx, `FALSE` = COL$tn), guide = "none") +
  scale_x_continuous(breaks = x_breaks, expand = expansion(mult = c(0.01, 0.04))) +
  scale_y_continuous(labels = function(x) deg_label(x, signed = TRUE),
                     expand = expansion(mult = c(0.04, 0.20))) +
  labs(
    title = title_txt,
    subtitle = sprintf(
      "Each bar is a year's mean over the same window (%s) as its departure from the %d–%d normal (%.1f °C).\nRed = warmer than normal, blue = cooler.  %s",
      win_lab, min(ytd$year), norm_yr1, normal, subtitle_lead),
    x = NULL, y = NULL,
    caption = paste0(
      caption_source_line(SITE$citation), "\n",
      sprintf("Station: %s (%s).  ", SITE$reference_station, station_id(SITE, SITE$reference_station)),
      sprintf("Each bar = mean of daily mean (TN+TX)/2 over %s of that year, minus the %d–%d average of the same window; years with < %d valid days in the window are omitted.",
              win_lab, min(ytd$year), norm_yr1, YTD_MIN_DAYS))
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title    = element_text(face = "bold", size = 17, colour = "#1A2530"),
    plot.subtitle = element_text(size = 11, colour = "#566573", margin = margin(b = 12)),
    plot.caption  = element_text(size = 8, colour = "#7F8C8D", hjust = 0,
                                 margin = margin(t = 14), lineheight = 1.05),
    plot.caption.position = "plot", plot.title.position = "plot",
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_line(colour = "#EDF0F2", linewidth = 0.4),
    panel.grid.major.y = element_line(colour = "#ECEFF1", linewidth = 0.4),
    axis.text = element_text(colour = "#566573"),
    plot.margin = margin(18, 22, 12, 18),
    plot.background = element_rect(fill = "white", colour = NA)
  )

agg_png(file.path(PATHS$figures, "temperature_ytd.png"),
        width = 2400, height = 1250, res = 200, background = "white")
print(p3); invisible(dev.off())
message("Wrote temperature_ytd.png")

# ---- all-time record days (per station) -------------------------------------
# Hottest = highest daily max (TX); coldest = lowest daily min (TN). Only for
# stations that actually carry temperature — a rain-only local station (e.g.
# Karlsruhe's Wolfartsweier) has no TX/TN to report a record for.
record_day <- function(st, col, decreasing) {
  d <- dat[station == st & !is.na(get(col))]
  d <- d[order(if (decreasing) -get(col) else get(col))][1]
  list(date = sprintf("%04d-%02d-%02d", d$year, d$month, d$day),
       value = d[[col]], tn = d$TN, tx = d$TX)
}
record_stations <- if (SITE$local_has_temp) levels(dat$station) else SITE$reference_station
records <- lapply(record_stations, function(st) {
  # Span must reflect years the station actually carries TX/TN (TNTXM is NA
  # unless both are present) — not every year `dat` has ANY row for. Zurich's
  # SMA file carries a mean-only series back to 1864, eight years before its
  # digitized TX/TN start in 1881; using every row's year claimed an 1864
  # "hottest/coldest" span for a record search that only ever looks at 1881->.
  yrs <- dat[station == st & !is.na(TNTXM)]$year
  list(station = st,
       span_yr0 = min(yrs),
       span_yr1 = max(yrs),
       hot  = record_day(st, "TX", TRUE),
       cold = record_day(st, "TN", FALSE))
})
for (r in records)
  message(sprintf("%-26s hottest %s = %.1f°C (TX) | coldest %s = %.1f°C (TN)",
                  r$station, r$hot$date, r$hot$value, r$cold$date, r$cold$value))

# ---- temperature-extremes: threshold-day counts (reference station) --------
# Counts of days per year crossing a fixed line. These make the warming tangible:
# their first-decade vs last-decade change is the "frost days halved, hot days
# doubled" story. Complete years only, so a partial year cannot deflate a count.
tb <- dat[station == CLIMATOLOGY_STATION]
ext_ann <- tb[, .(
  frost = sum(TN <  FROST_TX,  na.rm = TRUE),
  hot   = sum(TX >= HOT_TX,    na.rm = TRUE),
  vhot  = sum(TX >= VHOT_TX,   na.rm = TRUE),
  trop  = sum(TN >= TROPNIGHT, na.rm = TRUE),
  n     = sum(!is.na(TNTXM))
), by = year][n >= MIN_DAYS]
setorder(ext_ann, year)
edec1 <- ext_ann[year <= min(year) + 9]   # first complete decade
edec2 <- ext_ann[year >= max(year) - 9]   # last complete decade
# Where does the hot-day threshold SIT in this city's distribution? A fixed
# 30 degC line means very different things across ten climates. At Honolulu the
# recent-decade median TX is 29.4 degC, so the threshold cuts through the middle
# of the distribution and a mean shift of +1.8 degC reads as a 4x jump in the
# count (42 -> 175); at Castanet 30 degC sits out near the 90th percentile, where
# the same count is a genuine tail measure. Reporting the ratio without saying
# which case applies overstates the tropical sites. Computed here so the caveat
# in R/lib/narrative.R fires only where the threshold really is mid-distribution.
tx_recent <- tb[year >= max(ext_ann$year) - 9 & !is.na(TX)]$TX
hot_thr_pctile <- mean(tx_recent < HOT_TX)              # 0.5 = dead centre
hot_thr_near   <- mean(abs(tx_recent - HOT_TX) <= 1)    # crowding at the line
tx_mean_early  <- mean(tb[year %in% edec1$year & !is.na(TX)]$TX)
tx_mean_recent <- mean(tx_recent)

extremes <- list(
  yr0 = min(ext_ann$year), yr1 = max(ext_ann$year),
  frost_thr = FROST_TX, hot_thr = HOT_TX, vhot_thr = VHOT_TX, trop_thr = TROPNIGHT,
  frost_early = round(mean(edec1$frost)), frost_recent = round(mean(edec2$frost)),
  hot_early   = round(mean(edec1$hot)),   hot_recent   = round(mean(edec2$hot)),
  vhot_early  = round(mean(edec1$vhot)),  vhot_recent  = round(mean(edec2$vhot)),
  trop_early  = round(mean(edec1$trop)),  trop_recent  = round(mean(edec2$trop)),
  hot_thr_pctile = hot_thr_pctile, hot_thr_near = hot_thr_near,
  tx_shift = tx_mean_recent - tx_mean_early
)
message(sprintf("Hot-day threshold sits at p%.0f of recent TX (%.0f%% of days within +/-1 degC); mean TX shift %+.2f",
                100 * hot_thr_pctile, 100 * hot_thr_near, tx_mean_recent - tx_mean_early))
message(sprintf("Extremes (%d-%d decade vs last): frost %d->%d | hot %d->%d | v.hot %d->%d | trop.nights %d->%d",
                extremes$yr0, extremes$yr0 + 9,
                extremes$frost_early, extremes$frost_recent,
                extremes$hot_early, extremes$hot_recent,
                extremes$vhot_early, extremes$vhot_recent,
                extremes$trop_early, extremes$trop_recent))

# ---- Köppen-Geiger class of the reference station ---------------------------
# From its own monthly normals over the most recent KOPPEN_YEARS complete years,
# so the label is checkable and moves with the data. Months need >= 27 valid days
# to count, the same rule the monthly rainfall climatology uses.
kop_yrs <- tail(sort(ext_ann$year), KOPPEN_YEARS)
kop_t <- tb[year %in% kop_yrs & !is.na(TNTXM), .(t = mean(TNTXM), nd = .N),
            by = .(year, month)][nd >= 27, .(t = mean(t)), by = month][order(month)]
kop_p <- tb[year %in% kop_yrs & !is.na(RR), .(p = sum(RR), nd = .N),
            by = .(year, month)][nd >= 27, .(p = mean(p)), by = month][order(month)]
kop_ok  <- nrow(kop_t) == 12 && nrow(kop_p) == 12
koppen  <- if (kop_ok) koppen_code(kop_t$t, kop_p$p, SITE$latitude < 0) else NA_character_
kop_near <- if (kop_ok) koppen_borderline(kop_t$t, kop_p$p, SITE$latitude < 0) else NA_character_
message(sprintf("Köppen (%d-%d): %s — %s%s", min(kop_yrs), max(kop_yrs),
                koppen, koppen_label(koppen),
                if (!is.na(kop_near)) sprintf("  [near %s boundary]", kop_near) else ""))

# =============================================================================
# PLOT 4 — annual rainfall totals (both stations). Rainfall pairs normally for
# every site, even Karlsruhe, whose local station is rain-only: this plot never
# needed the local station's temperature, so `local_has_temp` doesn't apply here.
# The honest headline is a NULL result: unlike temperature, annual precipitation
# shows no statistically significant trend. Showing it is a credibility point —
# the same data that proves the warming does not manufacture a rainfall trend.
# =============================================================================
mm_label <- function(x) paste0(format(x, trim = TRUE, big.mark = ","), " mm")

rain <- dat[!is.na(RR)]
rain_ann_all <- rain[, .(total = sum(RR), n = .N), by = .(station, year)]
rain_ann_all[, complete := n >= MIN_DAYS]
setorder(rain_ann_all, station, year)
rain_ann <- rain_ann_all[complete == TRUE]
fwrite(rain_ann_all[complete == TRUE | year == cur_year],
       file.path(PATHS$outputs, "annual_rainfall.csv"))

rain_ref   <- rain_ann[station == SITE$reference_station]
rain_local <- if (HAS_LOCAL) rain_ann[station == SITE$local_station] else rain_ann[0]

# The rain series' own year range — NOT the temperature series' yr0/yr1 above.
# Reusing the temperature range previously clipped Zurich's rain chart (rain
# data from 1864, temperature from 1882 -> scale_x_continuous(limits=) silently
# dropped 18 years of valid rainfall, since `limits` filters rows, unlike
# coord_cartesian which only pads the view).
yr0_rain <- min(rain_ref$year); yr1_rain <- max(rain_ref$year)

# Trend + significance on the long reference-station record (the one worth a slope).
fit_rain       <- lm(total ~ year, data = rain_ref)
rain_slope_dec <- unname(coef(fit_rain)[2]) * 10
rain_p         <- summary(fit_rain)$coefficients[2, 4]
rain_sig       <- rain_p < 0.05
rain_mean_ref  <- mean(rain_ref$total)
rain_wettest   <- rain_ref[which.max(total)]
rain_driest    <- rain_ref[which.min(total)]

rain_levels <- if (HAS_LOCAL) c(SITE$reference_station, SITE$local_station) else SITE$reference_station
rain_pal <- if (HAS_LOCAL) c(COL$rain_blag, COL$rain_auz) else c(COL$rain_blag)
rain_shp <- if (HAS_LOCAL) c(16, 18)                      else c(16)
names(rain_pal) <- rain_levels
names(rain_shp) <- rain_levels
rain_ann[, station := factor(station, levels = rain_levels)]

# geom_line only breaks at a row that EXISTS with an NA value, not at a year
# with no row at all -- a station with a real multi-year digitization gap (e.g.
# Santa Fe/Honolulu's local rain station) otherwise gets a single straight
# diagonal segment bridging the gap, indistinguishable from real data. Insert
# an explicit NA row for every year missing within each station's own
# min..max span; geom_point/geom_smooth silently drop NA rows on their own.
rain_plot <- merge(
  rain_ann[, .(year = seq(min(year), max(year))), by = station],
  rain_ann[, .(station, year, total)],
  by = c("station", "year"), all.x = TRUE)

# Significance clause must branch like the report text (see R/lib/narrative.R)
# — this was previously hardcoded to "not significant" regardless of rain_sig.
rain_sig_txt <- if (rain_sig) sprintf("significant (p = %.2f)", rain_p) else
                               sprintf("not significant (p = %.2f)", rain_p)
rain_txt <- sprintf(
  "%s, annual total rainfall\nmean %.0f mm/yr  ·  %+.0f mm/decade — %s",
  SITE$reference_station, rain_mean_ref, rain_slope_dec, rain_sig_txt)

p4 <- ggplot(rain_plot, aes(year, total, colour = station, shape = station)) +
  geom_hline(yintercept = rain_mean_ref, colour = COL$rain_blag,
             linetype = "dashed", linewidth = 0.4, alpha = 0.6) +
  geom_line(aes(group = station), alpha = 0.28, linewidth = 0.4) +
  geom_point(size = 1.7, alpha = 0.85) +
  geom_smooth(aes(group = station), method = "loess", formula = y ~ x, se = FALSE,
              linewidth = 1.3, span = 0.75) +
  annotate("label", x = yr0_rain + 0.5, y = max(rain_ref$total) + 30,
           label = rain_txt, hjust = 0, vjust = 1,
           size = 3.2, colour = "#3D4A54", lineheight = 0.98, fontface = "italic",
           fill = "white", alpha = 0.7, label.padding = unit(0.4, "lines")) +
  scale_colour_manual(values = rain_pal, name = NULL, breaks = rain_levels) +
  scale_shape_manual(values = rain_shp, name = NULL, breaks = rain_levels) +
  scale_x_continuous(breaks = x_breaks, limits = c(yr0_rain, max(yr1_rain, cur_year)),
                     expand = expansion(mult = c(0.01, 0.04))) +
  scale_y_continuous(labels = mm_label, limits = c(0, max(rain_ref$total) + 60),
                     expand = expansion(mult = c(0, 0.02))) +
  guides(colour = guide_legend(override.aes = list(alpha = 1, linewidth = 1.4))) +
  labs(
    title = sprintf(if (rain_sig) "Rainfall around %s — a slow long-run trend" else "Rainfall around %s — no clear trend",
                    SITE$city),
    subtitle = sprintf(if (rain_sig)
                    "Annual total precipitation, %d → %d  ·  highly variable year to year, with a measurable long-run trend"
                  else "Annual total precipitation, %d → %d  ·  highly variable year to year, but flat over the long run",
                       yr0_rain, yr1_rain),
    x = NULL, y = NULL,
    caption = paste0(
      caption_source_line(SITE$citation), "\n",
      sprintf("Annual total of daily rainfall (RR, mm).  Dashed line = %s long-term mean.  ", SITE$reference_station),
      sprintf("Incomplete years (< %d valid days) excluded. Curves: LOESS smoothing.", MIN_DAYS)
    )
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title    = element_text(face = "bold", size = 17, colour = "#1A2530"),
    plot.subtitle = element_text(size = 12, colour = "#566573", margin = margin(b = 12)),
    plot.caption  = element_text(size = 8, colour = "#7F8C8D", hjust = 0,
                                 margin = margin(t = 14), lineheight = 1.05),
    plot.caption.position = "plot", plot.title.position = "plot",
    legend.position = "bottom", legend.text = element_text(size = 10),
    legend.key.width = unit(1.6, "lines"),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(colour = "#ECEFF1", linewidth = 0.4),
    axis.text = element_text(colour = "#566573"),
    plot.margin = margin(18, 22, 12, 18),
    plot.background = element_rect(fill = "white", colour = NA)
  )

agg_png(file.path(PATHS$figures, "rain_series.png"),
        width = 2400, height = 1400, res = 200, background = "white")
print(p4); invisible(dev.off())
message("Wrote rain_series.png")

# =============================================================================
# PLOT 5 — monthly rainfall climatology (reference station): one line per year,
#          normal bold, current year bold — the seasonal shape, mirroring the
#          daily temperature climatology.
# =============================================================================
rain_clim <- dat[station == CLIMATOLOGY_STATION & !is.na(RR)]
# monthly totals, keeping only near-complete months (>= 27 valid days) so a month
# with missing days is not mistaken for a dry one. This also drops the current,
# still-incomplete month of the in-progress year automatically.
rmon      <- rain_clim[, .(mm = sum(RR), nd = .N), by = .(year, month)][nd >= 27]
rmon_prev <- rmon[year <  cur_year]
rmon_cur  <- rmon[year == cur_year]
rain_norm <- rmon_prev[, .(mm = mean(mm)), by = month][order(month)]
rain_nyears <- uniqueN(rmon_prev$year)

# wettest and driest calendar month on record (normal), for the caption
rain_wet_mon <- rain_norm[which.max(mm)]
rain_dry_mon <- rain_norm[which.min(mm)]

p5 <- ggplot() +
  geom_line(data = rmon_prev, aes(month, mm, group = year),
            colour = COL$spaghetti, alpha = 0.20, linewidth = 0.35) +
  geom_line(data = rain_norm, aes(month, mm),
            colour = COL$normal, linewidth = 1.1, alpha = 0.95) +
  geom_line(data = rmon_cur, aes(month, mm),
            colour = COL$wet, linewidth = 1.6) +
  geom_point(data = rmon_cur, aes(month, mm),
             colour = COL$wet, size = 1.9) +
  annotate("text", x = max(rmon_cur$month) + 0.15, y = tail(rmon_cur$mm, 1),
           label = as.character(cur_year), hjust = 0, vjust = 0.5,
           colour = COL$wet, fontface = "bold", size = 4) +
  scale_x_continuous(breaks = 1:12, labels = month.abb,
                     expand = expansion(mult = c(0.02, 0.06))) +
  scale_y_continuous(labels = mm_label, limits = c(0, NA),
                     expand = expansion(mult = c(0, 0.04))) +
  labs(
    title = sprintf("Rain through the year — %s", CLIMATOLOGY_STATION),
    subtitle = sprintf(
      "Monthly rainfall total, one grey line per year (%d–%d, %d years).  Dark line = long-term monthly normal; bold blue = %d so far.\n%s is the wettest month on average (%.0f mm), %s the driest (%.0f mm) — but any month can swing widely from year to year.",
      min(rmon_prev$year), max(rmon_prev$year), rain_nyears, cur_year,
      month.name[rain_wet_mon$month], rain_wet_mon$mm,
      month.name[rain_dry_mon$month], rain_dry_mon$mm),
    x = NULL, y = NULL,
    caption = paste0(
      caption_source_line(SITE$citation), "\n",
      sprintf("Station: %s (%s).  ", SITE$reference_station, station_id(SITE, SITE$reference_station)),
      "Each line = one year's monthly rainfall totals (RR, mm); months with < 27 valid days omitted."
    )
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title    = element_text(face = "bold", size = 17, colour = "#1A2530"),
    plot.subtitle = element_text(size = 11, colour = "#566573", margin = margin(b = 12)),
    plot.caption  = element_text(size = 8, colour = "#7F8C8D", hjust = 0,
                                 margin = margin(t = 14), lineheight = 1.05),
    plot.caption.position = "plot", plot.title.position = "plot",
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_line(colour = "#EDF0F2", linewidth = 0.4),
    panel.grid.major.y = element_line(colour = "#ECEFF1", linewidth = 0.4),
    axis.text = element_text(colour = "#566573"),
    plot.margin = margin(18, 22, 12, 18),
    plot.background = element_rect(fill = "white", colour = NA)
  )

agg_png(file.path(PATHS$figures, "rain_climatology.png"),
        width = 2400, height = 1250, res = 200, background = "white")
print(p5); invisible(dev.off())
message("Wrote rain_climatology.png")

# ---- stash numbers for the HTML report / README ------------------------------
stats <- list(
  yr0 = yr0, yr1 = yr1,
  slope_dec_ref = slope_dec_ref, rise_ref = rise_ref,
  slope_dec_local = slope_dec_local,
  slope_dec_ref_localwin = slope_dec_ref_localwin,
  local_yr0 = local_yr0, local_yr1 = local_yr1,
  n_years_ref = n_years_ref,
  koppen = koppen, koppen_label = koppen_label(koppen),
  koppen_borderline = kop_near,
  koppen_yr0 = min(kop_yrs), koppen_yr1 = max(kop_yrs),
  latitude = SITE$latitude, longitude = SITE$longitude,
  elevation_m = SITE$elevation_m,
  common_yr0 = COMMON_YR0, slope_dec_ref_common = slope_dec_ref_common,
  slope_dec_tn = slope_dec_tn, slope_dec_tx = slope_dec_tx,
  dtr_early = dtr_early, dtr_recent = dtr_recent,
  mean_recent = round(mean(ref[year >= yr1 - 9]$TMEAN), 2),
  mean_early  = round(mean(ref[year <= yr0 + 9]$TMEAN), 2),
  clim_yr0 = min(prev_years$year), clim_yr1 = max(prev_years$year),
  clim_nyears = n_years, cur_year = cur_year, year_complete = YEAR_COMPLETE,
  n_station_years = nrow(annual),
  hot_thr = HOT_THR, cold_thr = COLD_THR,
  hot_years = hot_years, cold_years = cold_years, both_years = both_years,
  raw_both_years = raw_both_years,
  hot_all_recent = hot_all_recent, cold_all_but_one = cold_all_but_one,
  smooth_window = SMOOTH_WINDOW,
  records = records,
  ytd = list(
    window    = win_lab,
    window_days = cutoff_doy,   # length of the Jan-1-to-cutoff window, in days
    cutoff_month = cutM, cutoff_day = cutD,   # structured cutoff — don't regex-parse `window`
    min_days  = YTD_MIN_DAYS,
    n_years   = nrow(ytd),
    has_ytd   = HAS_YTD,
    cur       = round(cur_ytd, 1),
    rank      = ytd_rank,
    is_record = is_record,
    rec_year  = best_oth$year,
    rec_val   = round(best_oth$ytd, 1),
    delta     = round(delta, 1),
    normal    = round(normal, 1),
    # The span the `normal` is averaged over. The prose must NAME it: this
    # baseline is the whole qualifying record, so a longer record gives a cooler
    # normal and a larger anomaly. Zurich's "+3.5 degC above normal" is against
    # an 1882-2025 mean and Karlsruhe's "+2.4" against 1876-2025 — calling both
    # "the long-term normal" invites a comparison the numbers do not support.
    norm_yr0  = min(ytd$year), norm_yr1 = norm_yr1,
    cur_anom  = round(cur_anom, 1)
  ),
  extremes = extremes,
  rain = list(
    yr0 = min(rain_ref$year), yr1 = max(rain_ref$year),
    n_years = nrow(rain_ref),
    mean_ref = round(rain_mean_ref),
    slope_dec = round(rain_slope_dec, 1),
    p = round(rain_p, 2),
    significant = rain_sig,
    wettest_year = rain_wettest$year, wettest_mm = round(rain_wettest$total),
    driest_year  = rain_driest$year,  driest_mm  = round(rain_driest$total),
    wet_month = month.name[rain_wet_mon$month], wet_month_mm = round(rain_wet_mon$mm),
    dry_month = month.name[rain_dry_mon$month], dry_month_mm = round(rain_dry_mon$mm),
    local_yr0 = if (HAS_LOCAL) min(rain_local$year) else NA_integer_,
    local_yr1 = if (HAS_LOCAL) max(rain_local$year) else NA_integer_,
    local_mean = if (HAS_LOCAL) round(mean(rain_local$total)) else NA_real_
  )
)
saveRDS(stats, file.path(PATHS$processed, "trend_stats.rds"))
message("Wrote trend_stats.rds")
