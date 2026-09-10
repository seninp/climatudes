# =============================================================================
# Source module — one physical airport station, two open providers homogenized
# into a single daily series, for a station whose internationally-shared
# climatological feed thinned but whose live METAR stream did not.
#
# The first worked case is Kathmandu's Tribhuvan International Airport, the
# sole long record for the Kathmandu Valley (see R/sites/lalitpur.R); Hyderabad's
# Begumpet observatory (R/sites/hyderabad.R) follows the same recipe with a far
# richer overlap. For Kathmandu:
#   * NOAA GHCN-Daily (station NP000444540, WMO 44454) — clean daily TMAX/TMIN
#     1971-2000, thin and intermittent 2001-2011, then substantial again from
#     ~2015 (200-260 days/yr, below the completeness bar alone but a rich
#     same-day overlap with IEM). Also the ONLY source of daily rainfall here.
#   * Iowa Environmental Mesonet (IEM) ASOS archive (station VNKT, the SAME
#     airport) — daily max/min derived from hourly METAR, near-complete from
#     2012 on. METAR carries no usable rainfall, so IEM supplies TEMPERATURE
#     ONLY.
#
# Why homogenize rather than hard-splice by date. The two feeds are the same
# instrument seen through different processing, and they sit on measurably
# different scales: IEM's METAR-derived nights read WARMER and its days read
# COOLER than GHCN's co-op values (hourly METAR misses the pre-dawn low, and
# ASOS automation clips the afternoon peak). A naive "GHCN before 2000, IEM
# after" splice bakes that offset straight into the trend — the daytime-max
# curve bends DOWN at the seam and the nighttime-min curve jumps UP, an
# artifact, not climate. Because GHCN and IEM overlap on thousands of days
# (2015-2025), the offset is not guessed: it is MEASURED from same-station,
# same-day pairs, per calendar month (it is strongly seasonal), and IEM is
# shifted onto GHCN's scale before it is used. This is a data-driven
# homogenization, not a model.
#
# Combine rule (after correction, both feeds are on GHCN's scale):
#   TEMPERATURE  real GHCN value wherever GHCN has one; otherwise the
#                offset-corrected IEM value. Years that end up with < MIN_DAYS
#                (the sparse 2001-2011 stretch) drop out downstream as an honest
#                interior gap, not invented data.
#   RAINFALL     GHCN throughout (IEM has none). Usable rain-years are few and
#                recent; R/sites/lalitpur.R's prose says so.
#   OFFSET       per-month mean(IEM - GHCN) over all same-day pairs, computed at
#                run time and logged. Requires >= MIN_OVERLAP_DAYS pairs per
#                month or the run stops — no silent fallback to an uncorrected
#                splice.
#   QC           corrected IEM is despiked against its own 15-day rolling
#                median and bounded by GHCN's per-month all-record envelope
#                (IEM has no QC flags of its own), and a day where the two
#                feeds contradict each other beyond any plausible processing
#                difference is dropped rather than guessed. See the threshold
#                constants below for the measurements behind all three.
#
# Contract every R/sources/<source>.R module must satisfy: define
# prepare_data(site), which fetches whatever is missing under site$paths$raw,
# slices/normalizes to columns NUM_POSTE, AAAAMMJJ, TN, TX, TNTXM, RR, and
# writes that via write_extract() to site$paths$processed/<STATION_EXTRACT>.
# =============================================================================

# Minimum same-day pairs per calendar month to trust that month's offset.
# All 12 months clear this comfortably (160-320 pairs as of 2026); the guard is
# a tripwire against a future data change that quietly erodes the overlap.
GHCN_IEM_MIN_OVERLAP_DAYS <- 60L

