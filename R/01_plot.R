#!/usr/bin/env Rscript
# =============================================================================
# Stage 01 — build the figures
# Reads the processed daily CSVs and produces:
#   * outputs/figures/temperature_series.png      — annual series, first->current
#   * outputs/figures/temperature_climatology.png — every year day-by-day
#   * outputs/annual_temperatures.csv             — the annual table
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

annual <- dat[, .(
  n_tn = sum(!is.na(TN)),
  n_tx = sum(!is.na(TX)),
  n_tm = sum(!is.na(TNTXM)),
  TN    = mean(TN,    na.rm = TRUE),
  TX    = mean(TX,    na.rm = TRUE),
  TMEAN = mean(TNTXM, na.rm = TRUE)
), by = .(station, year)]

annual <- annual[n_tn >= MIN_DAYS & n_tx >= MIN_DAYS & n_tm >= MIN_DAYS]
setorder(annual, station, year)

fwrite(annual, file.path(PATHS$outputs, "annual_temperatures.csv"))
message(sprintf("Annual table: %d complete station-years (%d..%d).",
                nrow(annual), min(annual$year), max(annual$year)))

blag <- annual[station == "Toulouse-Blagnac"]
auz  <- annual[station == "Auzeville-Tolosane-INRAE"]

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
  scale_x_continuous(breaks = x_breaks, limits = c(yr0, yr1),
                     expand = expansion(mult = c(0.01, 0.02))) +
  scale_y_continuous(breaks = seq(-5, 30, 2),
                     limits = c(min(blag$TN) - 0.5, max(blag$TX) + 1.6),
                     labels = function(x) paste0(x, " °C")) +
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
      "Stations: Auzeville-Tolosane-INRAE (31035001, edge of Castanet-Tolosan) and Toulouse-Blagnac (31069001, long-term reference).  ",
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

cur_year   <- max(clim$year)              # 2026 (partial)
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
  scale_y_continuous(breaks = seq(-10, 40, 5), labels = function(x) paste0(x, " °C")) +
  labs(
    title = sprintf("Every year, day by day — %s", CLIMATOLOGY_STATION),
    subtitle = sprintf(
      "Daily mean temperature, %d–%d (%d years), smoothed with a centred %d-day rolling mean.  Bold red = %d so far; dark line = long-term normal.\nYears whose smoothed daily mean ever rose above +30 °C are drawn red; those that ever fell below −5 °C, blue.  %s",
      min(prev_years$year), max(prev_years$year), n_years, SMOOTH_WINDOW, cur_year, both_txt),
    x = NULL, y = NULL,
    caption = paste0(
      "Source: Météo-France, Données climatologiques de base – quotidiennes (meteo.data.gouv.fr, dataset 6569b51a…). Licence Ouverte / Etalab.  Station: Toulouse-Blagnac (31069001).  ",
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

# ---- stash numbers for the HTML report --------------------------------------
stats <- list(
  yr0 = yr0, yr1 = yr1,
  slope_dec_blag = slope_dec_blag, rise_blag = rise_blag,
  slope_dec_auz = slope_dec_auz,
  auz_yr0 = min(auz$year), auz_yr1 = max(auz$year),
  mean_recent = round(mean(blag[year >= yr1 - 9]$TMEAN), 2),
  mean_early  = round(mean(blag[year <= yr0 + 9]$TMEAN), 2),
  clim_yr0 = min(prev_years$year), clim_yr1 = max(prev_years$year),
  clim_nyears = n_years, cur_year = cur_year,
  n_station_years = nrow(annual),
  hot_thr = HOT_THR, cold_thr = COLD_THR,
  hot_years = hot_years, cold_years = cold_years, both_years = both_years,
  smooth_window = SMOOTH_WINDOW
)
saveRDS(stats, file.path(PATHS$processed, "trend_stats.rds"))
message("Wrote trend_stats.rds")
