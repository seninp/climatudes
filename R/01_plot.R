#!/usr/bin/env Rscript
# =============================================================================
# Stage 01 — build the figures
# Reads the processed daily CSVs and produces:
#   * outputs/figures/temperature_series.png      — annual series, first->current
#   * outputs/figures/temperature_climatology.png — every year day-by-day
#   * outputs/figures/temperature_ytd.png         — year-to-date race
#   * outputs/figures/rain_series.png             — annual rainfall totals
#   * outputs/figures/rain_climatology.png        — monthly rainfall seasonal cycle
#   * outputs/annual_temperatures.csv             — the annual table
#   * outputs/annual_rainfall.csv                 — annual rainfall totals
#   * data/processed/trend_stats.rds              — numbers reused by the report
# =============================================================================

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(scales)
  library(ragg)
})

source("R/config.R")
dir.create(PATHS$figures, recursive = TRUE, showWarnings = FALSE)

# ---- read the small gzipped station extract produced by stage 00 ------------
extract_gz <- file.path(PATHS$processed, STATION_EXTRACT)
if (!file.exists(extract_gz))
  stop("Missing ", extract_gz, " — run stage 00 first (make prepare).")

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

blag <- annual[station == "Toulouse-Blagnac"]
auz  <- annual[station == "Auzeville-Tolosane-INRAE"]

# current partial-year row (for the hollow "to date" marker on plot 1)
blag_cur <- annual_all[station == "Toulouse-Blagnac" & year == cur_year & complete == FALSE]

L_TX   <- "Toulouse-Blagnac — daily maximum (TX)"
L_MEAN <- "Toulouse-Blagnac — daily mean"
L_TN   <- "Toulouse-Blagnac — daily minimum (TN)"
L_AUZ  <- "Auzeville-INRAE (≈ Castanet-Tolosan) — mean"
series_levels <- c(L_TX, L_MEAN, L_TN, L_AUZ)

mk <- function(d, col, label) data.table(year = d$year, value = d[[col]], series = label)
plotdat <- rbindlist(list(
  mk(blag, "TX",    L_TX),
  mk(blag, "TMEAN", L_MEAN),
  mk(blag, "TN",    L_TN),
  mk(auz,  "TMEAN", L_AUZ)
))
plotdat[, series := factor(series, levels = series_levels)]

pal <- c(COL$tx, COL$mean, COL$tn, COL$auz); names(pal) <- series_levels
shp <- c(16, 16, 16, 18);                    names(shp) <- series_levels

# ---- linear-trend statistics ------------------------------------------------
fit_blag <- lm(TMEAN ~ year, data = blag)
slope_dec_blag <- unname(coef(fit_blag)[2]) * 10
yr0 <- min(blag$year); yr1 <- max(blag$year)
rise_blag <- unname(coef(fit_blag)[2]) * (yr1 - yr0)

fit_auz <- lm(TMEAN ~ year, data = auz)
slope_dec_auz <- unname(coef(fit_auz)[2]) * 10

# Blagnac's slope over the SAME window as Auzeville — so the two local/regional
# slopes are compared like-for-like. (Over 2004-> Blagnac warms faster than over
# its full 1947-> record: recent decades warm faster, so this is the honest
# number to set beside Auzeville's, not the whole-period 0.34.)
auz_span <- range(auz$year)
slope_dec_blag_auzwin <- unname(
  coef(lm(TMEAN ~ year, data = blag[year >= auz_span[1] & year <= auz_span[2]]))[2]) * 10

trend_txt <- sprintf(
  "Toulouse-Blagnac, annual mean temperature\n+%.2f °C / decade  ·  +%.1f °C over %d years (%d–%d)",
  slope_dec_blag, rise_blag, yr1 - yr0, yr0, yr1)

x_breaks <- seq(1950, 2030, by = 10)