# ---- QC thresholds, from measuring both sites' feeds (2026-09-10) ------------
# IEM's daily summaries carry no QC flags at all (unlike GHCN's QFLAG), and the
# raw METAR archive contains outright garbage: a -22 F September minimum and a
# 59 C January maximum at Hyderabad, 2-3 C monsoon nights at Kathmandu. Real
# weather deviates from a station's 15-day rolling median by at most ~12 C in
# these climates (Kathmandu's winter-fog days, Hyderabad's cyclone days reach
# -11 to -12); the glitches sit at 15-54. Null corrected-IEM values beyond this:
GHCN_IEM_IEM_SPIKE <- 12
# Where BOTH feeds observe the same day, they agree to sd ~1.0-1.4 C after the
# offset correction. A disagreement beyond this (~6 sigma) means one of them is
# wrong, and cheaply deciding which is unreliable — measured cases go both ways
# (GHCN's un-QC'd 49.0 C at Hyderabad 1979-04-27 vs IEM's 38.9 matching the
# neighbouring days; elsewhere IEM is the bad one). Drop the day for that
# element instead of guessing:
GHCN_IEM_MAX_DISAGREE <- 8
# The rolling-median despike misses garbage that is only modestly above the
# surrounding days: a lone corrupt METAR gave Hyderabad 116.6 F (47.0 C) on
# 2019-04-27 among 104-107.6 F neighbours — +5.5 C off the local median, inside
# the real-weather band, yet 4 C above anything the station's 50-year GHCN
# record ever measured in April. So corrected-IEM values are also bounded by
# GHCN's own per-calendar-month all-record envelope, widened by this margin.
# The margin keeps genuine new records: real all-time extremes advance on this
# envelope by tenths of a degree, not by four. GHCN values are not bounded
# (the envelope is circular for them); a bogus GHCN extreme is caught by the
# disagreement rule instead, and excluded from the envelope it would inflate.
GHCN_IEM_ENVELOPE_MARGIN <- 3

# ---- NOAA GHCN-Daily (Access Data Service v1) --------------------------------
# Same endpoint/units as R/sources/noaa.R; replicated (not shared) so this module
# stands alone. `end` is a future sentinel so the file keeps gaining rows (rain,
# and recent temperature) as NOAA publishes, and never needs bumping.
ghcn_iem_fetch_ghcn <- function(base_url, raw_dir, id, start, end) {
  dest <- file.path(raw_dir, sprintf("ghcn_%s_%s_%s.csv", id, start, end))
  if (!file.exists(dest)) {
    url <- sprintf(
      "%s?dataset=daily-summaries&stations=%s&startDate=%s&endDate=%s&format=csv&units=metric&dataTypes=TMAX,TMIN,PRCP&includeAttributes=true",
      base_url, id, start, end)
    fetch_url(url, dest, verify_text, on_404_hint = sprintf(
      "GHCN station %s may not exist or have no data in %s..%s.", id, start, end))
  }
  dest
}

# A non-empty QFLAG means GHCN's own QC rejected the value — null it out (same
# rule as R/sources/noaa.R::noaa_qflag_ok).
ghcn_iem_qflag_ok <- function(attrs) {
  attrs <- as.character(attrs)
  qflag <- vapply(strsplit(attrs, ",", fixed = TRUE), function(x)
    if (length(x) >= 2) x[[2]] else "", character(1))
  is.na(attrs) | qflag == ""
}

ghcn_iem_read_ghcn <- function(path) {
  suppressPackageStartupMessages(library(data.table))
  d <- fread(path)
  tn <- as.numeric(d$TMIN); tx <- as.numeric(d$TMAX); rr <- as.numeric(d$PRCP)
  tn[!ghcn_iem_qflag_ok(d$TMIN_ATTRIBUTES)] <- NA_real_
  tx[!ghcn_iem_qflag_ok(d$TMAX_ATTRIBUTES)] <- NA_real_
  rr[!ghcn_iem_qflag_ok(d$PRCP_ATTRIBUTES)] <- NA_real_
  data.table(AAAAMMJJ = as.integer(gsub("-", "", d$DATE, fixed = TRUE)),
             TN = tn, TX = tx, RR = rr)
}

# ---- Iowa Environmental Mesonet (daily summary from METAR) -------------------
# The daily.py service returns a precomputed daily summary; we take only
# max_temp_f / min_temp_f (F -> C) and ignore its precip, which METAR does not
# measure reliably here. `end` is stamped to today by prepare_data().
ghcn_iem_fetch_iem <- function(raw_dir, network, station, start, today) {
  dest <- file.path(raw_dir, sprintf("iem_%s_%s_to_%s.csv", station, start, today))
  if (!file.exists(dest)) {
    s <- as.integer(unlist(strsplit(start, "-")))   # "YYYY-MM-DD"
    e <- as.integer(unlist(strsplit(today, "-")))
    url <- sprintf(
      paste0("https://mesonet.agron.iastate.edu/cgi-bin/request/daily.py",
             "?network=%s&stations=%s&year1=%d&month1=%d&day1=%d",
             "&year2=%d&month2=%d&day2=%d&format=comma"),
      network, station, s[1], s[2], s[3], e[1], e[2], e[3])
    fetch_url(url, dest, verify_text, on_404_hint = sprintf(
      "IEM station %s (network %s) may not exist, or the daily service changed.",
      station, network))
  }
  dest
}

ghcn_iem_read_iem <- function(path) {
  suppressPackageStartupMessages(library(data.table))
  d <- fread(path, na.strings = c("None", "M", "", "NA"))
  f2c <- function(f) (as.numeric(f) - 32) * 5 / 9
  out <- data.table(AAAAMMJJ = as.integer(gsub("-", "", d$day, fixed = TRUE)),
                    TN = round(f2c(d$min_temp_f), 1),
                    TX = round(f2c(d$max_temp_f), 1))
  out[!(is.na(TN) & is.na(TX))]
}

# ---- homogenization: measure per-month IEM->GHCN offset from same-day pairs --
# Returns a 12-row table (m, offTN, offTX) of mean(IEM - GHCN) per calendar
# month over every day both feeds observed. Stops if any month has fewer than
# GHCN_IEM_MIN_OVERLAP_DAYS pairs, so a shrinking overlap fails loud rather than
# correcting on a handful of days.
ghcn_iem_month_offsets <- function(ghcn, iem) {
  m_of <- function(x) (x %/% 100L) %% 100L
  g <- copy(ghcn)[, m := m_of(AAAAMMJJ)]
  i <- copy(iem)[,  m := m_of(AAAAMMJJ)]
  offs <- rbindlist(lapply(1:12, function(mm) {
    a <- merge(g[m == mm & !is.na(TN), .(AAAAMMJJ, gv = TN)],
               i[m == mm & !is.na(TN), .(AAAAMMJJ, iv = TN)], by = "AAAAMMJJ")
    b <- merge(g[m == mm & !is.na(TX), .(AAAAMMJJ, gv = TX)],
               i[m == mm & !is.na(TX), .(AAAAMMJJ, iv = TX)], by = "AAAAMMJJ")
    data.table(m = mm,
               offTN = mean(a$iv - a$gv), nTN = nrow(a),
               offTX = mean(b$iv - b$gv), nTX = nrow(b))
  }))
  thin <- offs[nTN < GHCN_IEM_MIN_OVERLAP_DAYS | nTX < GHCN_IEM_MIN_OVERLAP_DAYS]
  if (nrow(thin) > 0)
    stop("GHCN<->IEM overlap too thin to homogenize in month(s) ",
         paste(thin$m, collapse = ", "),
         " (need >= ", GHCN_IEM_MIN_OVERLAP_DAYS,
         " same-day pairs each for TN and TX). Overlap has eroded; ",
         "re-check the feeds before trusting a correction.")
  offs[]
}