p1 <- ggplot() +
  geom_ribbon(data = blag, aes(year, ymin = TN, ymax = TX),
              fill = COL$tx, alpha = 0.05) +
  geom_line(data = plotdat, aes(year, value, colour = series, group = series),
            alpha = 0.28, linewidth = 0.4) +
  geom_point(data = plotdat, aes(year, value, colour = series, shape = series),
             size = 1.5, alpha = 0.85) +
  geom_smooth(data = plotdat, aes(year, value, colour = series, group = series),
              method = "loess", formula = y ~ x, se = FALSE,
              linewidth = 1.3, span = 0.7) +
  annotate("label", x = yr0 + 0.5, y = max(blag$TX) + 1.2,
           label = trend_txt, hjust = 0, vjust = 1,
           size = 3.2, colour = "#3D4A54", lineheight = 0.98, fontface = "italic",
           fill = "white", alpha = 0.7, label.padding = unit(0.4, "lines")) +
  scale_colour_manual(values = pal, name = NULL, breaks = series_levels) +
  scale_shape_manual(values = shp, name = NULL, breaks = series_levels) +
  scale_x_continuous(breaks = x_breaks, limits = c(yr0, max(yr1, cur_year)),
                     expand = expansion(mult = c(0.01, 0.04))) +
  scale_y_continuous(breaks = seq(-5, 30, 2),
                     limits = c(min(blag$TN) - 0.5, max(blag$TX) + 1.6),
                     labels = deg_label) +
  guides(colour = guide_legend(nrow = 2, byrow = TRUE,
                               override.aes = list(alpha = 1, linewidth = 1.4)),
         shape = guide_legend(nrow = 2, byrow = TRUE)) +
  labs(
    title = "Temperatures around Castanet-Tolosan (Haute-Garonne, France)",
    subtitle = sprintf("Annual means of daily temperatures, %d → %d  ·  a clear and continuous warming",
                       yr0, yr1),
    x = NULL, y = NULL,
    caption = paste0(
      "Source: Météo-France, Données climatologiques de base – quotidiennes (meteo.data.gouv.fr, dataset 6569b51a…), dept. 31. Licence Ouverte / Etalab.\n",
      "Min = TN, Max = TX, Mean = (TN+TX)/2.  ",
      "Stations: Auzeville-Tolosane-INRAE (31035001, edge of Castanet-Tolosan) and Toulouse-Blagnac (31069001, long-term reference).\n",
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
if (nrow(blag_cur)) {
  p1 <- p1 +
    geom_point(data = blag_cur, aes(year, TMEAN),
               shape = 23, size = 3, fill = "white", colour = COL$tx, stroke = 1.2) +
    annotate("text", x = blag_cur$year, y = blag_cur$TMEAN - 0.75,
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

prev_years <- clim[year <  cur_year]
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
  # one line per past year — pronounced enough to read the spread, still subordinate to 2026
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
      "Source: Météo-France, Données climatologiques de base – quotidiennes (meteo.data.gouv.fr, dataset 6569b51a…). Licence Ouverte / Etalab.  Station: Toulouse-Blagnac (31069001).\n",
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

blagd <- dat[station == CLIMATOLOGY_STATION & !is.na(TNTXM)]
cutM <- max(blagd[year == cur_year]$month)
cutD <- max(blagd[year == cur_year & month == cutM]$day)
in_window <- function(m, d) (m < cutM) | (m == cutM & d <= cutD)

ytd <- blagd[in_window(month, day), .(ytd = mean(TNTXM), n = .N), by = year][n >= MIN_YTD_DAYS]
setorder(ytd, year)
ytd[, is_cur := year == cur_year]

win_lab  <- sprintf("Jan 1 – %s %d", month.abb[cutM], cutD)   # e.g. "Jan 1 – Jul 9"
cur_ytd  <- ytd[year == cur_year]$ytd
best_oth <- ytd[year != cur_year][order(-ytd)][1]   # warmest of all OTHER years
ytd_rank <- match(cur_year, ytd[order(-ytd)]$year)
delta    <- cur_ytd - best_oth$ytd                  # + if the current year is the record
is_record <- ytd_rank == 1L

message(sprintf("YTD (%s): %d = %.2f°C, rank %d/%d%s",
                win_lab, cur_year, cur_ytd, ytd_rank, nrow(ytd),
                if (is_record) sprintf(" — RECORD, +%.2f°C over %d", delta, best_oth$year) else
                  sprintf(" — record held by %d (%.2f°C)", best_oth$year, best_oth$ytd)))

# each year's window mean as a DEPARTURE from the long-term (prior-years) normal —
# blue below, red above; the warming shows as the swing from blue to red, and the
# current year stands out as the tallest bar (no floating point, real time axis).
normal   <- mean(ytd[year != cur_year]$ytd)
ytd[, anom := ytd - normal]
cur_anom <- ytd[year == cur_year]$anom
delta_disp <- round(cur_ytd, 1) - round(best_oth$ytd, 1)   # matches the report's rounding
norm_yr1 <- max(ytd[is_cur == FALSE]$year)

p3 <- ggplot(ytd, aes(year, anom, fill = anom > 0)) +
  geom_col(width = 0.72, alpha = 0.85) +
  geom_hline(yintercept = 0, colour = "#8A97A0", linewidth = 0.4) +
  # current year emphasised: full-opacity red bar with a dark outline
  geom_col(data = ytd[is_cur == TRUE], aes(year, anom),
           fill = COL$tx, colour = "#7B241C", linewidth = 0.4, width = 0.92) +
  annotate("text", x = cur_year, y = cur_anom, vjust = -0.35, hjust = 0.65,
           label = sprintf("%d\n+%.1f °C", cur_year, cur_anom),
           colour = COL$tx, fontface = "bold", size = 3.7, lineheight = 0.92) +
  scale_fill_manual(values = c(`TRUE` = COL$tx, `FALSE` = COL$tn), guide = "none") +
  scale_x_continuous(breaks = x_breaks, expand = expansion(mult = c(0.01, 0.04))) +
  scale_y_continuous(labels = function(x) deg_label(x, signed = TRUE),
                     expand = expansion(mult = c(0.04, 0.20))) +
  labs(
    title = sprintf("The year so far, warmer than any before it — %s", CLIMATOLOGY_STATION),
    subtitle = sprintf(
      "Each bar is a year's mean over the same window (%s) as its departure from the %d–%d normal (%.1f °C).\nRed = warmer than normal, blue = cooler.  %d is the warmest such period on record: +%.1f °C above normal, +%.1f °C over the previous record (%d).",
      win_lab, min(ytd$year), norm_yr1, normal, cur_year, cur_anom, delta_disp, best_oth$year),
    x = NULL, y = NULL,
    caption = paste0(
      "Source: Météo-France, Données climatologiques de base – quotidiennes (meteo.data.gouv.fr, dataset 6569b51a…). Licence Ouverte / Etalab.  Station: Toulouse-Blagnac (31069001).\n",
      sprintf("Each bar = mean of daily mean (TN+TX)/2 over %s of that year, minus the %d–%d average of the same window; years with < %d valid days in the window are omitted.",
              win_lab, min(ytd$year), norm_yr1, MIN_YTD_DAYS))
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
# Hottest = highest daily max (TX); coldest = lowest daily min (TN).
record_day <- function(st, col, decreasing) {
  d <- dat[station == st & !is.na(get(col))]
  d <- d[order(if (decreasing) -get(col) else get(col))][1]
  list(date = sprintf("%04d-%02d-%02d", d$year, d$month, d$day),
       value = d[[col]], tn = d$TN, tx = d$TX)
}
records <- lapply(levels(dat$station), function(st) {
  list(station = st,
       span_yr0 = min(dat[station == st]$year),
       span_yr1 = max(dat[station == st]$year),
       hot  = record_day(st, "TX", TRUE),
       cold = record_day(st, "TN", FALSE))
})
for (r in records)
  message(sprintf("%-26s hottest %s = %.1f°C (TX) | coldest %s = %.1f°C (TN)",
                  r$station, r$hot$date, r$hot$value, r$cold$date, r$cold$value))

# ---- temperature-extremes: threshold-day counts (Toulouse-Blagnac) ----------
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
extremes <- list(
  yr0 = min(ext_ann$year), yr1 = max(ext_ann$year),
  frost_thr = FROST_TX, hot_thr = HOT_TX, vhot_thr = VHOT_TX, trop_thr = TROPNIGHT,
  frost_early = round(mean(edec1$frost)), frost_recent = round(mean(edec2$frost)),
  hot_early   = round(mean(edec1$hot)),   hot_recent   = round(mean(edec2$hot)),
  vhot_early  = round(mean(edec1$vhot)),  vhot_recent  = round(mean(edec2$vhot)),
  trop_early  = round(mean(edec1$trop)),  trop_recent  = round(mean(edec2$trop))
)
message(sprintf("Extremes (%d-%d decade vs last): frost %d->%d | hot %d->%d | v.hot %d->%d | trop.nights %d->%d",
                extremes$yr0, extremes$yr0 + 9,
                extremes$frost_early, extremes$frost_recent,
                extremes$hot_early, extremes$hot_recent,
                extremes$vhot_early, extremes$vhot_recent,
                extremes$trop_early, extremes$trop_recent))

# =============================================================================
# PLOT 4 — annual rainfall totals (both stations)
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

rain_blag <- rain_ann[station == "Toulouse-Blagnac"]
rain_auz  <- rain_ann[station == "Auzeville-Tolosane-INRAE"]

# Trend + significance on the long Blagnac record (the one worth a slope).
fit_rain       <- lm(total ~ year, data = rain_blag)
rain_slope_dec <- unname(coef(fit_rain)[2]) * 10
rain_p         <- summary(fit_rain)$coefficients[2, 4]
rain_sig       <- rain_p < 0.05
rain_mean_blag <- mean(rain_blag$total)
rain_wettest   <- rain_blag[which.max(total)]
rain_driest    <- rain_blag[which.min(total)]

rain_levels <- c("Toulouse-Blagnac", "Auzeville-Tolosane-INRAE")
rain_pal <- c(COL$rain_blag, COL$rain_auz); names(rain_pal) <- rain_levels
rain_shp <- c(16, 18);                      names(rain_shp) <- rain_levels
rain_ann[, station := factor(station, levels = rain_levels)]

rain_txt <- sprintf(
  "Toulouse-Blagnac, annual total rainfall\nmean %.0f mm/yr  ·  %+.0f mm/decade — not significant (p = %.2f)",
  rain_mean_blag, rain_slope_dec, rain_p)

p4 <- ggplot(rain_ann, aes(year, total, colour = station, shape = station)) +
  geom_hline(yintercept = rain_mean_blag, colour = COL$rain_blag,
             linetype = "dashed", linewidth = 0.4, alpha = 0.6) +
  geom_line(aes(group = station), alpha = 0.28, linewidth = 0.4) +
  geom_point(size = 1.7, alpha = 0.85) +
  geom_smooth(aes(group = station), method = "loess", formula = y ~ x, se = FALSE,
              linewidth = 1.3, span = 0.75) +
  annotate("label", x = yr0 + 0.5, y = max(rain_blag$total) + 30,
           label = rain_txt, hjust = 0, vjust = 1,
           size = 3.2, colour = "#3D4A54", lineheight = 0.98, fontface = "italic",
           fill = "white", alpha = 0.7, label.padding = unit(0.4, "lines")) +
  scale_colour_manual(values = rain_pal, name = NULL, breaks = rain_levels) +
  scale_shape_manual(values = rain_shp, name = NULL, breaks = rain_levels) +
  scale_x_continuous(breaks = x_breaks, limits = c(yr0, max(yr1, cur_year)),
                     expand = expansion(mult = c(0.01, 0.04))) +
  scale_y_continuous(labels = mm_label, limits = c(0, max(rain_blag$total) + 60),
                     expand = expansion(mult = c(0, 0.02))) +
  guides(colour = guide_legend(override.aes = list(alpha = 1, linewidth = 1.4))) +
  labs(
    title = "Rainfall around Castanet-Tolosan — no clear trend",
    subtitle = sprintf("Annual total precipitation, %d → %d  ·  highly variable year to year, but flat over the long run",
                       yr0, yr1),
    x = NULL, y = NULL,
    caption = paste0(
      "Source: Météo-France, Données climatologiques de base – quotidiennes (meteo.data.gouv.fr, dataset 6569b51a…), dept. 31. Licence Ouverte / Etalab.\n",
      "Annual total of daily rainfall (RR, mm).  Dashed line = Toulouse-Blagnac long-term mean.  ",
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
# PLOT 5 — monthly rainfall climatology (Toulouse-Blagnac): one line per year,
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
      "Source: Météo-France, Données climatologiques de base – quotidiennes (meteo.data.gouv.fr, dataset 6569b51a…). Licence Ouverte / Etalab.  Station: Toulouse-Blagnac (31069001).\n",
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

# ---- stash numbers for the HTML report --------------------------------------
stats <- list(
  yr0 = yr0, yr1 = yr1,
  slope_dec_blag = slope_dec_blag, rise_blag = rise_blag,
  slope_dec_auz = slope_dec_auz,
  slope_dec_blag_auzwin = slope_dec_blag_auzwin,
  auz_yr0 = min(auz$year), auz_yr1 = max(auz$year),
  mean_recent = round(mean(blag[year >= yr1 - 9]$TMEAN), 2),
  mean_early  = round(mean(blag[year <= yr0 + 9]$TMEAN), 2),
  clim_yr0 = min(prev_years$year), clim_yr1 = max(prev_years$year),
  clim_nyears = n_years, cur_year = cur_year,
  n_station_years = nrow(annual),
  hot_thr = HOT_THR, cold_thr = COLD_THR,
  hot_years = hot_years, cold_years = cold_years, both_years = both_years,
  raw_both_years = raw_both_years,
  hot_all_recent = hot_all_recent, cold_all_but_one = cold_all_but_one,
  smooth_window = SMOOTH_WINDOW,
  records = records,
  ytd = list(
    window    = win_lab,
    n_years   = nrow(ytd),
    cur       = round(cur_ytd, 1),
    rank      = ytd_rank,
    is_record = is_record,
    rec_year  = best_oth$year,
    rec_val   = round(best_oth$ytd, 1),
    delta     = round(delta, 1),
    normal    = round(normal, 1),
    cur_anom  = round(cur_anom, 1)
  ),
  extremes = extremes,
  rain = list(
    yr0 = min(rain_blag$year), yr1 = max(rain_blag$year),
    n_years = nrow(rain_blag),
    mean_blag = round(rain_mean_blag),
    slope_dec = round(rain_slope_dec, 1),
    p = round(rain_p, 2),
    significant = rain_sig,
    wettest_year = rain_wettest$year, wettest_mm = round(rain_wettest$total),
    driest_year  = rain_driest$year,  driest_mm  = round(rain_driest$total),
    wet_month = month.name[rain_wet_mon$month], wet_month_mm = round(rain_wet_mon$mm),
    dry_month = month.name[rain_dry_mon$month], dry_month_mm = round(rain_dry_mon$mm),
    auz_yr0 = min(rain_auz$year), auz_yr1 = max(rain_auz$year),
    auz_mean = round(mean(rain_auz$total))
  )
)
saveRDS(stats, file.path(PATHS$processed, "trend_stats.rds"))
message("Wrote trend_stats.rds")