# Rolling files — both providers gain rows over time (GHCN's rainfall and recent
# temperature; IEM's daily temperature), so both are rolling and refresh-rolling
# re-pulls them. The IEM filename embeds today's date; GHCN runs to its future
# sentinel.
rolling_files <- function(site) {
  gi <- site$ghcn_iem
  today <- format(Sys.Date(), "%Y-%m-%d")
  c(file.path(site$paths$raw, sprintf("ghcn_%s_%s_%s.csv",
              gi$ghcn_id, gi$ghcn_start, gi$ghcn_end)),
    file.path(site$paths$raw, sprintf("iem_%s_%s_to_%s.csv",
              gi$iem_station, gi$iem_start, today)))
}

prepare_data <- function(site) {
  suppressPackageStartupMessages(library(data.table))
  dir.create(site$paths$processed, recursive = TRUE, showWarnings = FALSE)
  dir.create(site$paths$raw,       recursive = TRUE, showWarnings = FALSE)

  gi    <- site$ghcn_iem
  today <- format(Sys.Date(), "%Y-%m-%d")
  sid   <- names(site$stations)[1]   # single physical station: one id

  ghcn_path <- ghcn_iem_fetch_ghcn(gi$ghcn_base_url, site$paths$raw,
                                   gi$ghcn_id, gi$ghcn_start, gi$ghcn_end)
  iem_path  <- ghcn_iem_fetch_iem(site$paths$raw, gi$iem_network,
                                  gi$iem_station, gi$iem_start, today)

  extract_gz <- file.path(site$paths$processed, STATION_EXTRACT)
  inputs <- c(ghcn_path, iem_path, "R/sources/ghcn_iem.R", sprintf("R/sites/%s.R", site$key))
  if (file.exists(extract_gz) &&
      file.info(extract_gz)$mtime >= max(file.info(inputs)$mtime)) {
    message("up to date: ", extract_gz)
    return(invisible(NULL))
  }

  message("Homogenizing GHCN (", gi$ghcn_id, ") + IEM METAR (", gi$iem_station,
          ") for ", site$city, " ...")
  ghcn <- ghcn_iem_read_ghcn(ghcn_path)
  iem  <- ghcn_iem_read_iem(iem_path)

  # 1. Measure the per-month IEM->GHCN scale offset from same-day overlap, and
  #    shift IEM onto GHCN's scale.
  offs <- ghcn_iem_month_offsets(ghcn, iem)
  message(sprintf("  IEM->GHCN offset (mean over months): TN %+.2f C, TX %+.2f C; "
                  , mean(offs$offTN), mean(offs$offTX)),
          sprintf("overlap %d-%d same-day pairs/month",
                  min(offs$nTN, offs$nTX), max(offs$nTN, offs$nTX)))
  iem[, m := (AAAAMMJJ %/% 100L) %% 100L]
  iem <- merge(iem, offs[, .(m, offTN, offTX)], by = "m")
  iem[, `:=`(TN = TN - offTN, TX = TX - offTX, m = NULL, offTN = NULL, offTX = NULL)]

  # 2. QC pass one — despike the corrected IEM feed against its own 15-day
  #    rolling median (see GHCN_IEM_IEM_SPIKE above). GHCN is NOT despiked:
  #    it has its own QC (QFLAG, applied at read time), and a symmetric filter
  #    here would delete real weather — Hyderabad's 2010 cyclone days and
  #    Kathmandu's winter-fog days sit just under the garbage band.
  setorder(iem, AAAAMMJJ)
  n_spike <- integer(0)
  for (v in c("TN", "TX")) {
    ok <- !is.na(iem[[v]])
    dev <- iem[[v]][ok] - runmed(iem[[v]][ok], 15)
    bad <- which(ok)[abs(dev) > GHCN_IEM_IEM_SPIKE]
    n_spike[v] <- length(bad)
    if (length(bad)) set(iem, i = bad, j = v, value = NA_real_)
  }

  # 3. Temperature: real GHCN value wherever it exists, else corrected IEM —
  #    except where the two feeds contradict each other beyond
  #    GHCN_IEM_MAX_DISAGREE, where the day is dropped for that element: two
  #    irreconcilable measurements of the same instrument are an unknown, not
  #    a choice.
  temp <- merge(ghcn[, .(AAAAMMJJ, gTN = TN, gTX = TX)],
                iem [, .(AAAAMMJJ, iTN = TN, iTX = TX)],
                by = "AAAAMMJJ", all = TRUE)
  temp[, disTN := !is.na(gTN) & !is.na(iTN) & abs(gTN - iTN) > GHCN_IEM_MAX_DISAGREE]
  temp[, disTX := !is.na(gTX) & !is.na(iTX) & abs(gTX - iTX) > GHCN_IEM_MAX_DISAGREE]

  # 3b. QC pass two, IEM only — bound corrected IEM by GHCN's per-calendar-month
  #     all-record envelope (see GHCN_IEM_ENVELOPE_MARGIN above), computed with
  #     the disagreement-flagged GHCN values left out so a bogus GHCN extreme
  #     cannot inflate the envelope that exists to catch its IEM twin.
  temp[, m := (AAAAMMJJ %/% 100L) %% 100L]
  env <- temp[, .(loTN = min(gTN[!disTN], na.rm = TRUE), hiTN = max(gTN[!disTN], na.rm = TRUE),
                  loTX = min(gTX[!disTX], na.rm = TRUE), hiTX = max(gTX[!disTX], na.rm = TRUE)),
              by = m]
  temp <- merge(temp, env, by = "m")
  n_env <- c(TN = temp[, sum(!is.na(iTN) &
               (iTN < loTN - GHCN_IEM_ENVELOPE_MARGIN | iTN > hiTN + GHCN_IEM_ENVELOPE_MARGIN))],
             TX = temp[, sum(!is.na(iTX) &
               (iTX < loTX - GHCN_IEM_ENVELOPE_MARGIN | iTX > hiTX + GHCN_IEM_ENVELOPE_MARGIN))])
  temp[!is.na(iTN) & (iTN < loTN - GHCN_IEM_ENVELOPE_MARGIN | iTN > hiTN + GHCN_IEM_ENVELOPE_MARGIN),
       iTN := NA_real_]
  temp[!is.na(iTX) & (iTX < loTX - GHCN_IEM_ENVELOPE_MARGIN | iTX > hiTX + GHCN_IEM_ENVELOPE_MARGIN),
       iTX := NA_real_]

  temp[, TN := fifelse(disTN, NA_real_, fifelse(!is.na(gTN), gTN, iTN))]
  temp[, TX := fifelse(disTX, NA_real_, fifelse(!is.na(gTX), gTX, iTX))]
  message(sprintf("  QC: nulled %d IEM spikes (TN %d, TX %d); dropped %d contradictory days (TN %d, TX %d); %d IEM values outside the GHCN monthly envelope (TN %d, TX %d)",
                  sum(n_spike), n_spike["TN"], n_spike["TX"],
                  sum(temp$disTN) + sum(temp$disTX), sum(temp$disTN), sum(temp$disTX),
                  sum(n_env), n_env["TN"], n_env["TX"]))
  temp <- temp[order(AAAAMMJJ), .(AAAAMMJJ, TN, TX)]

  # 3. Rainfall: GHCN for every date it has one.
  rain <- ghcn[, .(AAAAMMJJ, RR)]

  slice <- merge(temp, rain, by = "AAAAMMJJ", all = TRUE)
  slice[, NUM_POSTE := as.character(sid)]
  slice[, TNTXM := (TN + TX) / 2]
  slice <- slice[!(is.na(TN) & is.na(TX) & is.na(RR)),
                 .(NUM_POSTE, AAAAMMJJ, TN, TX, TNTXM, RR)]

  write_extract(slice, extract_gz)
}
