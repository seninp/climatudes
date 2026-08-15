# Climatudes — local warming, city by city

A small, reproducible analytics pipeline that turns national weather-service
daily records into a readable report on local warming. It currently covers
nine sites, each from its own national open-data source:

| Site | Country | Source |
|---|---|---|
| [Castanet-Tolosan](#a-warming-climate-seen-from-castanet-tolosan) | France | Météo-France |
| [Zurich](#a-warming-climate-seen-from-zurich) | Switzerland | MeteoSwiss |
| [Karlsruhe](#a-warming-climate-seen-from-karlsruhe) | Germany | DWD (Deutscher Wetterdienst) |
| [Santa Fe](#a-warming-climate-seen-from-santa-fe) | USA | NOAA (GHCN-Daily) |
| [Honolulu](#a-warming-climate-seen-from-honolulu) | USA | NOAA (GHCN-Daily) |
| [Nouméa](#a-warming-climate-seen-from-nouméa) | France (New Caledonia) | Météo-France |
| [Moscow](#a-warming-climate-seen-from-moscow) | Russia | Roshydromet (AISORI-M, manual export) |
| [Voronezh](#a-warming-climate-seen-from-voronezh) | Russia | Roshydromet (AISORI-M, manual export) |
| [Irvine](#a-warming-climate-seen-from-irvine) | USA | NOAA (GHCN-Daily) |

<!-- BEGIN COMPARE -->

## All nine cities, side by side

Every chapter below uses the same variables, the same completeness rule (>= 330 valid
days/year) and the same trend method (least-squares on annual means) — the numbers below are those
same headline figures, gathered in one place rather than recomputed. These are raw warming rates:
they are not adjusted for the very different length and era of each record. The record span in the
table is the honest caveat, not a footnote to skip.

![Warming rate compared across all nine cities, ranked fastest to slowest](outputs/compare/figures/warming_rate.png)

<sub>Ranked fastest to slowest. Record span and length for each city are in the table below, not
repeated on the bars — Santa Fe’s and Karlsruhe’s records run a century longer than Honolulu’s or
Nouméa’s, so the same-looking rate rests on very different amounts of evidence.</sub>

| City | Country | Record | Warming rate | Standing | Data current through |
|---|---|---:|---:|---|---|
| Voronezh | Russia | 1940→2025 (85 yr) | **+0.46 °C/decade** | #55 of 84 (2026, Jan 1 – Feb 28) | Feb 28, 2026 † |
| Moscow | Russia | 1949→2025 (76 yr) | **+0.39 °C/decade** | #1 of 77 — record (2025, full year) | Dec 31, 2025 † |
| Castanet-Tolosan | France | 1947→2025 (78 yr) | **+0.34 °C/decade** | #1 of 80 — record (2026, Jan 1 – Aug 13) | Aug 13, 2026 |
| Irvine | USA | 1915→2025 (110 yr) | **+0.27 °C/decade** | #2 of 101 (2026, Jan 1 – May 31) | May 31, 2026 |
| Honolulu | USA | 1950→2025 (75 yr) | **+0.20 °C/decade** | #18 of 84 (2026, Jan 1 – Aug 11) | Aug 11, 2026 |
| Nouméa | France | 1951→2025 (74 yr) | **+0.19 °C/decade** | #5 of 76 (2026, Jan 1 – Aug 14) | Aug 14, 2026 |
| Zurich | Switzerland | 1882→2025 (143 yr) | **+0.18 °C/decade** | #1 of 144 — record (2026, Jan 1 – Aug 13) | Aug 13, 2026 |
| Karlsruhe | Germany | 1876→2025 (149 yr) | **+0.14 °C/decade** | #2 of 150 (2026, Jan 1 – Aug 13) | Aug 13, 2026 |
| Santa Fe | USA | 1874→2025 (151 yr) | **+0.08 °C/decade** | #1 of 149 — record (2026, Jan 1 – Jun 30) | Jun 30, 2026 |

† Moscow and Voronezh are manually exported from Roshydromet’s AISORI-M (login-gated, no automated
refresh) — their "current through" date is not "today" the way the other seven sites’ automated feeds
are; see each city’s own "Why only one station?" note in its chapter below.

Each row’s standing also names its own year and window in parentheses, since they are not all the
same claim: the seven automated sites all rank 2026 over comparable multi-month windows, but Moscow’s
row ranks a complete, already-finished 2025 and Voronezh’s ranks a 59-day midwinter fragment — a
"#55 of 84" over two months of winter is not the same kind of statement as an 8-month "#5 of 76".

<sub>Figures and numbers above are generated — edit `R/04_compare.R`, not this block.</sub>

<!-- END COMPARE -->

Each site's report below is generated. `make all SITE=<site>` (a few seconds,
including the download) refreshes that site's data, rebuilds its five
figures, regenerates its section here from them, and writes a self-contained
`<outputs>/temperature_report.html` you can email or read offline. `make
all-sites` does this for every site. See [How to run](#how-to-run).

<!-- BEGIN REPORT:castanet -->

## A warming climate, seen from Castanet-Tolosan

*Météo-France daily temperature records, 1947 to 2025 — plus 2026 so far.*

Météo-France daily records for the Castanet-Tolosan area tell an unambiguous story:
since the mid-20th century, minimum, maximum and mean temperatures have all risen —
steadily and continuously.

| Headline number | Value |
|---|---:|
| Warming rate, mean temperature (Toulouse-Blagnac) | **+0.34 °C / decade** |
| Total rise over 78 years (1947 → 2025) | **+2.6 °C** |
| Mean of the last decade (vs 12.9 °C in 1947–1956) | **15.2 °C** |
| Frost days per year, 1947–1956 → 2016–2025 | **46 → 18** |
| Hot days (≥ 30 °C) per year, 1947–1956 → 2016–2025 | **24 → 47** |
| Complete station-years analysed | **101** |
| 2026 year-to-date (Jan 1 – Aug 13), against 79 prior years | **#1 of 80 — record** |

### The long view: annual means

![Annual mean temperatures around Castanet-Tolosan, 1947 to 2025](outputs/figures/temperature_series.png)

<sub>Annual means of daily temperatures. The thick curves are LOESS smoothings that
highlight the climate trend; the points are annual means. The green series (Auzeville-Tolosane-INRAE) is the station on the edge of Castanet-Tolosan; it tracks the long Toulouse-Blagnac reference mean almost exactly.</sub>

At Toulouse-Blagnac — the station with the longest record (1947→2025) — the annual
mean temperature rises by **+0.34 °C per decade**, about **+2.6 °C** over the
whole period. The local Auzeville-Tolosane-INRAE station only covers 2004→2025. Its slope over that shorter, more recent window is steeper (+0.83 °C/decade) — but so is Toulouse-Blagnac’s over the same years (+0.91 °C/decade): recent decades warm faster, and the local station sits almost exactly on the regional mean.

### This year, against every year before it

![Per-year mean over the same Jan-to-cutoff window, as a departure from the long-term normal, with 2026 the largest bar](outputs/figures/temperature_ytd.png)

<sub>Each bar is a year’s mean over the <em>same window</em> — <strong>Jan 1 – Aug 13</strong> —
shown as its departure from the long-term normal (13.6 °C): red above, blue
below. Comparing each year over the identical part-of-year is the only fair way to place
any one year against every other. The bars swing from blue to red over
the decades — the warming — and 2026 is the tallest of all.</sub>

Measured like-for-like, **2026 is the warmest Jan 1 – Aug 13 in 80 years** at Toulouse-Blagnac: **16.9 °C** — +0.8 °C above the previous record (2025, 16.1 °C) and **+3.3 °C above the long-term normal** (13.6 °C). This is exactly the point of the chart: a year still in progress can already stand out against the whole record.

> [!NOTE]
> A partial year cannot be compared to other years' full-year means — it is still missing the rest of the year. That is why 2026 appears on the long-view chart above only as a marked, hollow "to date" point (seasonally incomplete, so lower than its eventual annual figure), while its real, like-for-like standing is the chart here.

### Every year, day by day

![Daily temperature climatology, every year January to December, hot years red and cold years blue](outputs/figures/temperature_climatology.png)

<sub>Each thin line is a single year’s daily mean temperature from January to December
(1947–2025, 79 years), smoothed with a centred
<strong>3-day rolling mean</strong> (each day = the average of itself
±1 day) to tame day-to-day jitter while keeping the shape. The dark line
is the long-term daily normal; the bold red line is <strong>2026 so far</strong>.
Years whose smoothed daily mean ever rose above <strong>+30 °C</strong> are
highlighted in red and labelled; years that ever fell below
<strong>-5 °C</strong> in blue.</sub>

> [!NOTE]
> **Hottest and coldest years.** Measured on the smoothed daily-mean curve,
> **5** years pushed above +30 °C (2003, 2019, 2022, 2023, 2025) — all of them recent —
> while **10** years dropped below -5 °C (1947, 1954, 1956, 1960, 1962, 1963, 1971, 1985, 1987, 2012), all but one before 2000.
> No single year managed to hit both extremes. The hot extremes and the cold extremes fall in different eras, which is itself a fingerprint of the warming trend. <sub>(If the threshold is applied instead to the raw, unsmoothed daily mean, 1947 and 1987 each touch both extremes.)</sub>

### The record days

The single most extreme days in each station’s record. “Hottest” is the highest daily
maximum (TX), “coldest” the lowest daily minimum (TN).

| Station (record span) | Extreme | Date | Min (TN) | Max (TX) |
|---|---|---|---:|---:|
| Auzeville-Tolosane-INRAE <sub>2002–2026</sub> | Hottest 🔥 | 2023-08-23 | 21.9 | **42.1** |
| Auzeville-Tolosane-INRAE <sub>2002–2026</sub> | Coldest ❄️ | 2012-02-09 | **-12.1** | -1.4 |
| Toulouse-Blagnac <sub>1947–2026</sub> | Hottest 🔥 | 2023-08-23 | 24.1 | **42.4** |
| Toulouse-Blagnac <sub>1947–2026</sub> | Coldest ❄️ | 1956-02-15 | **-19.2** | -4.1 |

At Toulouse-Blagnac, the all-time heat (2023-08-23) is far more recent than the all-time cold (1956-02-15) — the same warming signature seen throughout this report.

> [!NOTE]
> **Why Auzeville-Tolosane-INRAE?** The Météo-France dataset for department 31 contains no station literally named “Castanet-Tolosan”. The Auzeville-Tolosane-INRAE station (no. 31035001), on the INRAE/ENSAT campus, sits right on the Castanet-Tolosan boundary — the most representative local record. Toulouse-Blagnac (no. 31069001) provides the historical depth needed to see the underlying trend and to draw the day-by-day climatology.

### The last decade (Toulouse-Blagnac)

| Year | Min (TN) | Max (TX) | Mean |
|---|---:|---:|---:|
| 2016 | 10.0 | 19.3 | **14.6** |
| 2017 | 9.7 | 19.5 | **14.6** |
| 2018 | 10.7 | 19.5 | **15.1** |
| 2019 | 10.0 | 19.9 | **15.0** |
| 2020 | 10.6 | 20.2 | **15.4** |
| 2021 | 9.7 | 19.1 | **14.4** |
| 2022 | 11.2 | 21.3 | **16.3** |
| 2023 | 10.7 | 20.8 | **15.7** |
| 2024 | 10.5 | 19.6 | **15.1** |
| 2025 | 10.7 | 20.6 | **15.6** |
| 2026 *(to date)* | 11.6 | 22.2 | **16.9** |

### Frost days down, hot days up

A degree of warming is abstract; the count of extreme days is not. Comparing
Toulouse-Blagnac’s first complete decade (1947–1956) with its last (2016–2025),
the everyday texture of the year has changed sharply:

| Threshold days per year | 1947–1956 | 2016–2025 |
|---|---:|---:|
| Frost days (min < 0 °C) | 46 | **18** |
| Hot days (max ≥ 30 °C) | 24 | **47** |
| Very hot days (max ≥ 35 °C) | 2 | **10** |
| Tropical nights (min ≥ 20 °C) | 4 | **21** |

<sub>Counts of days per year crossing each threshold, averaged over the first and last
complete decades. Frost is retreating just as heat advances — the same warming, read off the calendar instead of the thermometer.</sub>

### What about the rain?

Temperature is only half of a climate. Rainfall tells a very different — and much
quieter — story: over the same 79 years, annual precipitation at
Toulouse-Blagnac shows **no statistically significant trend**.

![Annual rainfall totals around Castanet-Tolosan](outputs/figures/rain_series.png)

<sub>Annual total precipitation. The dashed line is Toulouse-Blagnac’s long-term mean
(633 mm/yr); the thick curves are LOESS smoothings. The year-to-year swings are
large — from 378 mm (1967) to 915 mm (1993) —
but the long-run slope (-8 mm/decade) is flat and not significant (p = 0.16).</sub>

That contrast is the point. The very same daily records that show an unmistakable, statistically strong warming signal show *no* comparable signal in how much it rains. A dataset that manufactured trends would have produced one here too; this one does not.

![Monthly rainfall through the year at Toulouse-Blagnac, one line per year](outputs/figures/rain_climatology.png)

<sub>Rain through the year: each grey line is one year’s monthly totals, the dark line the
long-term monthly normal, the bold blue line 2026 so far. May is the
wettest month on average (72 mm), July the driest
(41 mm) — but the spread between years dwarfs the seasonal cycle, which is exactly why no annual trend emerges.</sub>

### Methodology

- **Source.** Météo-France — Données climatologiques de base – quotidiennes, Haute-Garonne, France. Full citation
  below.
- **Variables.** Minimum = `TN`, maximum = `TX`, mean = `(TN+TX)/2`, in °C;
  rainfall = `RR` (daily precipitation, in mm).
- **Annual aggregation.** Arithmetic mean of daily values over each calendar year. The
  long-term trend uses only complete years (≥ 330 valid days). Where the current
  year is still in progress, it is shown separately — as a hollow “to date” marker on the
  trend chart, and (for a fair record comparison) against the same calendar window
  (Jan 1 → cutoff) of every prior year, keeping only years with ≥ 150 valid
  days in that window.
- **Daily climatology.** Each year’s daily mean is smoothed with a centred
  3-day rolling mean (unweighted moving average, computed per year so
  December never bleeds into January; the first/last 1 day keep their raw
  value) for legibility; leap days are aligned across years. The normal is the per-day
  average over all prior years.
- **Threshold days.** Frost = `TN < 0`, hot day = `TX ≥ 30`, very hot =
  `TX ≥ 35`, tropical night = `TN ≥ 20`, counted per complete year and
  averaged over the first/last complete decade.
- **Rainfall.** Annual total of daily `RR` over complete years; the trend is a
  least-squares slope with its two-sided p-value. Monthly climatology keeps only months
  with ≥ 27 valid days.
- **Trend.** Slope estimated by linear regression (least squares); the line-chart curves
  use LOESS smoothing (span = 0.7).
- **Reproducibility.** A 4-stage R pipeline (`R/00_prepare_data.R` → `R/01_plot.R` →
  `R/02_report.R` → `R/03_readme.R`), driven by `SITE=castanet make all`. The figures
  above and the numbers in this section are regenerated from the source data on every
  run — see [Data source](#data-source--citation) below for the full citation.

<sub>Figures and numbers above are generated — edit `R/03_readme.R`, not this block.</sub>

<!-- END REPORT:castanet -->

<!-- BEGIN REPORT:zurich -->

## A warming climate, seen from Zurich

*MeteoSwiss daily temperature records, 1882 to 2025 — plus 2026 so far.*

MeteoSwiss daily records for the Zurich area tell an unambiguous story:
since the late 19th century, minimum, maximum and mean temperatures have all risen —
steadily and continuously.

| Headline number | Value |
|---|---:|
| Warming rate, mean temperature (Zürich-Fluntern) | **+0.18 °C / decade** |
| Total rise over 143 years (1882 → 2025) | **+2.6 °C** |
| Mean of the last decade (vs 7.9 °C in 1882–1891) | **11.0 °C** |
| Frost days per year, 1882–1891 → 2016–2025 | **111 → 61** |
| Hot days (≥ 30 °C) per year, 1882–1891 → 2016–2025 | **4 → 12** |
| Complete station-years analysed | **190** |
| 2026 year-to-date (Jan 1 – Aug 13), against 143 prior years | **#1 of 144 — record** |

### The long view: annual means

![Annual mean temperatures around Zurich, 1882 to 2025](outputs/zurich/figures/temperature_series.png)

<sub>Annual means of daily temperatures. The thick curves are LOESS smoothings that
highlight the climate trend; the points are annual means. The green series (Zürich-Affoltern) is MeteoSwiss’s automatic station in Zurich’s Affoltern district; it tracks the long Zürich-Fluntern reference mean almost exactly.</sub>

At Zürich-Fluntern — the station with the longest record (1882→2025) — the annual
mean temperature rises by **+0.18 °C per decade**, about **+2.6 °C** over the
whole period. The local Zürich-Affoltern station only covers 1979→2025. Its slope over that shorter, more recent window is steeper (+0.49 °C/decade) — but so is Zürich-Fluntern’s over the same years (+0.50 °C/decade): recent decades warm faster, and the local station sits almost exactly on the regional mean.

### This year, against every year before it

![Per-year mean over the same Jan-to-cutoff window, as a departure from the long-term normal, with 2026 the largest bar](outputs/zurich/figures/temperature_ytd.png)

<sub>Each bar is a year’s mean over the <em>same window</em> — <strong>Jan 1 – Aug 13</strong> —
shown as its departure from the long-term normal (9.4 °C): red above, blue
below. Comparing each year over the identical part-of-year is the only fair way to place
any one year against every other. The bars swing from blue to red over
the decades — the warming — and 2026 is the tallest of all.</sub>

Measured like-for-like, **2026 is the warmest Jan 1 – Aug 13 in 144 years** at Zürich-Fluntern: **12.8 °C** — +0.5 °C above the previous record (2022, 12.3 °C) and **+3.5 °C above the long-term normal** (9.4 °C). This is exactly the point of the chart: a year still in progress can already stand out against the whole record.

> [!NOTE]
> A partial year cannot be compared to other years' full-year means — it is still missing the rest of the year. That is why 2026 appears on the long-view chart above only as a marked, hollow "to date" point (seasonally incomplete, so lower than its eventual annual figure), while its real, like-for-like standing is the chart here.

### Every year, day by day

![Daily temperature climatology, every year January to December, hot years red and cold years blue](outputs/zurich/figures/temperature_climatology.png)

<sub>Each thin line is a single year’s daily mean temperature from January to December
(1881–2025, 145 years), smoothed with a centred
<strong>3-day rolling mean</strong> (each day = the average of itself
±1 day) to tame day-to-day jitter while keeping the shape. The dark line
is the long-term daily normal; the bold red line is <strong>2026 so far</strong>.
Years whose smoothed daily mean ever rose above <strong>+30 °C</strong> are
highlighted in red and labelled; years that ever fell below
<strong>-5 °C</strong> in blue.</sub>

> [!NOTE]
> **Hottest and coldest years.** Measured on the smoothed daily-mean curve,
> **0** years pushed above +30 °C
> while **118** years dropped below -5 °C (1882, 1883, 1885, 1886, 1887, 1888, 1889, 1890, 1891, 1892, 1893, 1894, 1895, 1896, 1897, 1898, 1899, 1900, 1901, 1902, 1903, 1904, 1905, 1906, 1907, 1908, 1909, 1911, 1912, 1914, 1915, 1917, 1918, 1919, 1920, 1921, 1922, 1923, 1924, 1925, 1926, 1927, 1929, 1930, 1931, 1932, 1933, 1934, 1935, 1936, 1937, 1938, 1939, 1940, 1941, 1942, 1944, 1945, 1946, 1947, 1948, 1949, 1950, 1952, 1953, 1954, 1956, 1957, 1958, 1960, 1961, 1962, 1963, 1964, 1966, 1967, 1968, 1969, 1970, 1971, 1972, 1973, 1975, 1976, 1979, 1980, 1981, 1982, 1983, 1984, 1985, 1986, 1987, 1988, 1991, 1992, 1993, 1995, 1996, 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2005, 2006, 2007, 2009, 2010, 2012, 2013, 2014, 2017, 2018, 2021, 2022).
> No single year managed to hit both extremes.  <sub>(On the raw, unsmoothed daily mean, no year touches both extremes.)</sub>

### The record days

The single most extreme days in each station’s record. “Hottest” is the highest daily
maximum (TX), “coldest” the lowest daily minimum (TN).

| Station (record span) | Extreme | Date | Min (TN) | Max (TX) |
|---|---|---|---:|---:|
| Zürich-Fluntern <sub>1881–2026</sub> | Hottest 🔥 | 2026-06-27 | 21.6 | **37.1** |
| Zürich-Fluntern <sub>1881–2026</sub> | Coldest ❄️ | 1929-02-12 | **-24.7** | -16.3 |
| Zürich-Affoltern <sub>1978–2026</sub> | Hottest 🔥 | 2026-07-30 | 15.4 | **37.5** |
| Zürich-Affoltern <sub>1978–2026</sub> | Coldest ❄️ | 1985-01-09 | **-26.6** | -12.9 |

At Zürich-Fluntern, the all-time heat (2026-06-27) is far more recent than the all-time cold (1929-02-12) — the same warming signature seen throughout this report.

> [!NOTE]
> **Why Zürich-Affoltern?** MeteoSwiss’s homogeneous long-term series (Swiss NBCN) covers only about thirty stations nationwide; Affoltern — a district in the north of Zurich — isn’t one of them. REH, MeteoSwiss’s automatic station there, is the closest full station to that neighbourhood and has carried temperature since 1978. Zürich-Fluntern (station SMA), in the hills above the city centre, provides the historical depth — a homogeneous record back to 1881 — needed to see the underlying trend and to draw the day-by-day climatology.

### The last decade (Zürich-Fluntern)

| Year | Min (TN) | Max (TX) | Mean |
|---|---:|---:|---:|
| 2016 | 6.5 | 14.1 | **10.3** |
| 2017 | 6.5 | 14.6 | **10.6** |
| 2018 | 7.4 | 15.6 | **11.5** |
| 2019 | 6.8 | 14.9 | **10.9** |
| 2020 | 6.9 | 15.4 | **11.2** |
| 2021 | 6.1 | 13.8 | **9.9** |
| 2022 | 7.6 | 16.1 | **11.8** |
| 2023 | 7.8 | 15.8 | **11.8** |
| 2024 | 7.7 | 15.0 | **11.4** |
| 2025 | 7.0 | 14.9 | **11.0** |
| 2026 *(to date)* | 7.9 | 17.8 | **12.8** |

### Frost days down, hot days up

A degree of warming is abstract; the count of extreme days is not. Comparing
Zürich-Fluntern’s first complete decade (1882–1891) with its last (2016–2025),
the everyday texture of the year has changed sharply:

| Threshold days per year | 1882–1891 | 2016–2025 |
|---|---:|---:|
| Frost days (min < 0 °C) | 111 | **61** |
| Hot days (max ≥ 30 °C) | 4 | **12** |
| Very hot days (max ≥ 35 °C) | 0 | **0** |
| Tropical nights (min ≥ 20 °C) | 0 | **2** |

<sub>Counts of days per year crossing each threshold, averaged over the first and last
complete decades. Frost is retreating just as heat advances — the same warming, read off the calendar instead of the thermometer.</sub>

### What about the rain?

Temperature is only half of a climate. Rainfall tells a very different — and much
quieter — story: over the same 162 years, annual precipitation at
Zürich-Fluntern shows **no statistically significant trend**.

![Annual rainfall totals around Zurich](outputs/zurich/figures/rain_series.png)

<sub>Annual total precipitation. The dashed line is Zürich-Fluntern’s long-term mean
(1104 mm/yr); the thick curves are LOESS smoothings. The year-to-year swings are
large — from 674 mm (1949) to 1988 mm (1876) —
but the long-run slope (-1 mm/decade) is flat and not significant (p = 0.77).</sub>

That contrast is the point. The very same daily records that show an unmistakable, statistically strong warming signal show *no* comparable signal in how much it rains. A dataset that manufactured trends would have produced one here too; this one does not.

![Monthly rainfall through the year at Zürich-Fluntern, one line per year](outputs/zurich/figures/rain_climatology.png)

<sub>Rain through the year: each grey line is one year’s monthly totals, the dark line the
long-term monthly normal, the bold blue line 2026 so far. June is the
wettest month on average (128 mm), February the driest
(61 mm) — but the spread between years dwarfs the seasonal cycle, which is exactly why no annual trend emerges.</sub>

### Methodology

- **Source.** MeteoSwiss — Open Government Data — climate stations (NBCN) & automatic weather stations (SMN), Kanton Zürich, Switzerland. Full citation
  below.
- **Variables.** Minimum = `TN`, maximum = `TX`, mean = `(TN+TX)/2`, in °C;
  rainfall = `RR` (daily precipitation, in mm).
- **Annual aggregation.** Arithmetic mean of daily values over each calendar year. The
  long-term trend uses only complete years (≥ 330 valid days). Where the current
  year is still in progress, it is shown separately — as a hollow “to date” marker on the
  trend chart, and (for a fair record comparison) against the same calendar window
  (Jan 1 → cutoff) of every prior year, keeping only years with ≥ 150 valid
  days in that window.
- **Daily climatology.** Each year’s daily mean is smoothed with a centred
  3-day rolling mean (unweighted moving average, computed per year so
  December never bleeds into January; the first/last 1 day keep their raw
  value) for legibility; leap days are aligned across years. The normal is the per-day
  average over all prior years.
- **Threshold days.** Frost = `TN < 0`, hot day = `TX ≥ 30`, very hot =
  `TX ≥ 35`, tropical night = `TN ≥ 20`, counted per complete year and
  averaged over the first/last complete decade.
- **Rainfall.** Annual total of daily `RR` over complete years; the trend is a
  least-squares slope with its two-sided p-value. Monthly climatology keeps only months
  with ≥ 27 valid days.
- **Trend.** Slope estimated by linear regression (least squares); the line-chart curves
  use LOESS smoothing (span = 0.7).
- **Reproducibility.** A 4-stage R pipeline (`R/00_prepare_data.R` → `R/01_plot.R` →
  `R/02_report.R` → `R/03_readme.R`), driven by `SITE=zurich make all`. The figures
  above and the numbers in this section are regenerated from the source data on every
  run — see [Data source](#data-source--citation) below for the full citation.

<sub>Figures and numbers above are generated — edit `R/03_readme.R`, not this block.</sub>

<!-- END REPORT:zurich -->

<!-- BEGIN REPORT:karlsruhe -->

## A warming climate, seen from Karlsruhe

*DWD (Deutscher Wetterdienst) daily temperature records, 1876 to 2025 — plus 2026 so far.*

DWD (Deutscher Wetterdienst) daily records for the Karlsruhe area tell an unambiguous story:
since the late 19th century, minimum, maximum and mean temperatures have all risen —
steadily and continuously.

| Headline number | Value |
|---|---:|
| Warming rate, mean temperature (Rheinstetten) | **+0.14 °C / decade** |
| Total rise over 149 years (1876 → 2025) | **+2.1 °C** |
| Mean of the last decade (vs 9.8 °C in 1876–1885) | **11.9 °C** |
| Frost days per year, 1876–1885 → 2016–2025 | **67 → 59** |
| Hot days (≥ 30 °C) per year, 1876–1885 → 2016–2025 | **7 → 26** |
| Complete station-years analysed | **148** |
| 2026 year-to-date (Jan 1 – Aug 13), against 149 prior years | **#2 of 150** |

### The long view: annual means

![Annual mean temperatures around Karlsruhe, 1876 to 2025](outputs/karlsruhe/figures/temperature_series.png)

<sub>Annual means of daily temperatures. The thick curves are LOESS smoothings that
highlight the climate trend; the points are annual means.</sub>

At Rheinstetten — the station with the longest record (1876→2025) — the annual
mean temperature rises by **+0.14 °C per decade**, about **+2.1 °C** over the
whole period. Karlsruhe-Wolfartsweier carries no temperature record; Rheinstetten alone provides the temperature trend for this area. The local comparison here uses rainfall instead — see below.

### This year, against every year before it

![Per-year mean over the same Jan-to-cutoff window, as a departure from the long-term normal, with 2026 highlighted](outputs/karlsruhe/figures/temperature_ytd.png)

<sub>Each bar is a year’s mean over the <em>same window</em> — <strong>Jan 1 – Aug 13</strong> —
shown as its departure from the long-term normal (11.0 °C): red above, blue
below. Comparing each year over the identical part-of-year is the only fair way to place
any one year against every other. The bars swing from blue to red over
the decades — the warming.</sub>

Measured like-for-like over Jan 1 – Aug 13, 2026 currently ranks **#2 of 150** at Rheinstetten (13.3 °C). The warmest such window on record remains 2007 (13.6 °C).

> [!NOTE]
> A partial year cannot be compared to other years' full-year means — it is still missing the rest of the year. That is why 2026 appears on the long-view chart above only as a marked, hollow "to date" point (seasonally incomplete, so lower than its eventual annual figure), while its real, like-for-like standing is the chart here.

### Every year, day by day

![Daily temperature climatology, every year January to December, hot years red and cold years blue](outputs/karlsruhe/figures/temperature_climatology.png)

<sub>Each thin line is a single year’s daily mean temperature from January to December
(1876–2025, 150 years), smoothed with a centred
<strong>3-day rolling mean</strong> (each day = the average of itself
±1 day) to tame day-to-day jitter while keeping the shape. The dark line
is the long-term daily normal; the bold red line is <strong>2026 so far</strong>.
Years whose smoothed daily mean ever rose above <strong>+30 °C</strong> are
highlighted in red and labelled; years that ever fell below
<strong>-5 °C</strong> in blue.</sub>

> [!NOTE]
> **Hottest and coldest years.** Measured on the smoothed daily-mean curve,
> **0** years pushed above +30 °C
> while **107** years dropped below -5 °C (1876, 1878, 1879, 1880, 1881, 1882, 1883, 1885, 1886, 1887, 1888, 1889, 1890, 1891, 1892, 1893, 1894, 1895, 1896, 1899, 1901, 1902, 1903, 1904, 1905, 1906, 1907, 1908, 1909, 1911, 1912, 1914, 1915, 1917, 1918, 1919, 1920, 1921, 1922, 1923, 1924, 1925, 1926, 1927, 1929, 1931, 1932, 1933, 1934, 1935, 1938, 1939, 1940, 1941, 1942, 1943, 1945, 1946, 1947, 1948, 1950, 1952, 1953, 1954, 1956, 1957, 1959, 1960, 1961, 1962, 1963, 1964, 1966, 1967, 1968, 1969, 1970, 1971, 1972, 1973, 1976, 1978, 1979, 1980, 1981, 1982, 1985, 1986, 1987, 1991, 1992, 1993, 1995, 1996, 1997, 2002, 2003, 2005, 2006, 2009, 2010, 2011, 2012, 2017, 2018, 2021, 2022).
> No single year managed to hit both extremes.  <sub>(If the threshold is applied instead to the raw, unsmoothed daily mean, 1952 and 2003 each touch both extremes.)</sub>

### The record days

The single most extreme days in each station’s record. “Hottest” is the highest daily
maximum (TX), “coldest” the lowest daily minimum (TN).

| Station (record span) | Extreme | Date | Min (TN) | Max (TX) |
|---|---|---|---:|---:|
| Rheinstetten <sub>1876–2026</sub> | Hottest 🔥 | 2026-06-27 | 20.7 | **40.5** |
| Rheinstetten <sub>1876–2026</sub> | Coldest ❄️ | 1940-01-18 | **-25.4** | -12.5 |

At Rheinstetten, the all-time heat (2026-06-27) is far more recent than the all-time cold (1940-01-18) — the same warming signature seen throughout this report.

> [!NOTE]
> **Why Karlsruhe-Wolfartsweier?** No active DWD station near Grötzingen — a district on Karlsruhe’s eastern edge — carries a temperature record; the nearest that once did (Augustenberg, under 1 km away) closed in 1985. Karlsruhe-Wolfartsweier (station 02523), 5.4 km away and active since 1931, is the nearest active rain gauge and stands in for local rainfall. Rheinstetten (station 04177) provides the temperature trend, spliced with its in-city predecessor (02522, 1876–2008) for the historical depth needed to see the underlying trend.

### The last decade (Rheinstetten)

| Year | Min (TN) | Max (TX) | Mean |
|---|---:|---:|---:|
| 2016 | 6.6 | 15.8 | **11.2** |
| 2017 | 6.6 | 16.5 | **11.5** |
| 2018 | 7.1 | 17.7 | **12.4** |
| 2019 | 6.5 | 17.0 | **11.8** |
| 2020 | 6.7 | 17.6 | **12.1** |
| 2021 | 5.9 | 15.5 | **10.7** |
| 2022 | 7.1 | 17.9 | **12.5** |
| 2023 | 7.9 | 17.6 | **12.8** |
| 2024 | 7.7 | 16.9 | **12.3** |
| 2025 | 6.3 | 17.0 | **11.6** |
| 2026 *(to date)* | 7.1 | 19.5 | **13.3** |

### Frost days down, hot days up

A degree of warming is abstract; the count of extreme days is not. Comparing
Rheinstetten’s first complete decade (1876–1885) with its last (2016–2025),
the everyday texture of the year has changed sharply:

| Threshold days per year | 1876–1885 | 2016–2025 |
|---|---:|---:|
| Frost days (min < 0 °C) | 67 | **59** |
| Hot days (max ≥ 30 °C) | 7 | **26** |
| Very hot days (max ≥ 35 °C) | 0 | **3** |
| Tropical nights (min ≥ 20 °C) | 1 | **1** |

<sub>Counts of days per year crossing each threshold, averaged over the first and last
complete decades. Frost is retreating just as heat advances — the same warming, read off the calendar instead of the thermometer.</sub>

### What about the rain?

Temperature is only half of a climate. Rainfall tells a very different — and much
quieter — story: over the same 148 years, annual precipitation at
Rheinstetten shows **a statistically significant trend (-11 mm/decade, p = 0.00)**.

![Annual rainfall totals around Karlsruhe](outputs/karlsruhe/figures/rain_series.png)

<sub>Annual total precipitation. The dashed line is Rheinstetten’s long-term mean
(793 mm/yr); the thick curves are LOESS smoothings. The year-to-year swings are
large — from 456 mm (1959) to 1452 mm (1882) —
but the long-run slope (-11 mm/decade) is measurable and statistically significant (p = 0.00).</sub>

Rainfall tells its own story here: Rheinstetten shows a real, if much smaller and slower, long-run trend toward drier conditions (-11 mm/decade, p = 0.00) — alongside the much larger and faster warming signal above.

![Monthly rainfall through the year at Rheinstetten, one line per year](outputs/karlsruhe/figures/rain_climatology.png)

<sub>Rain through the year: each grey line is one year’s monthly totals, the dark line the
long-term monthly normal, the bold blue line 2026 so far. June is the
wettest month on average (82 mm), February the driest
(52 mm) — but the spread between years is why that slow trend is easy to miss from the monthly shape alone.</sub>

### Methodology

- **Source.** DWD (Deutscher Wetterdienst) — Climate Data Center — daily station observations (KL) & precipitation (RR), Baden-Württemberg, Germany. Full citation
  below.
- **Variables.** Minimum = `TN`, maximum = `TX`, mean = `(TN+TX)/2`, in °C;
  rainfall = `RR` (daily precipitation, in mm).
- **Annual aggregation.** Arithmetic mean of daily values over each calendar year. The
  long-term trend uses only complete years (≥ 330 valid days). Where the current
  year is still in progress, it is shown separately — as a hollow “to date” marker on the
  trend chart, and (for a fair record comparison) against the same calendar window
  (Jan 1 → cutoff) of every prior year, keeping only years with ≥ 150 valid
  days in that window.
- **Daily climatology.** Each year’s daily mean is smoothed with a centred
  3-day rolling mean (unweighted moving average, computed per year so
  December never bleeds into January; the first/last 1 day keep their raw
  value) for legibility; leap days are aligned across years. The normal is the per-day
  average over all prior years.
- **Threshold days.** Frost = `TN < 0`, hot day = `TX ≥ 30`, very hot =
  `TX ≥ 35`, tropical night = `TN ≥ 20`, counted per complete year and
  averaged over the first/last complete decade.
- **Rainfall.** Annual total of daily `RR` over complete years; the trend is a
  least-squares slope with its two-sided p-value. Monthly climatology keeps only months
  with ≥ 27 valid days.
- **Trend.** Slope estimated by linear regression (least squares); the line-chart curves
  use LOESS smoothing (span = 0.7).
- **Reproducibility.** A 4-stage R pipeline (`R/00_prepare_data.R` → `R/01_plot.R` →
  `R/02_report.R` → `R/03_readme.R`), driven by `SITE=karlsruhe make all`. The figures
  above and the numbers in this section are regenerated from the source data on every
  run — see [Data source](#data-source--citation) below for the full citation.

<sub>Figures and numbers above are generated — edit `R/03_readme.R`, not this block.</sub>

<!-- END REPORT:karlsruhe -->

<!-- BEGIN REPORT:santafe -->

## A warming climate, seen from Santa Fe

*NOAA (National Centers for Environmental Information) daily temperature records, 1874 to 2025 — plus 2026 so far.*

NOAA (National Centers for Environmental Information) daily records for the Santa Fe area tell an unambiguous story:
since the late 19th century, minimum, maximum and mean temperatures have all risen —
steadily and continuously.

| Headline number | Value |
|---|---:|
| Warming rate, mean temperature (Santa Fe) | **+0.08 °C / decade** |
| Total rise over 151 years (1874 → 2025) | **+1.2 °C** |
| Mean of the last decade (vs 9.5 °C in 1874–1883) | **10.7 °C** |
| Frost days per year, 1874–1883 → 2016–2025 | **150 → 157** |
| Hot days (≥ 30 °C) per year, 1874–1883 → 2016–2025 | **25 → 59** |
| Complete station-years analysed | **182** |
| 2026 year-to-date (Jan 1 – Jun 30), against 148 prior years | **#1 of 149 — record** |

### The long view: annual means

![Annual mean temperatures around Santa Fe, 1874 to 2025](outputs/santafe/figures/temperature_series.png)

<sub>Annual means of daily temperatures. The thick curves are LOESS smoothings that
highlight the climate trend; the points are annual means. The green series (Santa Fe Airport) is Santa Fe County Municipal Airport, a few miles southwest of downtown; it tracks the long Santa Fe reference mean almost exactly.</sub>

At Santa Fe — the station with the longest record (1874→2025) — the annual
mean temperature rises by **+0.08 °C per decade**, about **+1.2 °C** over the
whole period. The local Santa Fe Airport station only covers 1942→2025. Its slope over that shorter, more recent window is steeper (+0.16 °C/decade) — but so is Santa Fe’s over the same years (+0.11 °C/decade): recent decades warm faster, and the local station sits almost exactly on the regional mean.

### This year, against every year before it

![Per-year mean over the same Jan-to-cutoff window, as a departure from the long-term normal, with 2026 the largest bar](outputs/santafe/figures/temperature_ytd.png)

<sub>Each bar is a year’s mean over the <em>same window</em> — <strong>Jan 1 – Jun 30</strong> —
shown as its departure from the long-term normal (7.7 °C): red above, blue
below. Comparing each year over the identical part-of-year is the only fair way to place
any one year against every other. The bars swing from blue to red over
the decades — the warming — and 2026 is the tallest of all.</sub>

Measured like-for-like, **2026 is the warmest Jan 1 – Jun 30 in 149 years** at Santa Fe: **10.9 °C** — +0.3 °C above the previous record (1879, 10.6 °C) and **+3.3 °C above the long-term normal** (7.7 °C). This is exactly the point of the chart: a year still in progress can already stand out against the whole record.

> [!NOTE]
> A partial year cannot be compared to other years' full-year means — it is still missing the rest of the year. That is why 2026 appears on the long-view chart above only as a marked, hollow "to date" point (seasonally incomplete, so lower than its eventual annual figure), while its real, like-for-like standing is the chart here.

### Every year, day by day

![Daily temperature climatology, every year January to December, hot years red and cold years blue](outputs/santafe/figures/temperature_climatology.png)

<sub>Each thin line is a single year’s daily mean temperature from January to December
(1874–2025, 152 years), smoothed with a centred
<strong>3-day rolling mean</strong> (each day = the average of itself
±1 day) to tame day-to-day jitter while keeping the shape. The dark line
is the long-term daily normal; the bold red line is <strong>2026 so far</strong>.
Years whose smoothed daily mean ever rose above <strong>+30 °C</strong> are
highlighted in red and labelled; years that ever fell below
<strong>-5 °C</strong> in blue.</sub>

> [!NOTE]
> **Hottest and coldest years.** Measured on the smoothed daily-mean curve,
> **0** years pushed above +30 °C
> while **148** years dropped below -5 °C (1874, 1875, 1876, 1877, 1878, 1879, 1880, 1881, 1882, 1883, 1884, 1885, 1886, 1887, 1888, 1889, 1890, 1891, 1892, 1893, 1894, 1895, 1896, 1897, 1898, 1899, 1900, 1901, 1902, 1903, 1904, 1905, 1906, 1907, 1908, 1909, 1910, 1911, 1912, 1913, 1914, 1915, 1916, 1917, 1918, 1919, 1920, 1921, 1922, 1923, 1924, 1925, 1926, 1927, 1928, 1929, 1930, 1931, 1932, 1933, 1934, 1935, 1936, 1937, 1938, 1939, 1940, 1941, 1942, 1944, 1945, 1946, 1947, 1948, 1949, 1950, 1951, 1952, 1953, 1954, 1955, 1956, 1957, 1958, 1959, 1960, 1961, 1962, 1963, 1964, 1965, 1966, 1967, 1968, 1969, 1970, 1971, 1972, 1973, 1974, 1975, 1976, 1977, 1978, 1979, 1982, 1983, 1984, 1985, 1986, 1987, 1988, 1989, 1990, 1991, 1992, 1993, 1994, 1995, 1996, 1997, 1998, 2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025).
> No single year managed to hit both extremes.  <sub>(On the raw, unsmoothed daily mean, no year touches both extremes.)</sub>

### The record days

The single most extreme days in each station’s record. “Hottest” is the highest daily
maximum (TX), “coldest” the lowest daily minimum (TN).

| Station (record span) | Extreme | Date | Min (TN) | Max (TX) |
|---|---|---|---:|---:|
| Santa Fe <sub>1874–2026</sub> | Hottest 🔥 | 1994-06-26 | 13.9 | **37.2** |
| Santa Fe <sub>1874–2026</sub> | Coldest ❄️ | 2011-02-03 | **-31.1** | -11.1 |
| Santa Fe Airport <sub>1941–2026</sub> | Hottest 🔥 | 2013-06-27 | 18.3 | **38.9** |
| Santa Fe Airport <sub>1941–2026</sub> | Coldest ❄️ | 2011-02-03 | **-27.7** | -8.8 |

At Santa Fe, the all-time cold (2011-02-03) is actually more recent than the all-time heat (1994-06-26) — a reminder that a single record day is noisy compared to the mean trend shown throughout this report.

> [!NOTE]
> **Why Santa Fe Airport?** Santa Fe Airport (station USW00023049), a few miles southwest of downtown, is the nearest continuously-sited station and provides the local comparison. NOAA's own GHCN-Daily archive has no digitized daily temperature for it between 1959 and 1996 — a real gap in the upstream record, not a fetch issue here — so its trend uses only the complete years on either side. The reference series, labelled “Santa Fe”, splices the city's original in-town COOP station (298072, 1874–1972) with its direct successor a few miles south (298085, 1972–2026) for one gap-free record back to 1874.

### The last decade (Santa Fe)

| Year | Min (TN) | Max (TX) | Mean |
|---|---:|---:|---:|
| 2016 | 2.0 | 18.9 | **10.5** |
| 2017 | 2.8 | 19.8 | **11.3** |
| 2018 | 2.2 | 19.3 | **10.8** |
| 2019 | 1.4 | 18.1 | **9.8** |
| 2020 | 1.8 | 19.5 | **10.7** |
| 2021 | 2.0 | 19.1 | **10.6** |
| 2022 | 1.6 | 18.3 | **10.0** |
| 2023 | 2.1 | 18.5 | **10.3** |
| 2024 | 2.5 | 19.9 | **11.2** |
| 2025 | 2.8 | 20.2 | **11.5** |
| 2026 *(to date)* | 1.7 | 20.2 | **10.9** |

### Frost days up, hot days up

A degree of warming is abstract; the count of extreme days is not. Comparing
Santa Fe’s first complete decade (1874–1883) with its last (2016–2025),
the everyday texture of the year has changed sharply:

| Threshold days per year | 1874–1883 | 2016–2025 |
|---|---:|---:|
| Frost days (min < 0 °C) | 150 | **157** |
| Hot days (max ≥ 30 °C) | 25 | **59** |
| Very hot days (max ≥ 35 °C) | 1 | **6** |
| Tropical nights (min ≥ 20 °C) | 0 | **0** |

<sub>Counts of days per year crossing each threshold, averaged over the first and last
complete decades. Both counts have risen here — a reminder that year-to-year extreme-day counts are noisy even where the underlying mean trend, shown above, is unambiguous.</sub>

### What about the rain?

Temperature is only half of a climate. Rainfall tells a very different — and much
quieter — story: over the same 144 years, annual precipitation at
Santa Fe shows **a statistically significant trend (-3 mm/decade, p = 0.04)**.

![Annual rainfall totals around Santa Fe](outputs/santafe/figures/rain_series.png)

<sub>Annual total precipitation. The dashed line is Santa Fe’s long-term mean
(346 mm/yr); the thick curves are LOESS smoothings. The year-to-year swings are
large — from 70 mm (1883) to 553 mm (1881) —
but the long-run slope (-3 mm/decade) is measurable and statistically significant (p = 0.04).</sub>

Rainfall tells its own story here: Santa Fe shows a real, if much smaller and slower, long-run trend toward drier conditions (-3 mm/decade, p = 0.04) — alongside the much larger and faster warming signal above.

![Monthly rainfall through the year at Santa Fe, one line per year](outputs/santafe/figures/rain_climatology.png)

<sub>Rain through the year: each grey line is one year’s monthly totals, the dark line the
long-term monthly normal, the bold blue line 2026 so far. July is the
wettest month on average (59 mm), January the driest
(16 mm) — but the spread between years is why that slow trend is easy to miss from the monthly shape alone.</sub>

### Methodology

- **Source.** NOAA (National Centers for Environmental Information) — GHCN-Daily — Global Historical Climatology Network, daily summaries, New Mexico, USA. Full citation
  below.
- **Variables.** Minimum = `TN`, maximum = `TX`, mean = `(TN+TX)/2`, in °C;
  rainfall = `RR` (daily precipitation, in mm).
- **Annual aggregation.** Arithmetic mean of daily values over each calendar year. The
  long-term trend uses only complete years (≥ 330 valid days). Where the current
  year is still in progress, it is shown separately — as a hollow “to date” marker on the
  trend chart, and (for a fair record comparison) against the same calendar window
  (Jan 1 → cutoff) of every prior year, keeping only years with ≥ 150 valid
  days in that window.
- **Daily climatology.** Each year’s daily mean is smoothed with a centred
  3-day rolling mean (unweighted moving average, computed per year so
  December never bleeds into January; the first/last 1 day keep their raw
  value) for legibility; leap days are aligned across years. The normal is the per-day
  average over all prior years.
- **Threshold days.** Frost = `TN < 0`, hot day = `TX ≥ 30`, very hot =
  `TX ≥ 35`, tropical night = `TN ≥ 20`, counted per complete year and
  averaged over the first/last complete decade.
- **Rainfall.** Annual total of daily `RR` over complete years; the trend is a
  least-squares slope with its two-sided p-value. Monthly climatology keeps only months
  with ≥ 27 valid days.
- **Trend.** Slope estimated by linear regression (least squares); the line-chart curves
  use LOESS smoothing (span = 0.7).
- **Reproducibility.** A 4-stage R pipeline (`R/00_prepare_data.R` → `R/01_plot.R` →
  `R/02_report.R` → `R/03_readme.R`), driven by `SITE=santafe make all`. The figures
  above and the numbers in this section are regenerated from the source data on every
  run — see [Data source](#data-source--citation) below for the full citation.

<sub>Figures and numbers above are generated — edit `R/03_readme.R`, not this block.</sub>

<!-- END REPORT:santafe -->

<!-- BEGIN REPORT:honolulu -->

## A warming climate, seen from Honolulu

*NOAA (National Centers for Environmental Information) daily temperature records, 1950 to 2025 — plus 2026 so far.*

NOAA (National Centers for Environmental Information) daily records for the Honolulu area tell an unambiguous story:
since the mid-20th century, minimum, maximum and mean temperatures have all risen —
steadily and continuously.

| Headline number | Value |
|---|---:|
| Warming rate, mean temperature (Honolulu Airport) | **+0.20 °C / decade** |
| Total rise over 75 years (1950 → 2025) | **+1.5 °C** |
| Mean of the last decade (vs 24.3 °C in 1950–1959) | **25.9 °C** |
| Frost days per year, 1950–1959 → 2016–2025 | **0 → 0** |
| Hot days (≥ 30 °C) per year, 1950–1959 → 2016–2025 | **42 → 175** |
| Complete station-years analysed | **76** |
| 2026 year-to-date (Jan 1 – Aug 11), against 83 prior years | **#18 of 84** |

### The long view: annual means

![Annual mean temperatures around Honolulu, 1950 to 2025](outputs/honolulu/figures/temperature_series.png)

<sub>Annual means of daily temperatures. The thick curves are LOESS smoothings that
highlight the climate trend; the points are annual means.</sub>

At Honolulu Airport — the station with the longest record (1950→2025) — the annual
mean temperature rises by **+0.20 °C per decade**, about **+1.5 °C** over the
whole period. Honolulu-Moanalua carries no temperature record; Honolulu Airport alone provides the temperature trend for this area. The local comparison here uses rainfall instead — see below.

### This year, against every year before it

![Per-year mean over the same Jan-to-cutoff window, as a departure from the long-term normal, with 2026 highlighted](outputs/honolulu/figures/temperature_ytd.png)

<sub>Each bar is a year’s mean over the <em>same window</em> — <strong>Jan 1 – Aug 11</strong> —
shown as its departure from the long-term normal (24.8 °C): red above, blue
below. Comparing each year over the identical part-of-year is the only fair way to place
any one year against every other. The bars swing from blue to red over
the decades — the warming.</sub>

Measured like-for-like over Jan 1 – Aug 11, 2026 currently ranks **#18 of 84** at Honolulu Airport (25.3 °C). The warmest such window on record remains 2025 (26.0 °C).

> [!NOTE]
> A partial year cannot be compared to other years' full-year means — it is still missing the rest of the year. That is why 2026 appears on the long-view chart above only as a marked, hollow "to date" point (seasonally incomplete, so lower than its eventual annual figure), while its real, like-for-like standing is the chart here.

### Every year, day by day

![Daily temperature climatology, every year January to December, hot years red and cold years blue](outputs/honolulu/figures/temperature_climatology.png)

<sub>Each thin line is a single year’s daily mean temperature from January to December
(1940–2025, 86 years), smoothed with a centred
<strong>3-day rolling mean</strong> (each day = the average of itself
±1 day) to tame day-to-day jitter while keeping the shape. The dark line
is the long-term daily normal; the bold red line is <strong>2026 so far</strong>.
Years whose smoothed daily mean ever rose above <strong>+30 °C</strong> are
highlighted in red and labelled; years that ever fell below
<strong>-5 °C</strong> in blue.</sub>

> [!NOTE]
> **Hottest and coldest years.** Measured on the smoothed daily-mean curve,
> **2** years pushed above +30 °C (1987, 2019)
> while **0** years dropped below -5 °C.
> No single year managed to hit both extremes.  <sub>(On the raw, unsmoothed daily mean, no year touches both extremes.)</sub>

### The record days

The single most extreme days in each station’s record. “Hottest” is the highest daily
maximum (TX), “coldest” the lowest daily minimum (TN).

| Station (record span) | Extreme | Date | Min (TN) | Max (TX) |
|---|---|---|---:|---:|
| Honolulu Airport <sub>1940–2026</sub> | Hottest 🔥 | 1994-09-19 | 25.6 | **35.0** |
| Honolulu Airport <sub>1940–2026</sub> | Coldest ❄️ | 1969-01-20 | **11.1** | 23.9 |

At Honolulu Airport, the all-time heat (1994-09-19) is far more recent than the all-time cold (1969-01-20) — the same warming signature seen throughout this report.

> [!NOTE]
> **Why Honolulu-Moanalua?** No other digitized GHCN-Daily station near Honolulu carries a temperature record independent of the airport. Moanalua (station USC00516395), a valley neighbourhood between the airport and downtown, has recorded rainfall since 1905 — 107 complete years of 122 — and stands in for local rainfall. Honolulu International Airport (station USW00022521) provides the temperature trend, a single continuous record back to 1940 with no gaps.

### The last decade (Honolulu Airport)

| Year | Min (TN) | Max (TX) | Mean |
|---|---:|---:|---:|
| 2016 | 22.0 | 28.9 | **25.5** |
| 2017 | 22.1 | 29.3 | **25.7** |
| 2018 | 22.7 | 29.3 | **26.0** |
| 2019 | 22.5 | 30.1 | **26.3** |
| 2020 | 22.4 | 29.7 | **26.1** |
| 2021 | 22.1 | 29.3 | **25.7** |
| 2022 | 22.1 | 29.4 | **25.7** |
| 2023 | 22.3 | 29.5 | **25.9** |
| 2024 | 22.2 | 29.2 | **25.7** |
| 2025 | 22.7 | 29.9 | **26.3** |
| 2026 *(to date)* | 22.0 | 28.6 | **25.3** |

### Frost days at zero, hot days up

A degree of warming is abstract; the count of extreme days is not. Comparing
Honolulu Airport’s first complete decade (1950–1959) with its last (2016–2025),
the everyday texture of the year has changed sharply:

| Threshold days per year | 1950–1959 | 2016–2025 |
|---|---:|---:|
| Frost days (min < 0 °C) | 0 | **0** |
| Hot days (max ≥ 30 °C) | 42 | **175** |
| Very hot days (max ≥ 35 °C) | 0 | **0** |
| Tropical nights (min ≥ 20 °C) | 272 | **317** |

<sub>Counts of days per year crossing each threshold, averaged over the first and last
complete decades. There was never a frost season here to retreat; the change shows up entirely on the hot side of the ledger.</sub>

### What about the rain?

Temperature is only half of a climate. Rainfall tells a very different — and much
quieter — story: over the same 83 years, annual precipitation at
Honolulu Airport shows **a statistically significant trend (-24 mm/decade, p = 0.02)**.

![Annual rainfall totals around Honolulu](outputs/honolulu/figures/rain_series.png)

<sub>Annual total precipitation. The dashed line is Honolulu Airport’s long-term mean
(488 mm/yr); the thick curves are LOESS smoothings. The year-to-year swings are
large — from 116 mm (1998) to 1087 mm (1965) —
but the long-run slope (-24 mm/decade) is measurable and statistically significant (p = 0.02).</sub>

Rainfall tells its own story here: Honolulu Airport shows a real, if much smaller and slower, long-run trend toward drier conditions (-24 mm/decade, p = 0.02) — alongside the much larger and faster warming signal above.

![Monthly rainfall through the year at Honolulu Airport, one line per year](outputs/honolulu/figures/rain_climatology.png)

<sub>Rain through the year: each grey line is one year’s monthly totals, the dark line the
long-term monthly normal, the bold blue line 2026 so far. January is the
wettest month on average (79 mm), June the driest
(10 mm) — but the spread between years is why that slow trend is easy to miss from the monthly shape alone.</sub>

### Methodology

- **Source.** NOAA (National Centers for Environmental Information) — GHCN-Daily — Global Historical Climatology Network, daily summaries, Oʻahu, Hawaiʻi, USA. Full citation
  below.
- **Variables.** Minimum = `TN`, maximum = `TX`, mean = `(TN+TX)/2`, in °C;
  rainfall = `RR` (daily precipitation, in mm).
- **Annual aggregation.** Arithmetic mean of daily values over each calendar year. The
  long-term trend uses only complete years (≥ 330 valid days). Where the current
  year is still in progress, it is shown separately — as a hollow “to date” marker on the
  trend chart, and (for a fair record comparison) against the same calendar window
  (Jan 1 → cutoff) of every prior year, keeping only years with ≥ 150 valid
  days in that window.
- **Daily climatology.** Each year’s daily mean is smoothed with a centred
  3-day rolling mean (unweighted moving average, computed per year so
  December never bleeds into January; the first/last 1 day keep their raw
  value) for legibility; leap days are aligned across years. The normal is the per-day
  average over all prior years.
- **Threshold days.** Frost = `TN < 0`, hot day = `TX ≥ 30`, very hot =
  `TX ≥ 35`, tropical night = `TN ≥ 20`, counted per complete year and
  averaged over the first/last complete decade.
- **Rainfall.** Annual total of daily `RR` over complete years; the trend is a
  least-squares slope with its two-sided p-value. Monthly climatology keeps only months
  with ≥ 27 valid days.
- **Trend.** Slope estimated by linear regression (least squares); the line-chart curves
  use LOESS smoothing (span = 0.7).
- **Reproducibility.** A 4-stage R pipeline (`R/00_prepare_data.R` → `R/01_plot.R` →
  `R/02_report.R` → `R/03_readme.R`), driven by `SITE=honolulu make all`. The figures
  above and the numbers in this section are regenerated from the source data on every
  run — see [Data source](#data-source--citation) below for the full citation.

<sub>Figures and numbers above are generated — edit `R/03_readme.R`, not this block.</sub>

<!-- END REPORT:honolulu -->

<!-- BEGIN REPORT:noumea -->

## A warming climate, seen from Nouméa

*Météo-France daily temperature records, 1951 to 2025 — plus 2026 so far.*

Météo-France daily records for the Nouméa area tell an unambiguous story:
since the mid-20th century, minimum, maximum and mean temperatures have all risen —
steadily and continuously.

| Headline number | Value |
|---|---:|
| Warming rate, mean temperature (Nouméa) | **+0.19 °C / decade** |
| Total rise over 74 years (1951 → 2025) | **+1.4 °C** |
| Mean of the last decade (vs 23.0 °C in 1951–1960) | **24.2 °C** |
| Frost days per year, 1951–1960 → 2016–2025 | **0 → 0** |
| Hot days (≥ 30 °C) per year, 1951–1960 → 2016–2025 | **32 → 74** |
| Complete station-years analysed | **137** |
| 2026 year-to-date (Jan 1 – Aug 14), against 75 prior years | **#5 of 76** |

### The long view: annual means

![Annual mean temperatures around Nouméa, 1951 to 2025](outputs/noumea/figures/temperature_series.png)

<sub>Annual means of daily temperatures. The thick curves are LOESS smoothings that
highlight the climate trend; the points are annual means. The green series (Nouméa-Magenta) is Nouméa's in-town domestic airfield, Magenta; it tracks the long Nouméa reference mean almost exactly.</sub>

At Nouméa — the station with the longest record (1951→2025) — the annual
mean temperature rises by **+0.19 °C per decade**, about **+1.4 °C** over the
whole period. The local Nouméa-Magenta station only covers 1964→2025. Its slope over that shorter, more recent window is steeper (+0.25 °C/decade) — but so is Nouméa’s over the same years (+0.23 °C/decade): recent decades warm faster, and the local station sits almost exactly on the regional mean.

### This year, against every year before it

![Per-year mean over the same Jan-to-cutoff window, as a departure from the long-term normal, with 2026 highlighted](outputs/noumea/figures/temperature_ytd.png)

<sub>Each bar is a year’s mean over the <em>same window</em> — <strong>Jan 1 – Aug 14</strong> —
shown as its departure from the long-term normal (23.7 °C): red above, blue
below. Comparing each year over the identical part-of-year is the only fair way to place
any one year against every other. The bars swing from blue to red over
the decades — the warming.</sub>

Measured like-for-like over Jan 1 – Aug 14, 2026 currently ranks **#5 of 76** at Nouméa (24.6 °C). The warmest such window on record remains 2022 (25.1 °C).

> [!NOTE]
> A partial year cannot be compared to other years' full-year means — it is still missing the rest of the year. That is why 2026 appears on the long-view chart above only as a marked, hollow "to date" point (seasonally incomplete, so lower than its eventual annual figure), while its real, like-for-like standing is the chart here.

### Every year, day by day

![Daily temperature climatology, every year January to December, hot years red and cold years blue](outputs/noumea/figures/temperature_climatology.png)

<sub>Each thin line is a single year’s daily mean temperature from January to December
(1950–2025, 76 years), smoothed with a centred
<strong>3-day rolling mean</strong> (each day = the average of itself
±1 day) to tame day-to-day jitter while keeping the shape. The dark line
is the long-term daily normal; the bold red line is <strong>2026 so far</strong>.
Years whose smoothed daily mean ever rose above <strong>+30 °C</strong> are
highlighted in red and labelled; years that ever fell below
<strong>-5 °C</strong> in blue.</sub>

> [!NOTE]
> **Hottest and coldest years.** Measured on the smoothed daily-mean curve,
> **12** years pushed above +30 °C (1954, 1986, 1991, 1992, 1995, 1996, 2009, 2010, 2015, 2019, 2020, 2024)
> while **0** years dropped below -5 °C.
> No single year managed to hit both extremes.  <sub>(On the raw, unsmoothed daily mean, no year touches both extremes.)</sub>

### The record days

The single most extreme days in each station’s record. “Hottest” is the highest daily
maximum (TX), “coldest” the lowest daily minimum (TN).

| Station (record span) | Extreme | Date | Min (TN) | Max (TX) |
|---|---|---|---:|---:|
| Nouméa <sub>1950–2026</sub> | Hottest 🔥 | 1986-01-25 | 26.4 | **36.8** |
| Nouméa <sub>1950–2026</sub> | Coldest ❄️ | 1961-08-10 | **13.2** | 20.8 |
| Nouméa-Magenta <sub>1964–2026</sub> | Hottest 🔥 | 1986-01-25 | 24.8 | **36.8** |
| Nouméa-Magenta <sub>1964–2026</sub> | Coldest ❄️ | 1968-07-28 | **8.9** | 21.2 |

At Nouméa, the all-time heat (1986-01-25) is far more recent than the all-time cold (1961-08-10) — the same warming signature seen throughout this report.

> [!NOTE]
> **Why Nouméa-Magenta?** Nouméa-Magenta (station 98818002), the in-town domestic airfield, has carried a complete, gap-free temperature record since 1964 and provides the local comparison. Nouméa (station 98818001) provides the historical depth needed to see the underlying trend, back to 1950.

### The last decade (Nouméa)

| Year | Min (TN) | Max (TX) | Mean |
|---|---:|---:|---:|
| 2016 | 21.3 | 27.2 | **24.2** |
| 2017 | 21.1 | 27.2 | **24.1** |
| 2018 | 20.8 | 26.7 | **23.8** |
| 2019 | 20.6 | 26.8 | **23.7** |
| 2020 | 21.1 | 27.6 | **24.4** |
| 2021 | 21.0 | 27.5 | **24.2** |
| 2022 | 21.8 | 28.0 | **24.9** |
| 2023 | 20.6 | 27.1 | **23.9** |
| 2024 | 21.3 | 27.9 | **24.6** |
| 2025 | 21.5 | 28.1 | **24.8** |
| 2026 *(to date)* | 21.4 | 27.8 | **24.6** |

### Frost days at zero, hot days up

A degree of warming is abstract; the count of extreme days is not. Comparing
Nouméa’s first complete decade (1951–1960) with its last (2016–2025),
the everyday texture of the year has changed sharply:

| Threshold days per year | 1951–1960 | 2016–2025 |
|---|---:|---:|
| Frost days (min < 0 °C) | 0 | **0** |
| Hot days (max ≥ 30 °C) | 32 | **74** |
| Very hot days (max ≥ 35 °C) | 0 | **1** |
| Tropical nights (min ≥ 20 °C) | 194 | **237** |

<sub>Counts of days per year crossing each threshold, averaged over the first and last
complete decades. There was never a frost season here to retreat; the change shows up entirely on the hot side of the ledger.</sub>

### What about the rain?

Temperature is only half of a climate. Rainfall tells a very different — and much
quieter — story: over the same 75 years, annual precipitation at
Nouméa shows **no statistically significant trend**.

![Annual rainfall totals around Nouméa](outputs/noumea/figures/rain_series.png)

<sub>Annual total precipitation. The dashed line is Nouméa’s long-term mean
(1054 mm/yr); the thick curves are LOESS smoothings. The year-to-year swings are
large — from 577 mm (1953) to 1951 mm (2022) —
but the long-run slope (+5 mm/decade) is flat and not significant (p = 0.71).</sub>

That contrast is the point. The very same daily records that show an unmistakable, statistically strong warming signal show *no* comparable signal in how much it rains. A dataset that manufactured trends would have produced one here too; this one does not.

![Monthly rainfall through the year at Nouméa, one line per year](outputs/noumea/figures/rain_climatology.png)

<sub>Rain through the year: each grey line is one year’s monthly totals, the dark line the
long-term monthly normal, the bold blue line 2026 so far. March is the
wettest month on average (143 mm), September the driest
(43 mm) — but the spread between years dwarfs the seasonal cycle, which is exactly why no annual trend emerges.</sub>

### Methodology

- **Source.** Météo-France — Données climatologiques de base – quotidiennes, New Caledonia, France. Full citation
  below.
- **Variables.** Minimum = `TN`, maximum = `TX`, mean = `(TN+TX)/2`, in °C;
  rainfall = `RR` (daily precipitation, in mm).
- **Annual aggregation.** Arithmetic mean of daily values over each calendar year. The
  long-term trend uses only complete years (≥ 330 valid days). Where the current
  year is still in progress, it is shown separately — as a hollow “to date” marker on the
  trend chart, and (for a fair record comparison) against the same calendar window
  (Jan 1 → cutoff) of every prior year, keeping only years with ≥ 150 valid
  days in that window.
- **Daily climatology.** Each year’s daily mean is smoothed with a centred
  3-day rolling mean (unweighted moving average, computed per year so
  December never bleeds into January; the first/last 1 day keep their raw
  value) for legibility; leap days are aligned across years. The normal is the per-day
  average over all prior years.
- **Threshold days.** Frost = `TN < 0`, hot day = `TX ≥ 30`, very hot =
  `TX ≥ 35`, tropical night = `TN ≥ 20`, counted per complete year and
  averaged over the first/last complete decade.
- **Rainfall.** Annual total of daily `RR` over complete years; the trend is a
  least-squares slope with its two-sided p-value. Monthly climatology keeps only months
  with ≥ 27 valid days.
- **Trend.** Slope estimated by linear regression (least squares); the line-chart curves
  use LOESS smoothing (span = 0.7).
- **Reproducibility.** A 4-stage R pipeline (`R/00_prepare_data.R` → `R/01_plot.R` →
  `R/02_report.R` → `R/03_readme.R`), driven by `SITE=noumea make all`. The figures
  above and the numbers in this section are regenerated from the source data on every
  run — see [Data source](#data-source--citation) below for the full citation.

<sub>Figures and numbers above are generated — edit `R/03_readme.R`, not this block.</sub>

<!-- END REPORT:noumea -->

<!-- BEGIN REPORT:moscow -->

## A warming climate, seen from Moscow

*Roshydromet / RIHMI-WDC — AISORI-M daily temperature records, 1949 to 2025.*

Roshydromet / RIHMI-WDC — AISORI-M daily records for the Moscow area tell an unambiguous story:
since the mid-20th century, minimum, maximum and mean temperatures have all risen —
steadily and continuously.

| Headline number | Value |
|---|---:|
| Warming rate, mean temperature (Moscow) | **+0.39 °C / decade** |
| Total rise over 76 years (1949 → 2025) | **+3.0 °C** |
| Mean of the last decade (vs 4.7 °C in 1949–1958) | **7.4 °C** |
| Frost days per year, 1949–1958 → 2016–2025 | **160 → 130** |
| Hot days (≥ 30 °C) per year, 1949–1958 → 2016–2025 | **4 → 8** |
| Complete station-years analysed | **77** |
| 2025 year-to-date (Jan 1 – Dec 31), against 76 prior years | **#1 of 77 — record** |

### The long view: annual means

![Annual mean temperatures around Moscow, 1949 to 2025](outputs/moscow/figures/temperature_series.png)

<sub>Annual means of daily temperatures. The thick curves are LOESS smoothings that
highlight the climate trend; the points are annual means.</sub>

At Moscow — the station with the longest record (1949→2025) — the annual
mean temperature rises by **+0.39 °C per decade**, about **+3.0 °C** over the
whole period. This site has no second station — Moscow alone provides the temperature trend and the daily climatology.

### 2025, against every year before it

![Per-year mean over the same Jan-to-cutoff window, as a departure from the long-term normal, with 2025 the largest bar](outputs/moscow/figures/temperature_ytd.png)

<sub>Each bar is a year’s mean over the <em>same window</em> — <strong>Jan 1 – Dec 31</strong> —
shown as its departure from the long-term normal (5.7 °C): red above, blue
below. Comparing each year over the identical part-of-year is the only fair way to place
any one year against every other. The bars swing from blue to red over
the decades — the warming — and 2025 is the tallest of all.</sub>

Measured like-for-like, **2025 is the warmest Jan 1 – Dec 31 in 77 years** at Moscow: **8.6 °C** — +0.4 °C above the previous record (2020, 8.2 °C) and **+2.9 °C above the long-term normal** (5.7 °C). This is exactly the point of the chart: even a complete year can be measured precisely, like-for-like, against every year before it.

> [!NOTE]
> 2025 is Moscow's most recent complete year — this export has no 2026 data yet, so it is plotted as a solid point like every other complete year, not as a hollow "to date" marker.

### Every year, day by day

![Daily temperature climatology, every year January to December, hot years red and cold years blue](outputs/moscow/figures/temperature_climatology.png)

<sub>Each thin line is a single year’s daily mean temperature from January to December
(1948–2025, 78 years), smoothed with a centred
<strong>3-day rolling mean</strong> (each day = the average of itself
±1 day) to tame day-to-day jitter while keeping the shape. The dark line
is the long-term daily normal; the bold red line is <strong>2025</strong>.
Years whose smoothed daily mean ever rose above <strong>+30 °C</strong> are
highlighted in red and labelled; years that ever fell below
<strong>-5 °C</strong> in blue.</sub>

> [!NOTE]
> **Hottest and coldest years.** Measured on the smoothed daily-mean curve,
> **1** year pushed above +30 °C (2010) — all of them recent —
> while **78** years dropped below -5 °C (1948, 1949, 1950, 1951, 1952, 1953, 1954, 1955, 1956, 1957, 1958, 1959, 1960, 1961, 1962, 1963, 1964, 1965, 1966, 1967, 1968, 1969, 1970, 1971, 1972, 1973, 1974, 1975, 1976, 1977, 1978, 1979, 1980, 1981, 1982, 1983, 1984, 1985, 1986, 1987, 1988, 1989, 1990, 1991, 1992, 1993, 1994, 1995, 1996, 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025).
> Years hitting both extremes: 2010.  <sub>(If the threshold is applied instead to the raw, unsmoothed daily mean, 2010 alone touches both extremes.)</sub>

### The record days

The single most extreme days in each station’s record. “Hottest” is the highest daily
maximum (TX), “coldest” the lowest daily minimum (TN).

| Station (record span) | Extreme | Date | Min (TN) | Max (TX) |
|---|---|---|---:|---:|
| Moscow <sub>1948–2025</sub> | Hottest 🔥 | 2010-07-29 | 26.0 | **38.2** |
| Moscow <sub>1948–2025</sub> | Coldest ❄️ | 1956-01-31 | **-38.1** | -32.3 |

At Moscow, the all-time heat (2010-07-29) is far more recent than the all-time cold (1956-01-31) — the same warming signature seen throughout this report.

> [!NOTE]
> **Why only one station?** This export from Roshydromet's AISORI-M portal (aisori-m.meteo.ru) includes only WMO index 27612 (Moscow, VDNKh) — the manual, login-gated query wasn't run for a second nearby station. Every other site in this project pairs a long regional reference with a shorter local one; re-querying AISORI-M with an additional station selected would let a future update add that pairing here too.

### The last decade (Moscow)

| Year | Min (TN) | Max (TX) | Mean |
|---|---:|---:|---:|
| 2016 | 3.2 | 10.2 | **6.7** |
| 2017 | 3.0 | 10.0 | **6.5** |
| 2018 | 2.7 | 10.8 | **6.7** |
| 2019 | 4.2 | 11.6 | **7.9** |
| 2020 | 4.6 | 11.9 | **8.2** |
| 2021 | 3.0 | 10.4 | **6.7** |
| 2022 | 3.4 | 10.6 | **7.0** |
| 2023 | 3.7 | 10.9 | **7.3** |
| 2024 | 4.1 | 12.0 | **8.0** |
| 2025 | 5.2 | 12.0 | **8.6** |

### Frost days down, hot days up

A degree of warming is abstract; the count of extreme days is not. Comparing
Moscow’s first complete decade (1949–1958) with its last (2016–2025),
the everyday texture of the year has changed sharply:

| Threshold days per year | 1949–1958 | 2016–2025 |
|---|---:|---:|
| Frost days (min < 0 °C) | 160 | **130** |
| Hot days (max ≥ 30 °C) | 4 | **8** |
| Very hot days (max ≥ 35 °C) | 0 | **0** |
| Tropical nights (min ≥ 20 °C) | 0 | **2** |

<sub>Counts of days per year crossing each threshold, averaged over the first and last
complete decades. Frost is retreating just as heat advances — the same warming, read off the calendar instead of the thermometer.</sub>

### What about the rain?

Temperature is only half of a climate. Rainfall tells a very different — and much
quieter — story: over the same 77 years, annual precipitation at
Moscow shows **a statistically significant trend (+19 mm/decade, p = 0.00)**.

![Annual rainfall totals around Moscow](outputs/moscow/figures/rain_series.png)

<sub>Annual total precipitation. The dashed line is Moscow’s long-term mean
(692 mm/yr); the thick curves are LOESS smoothings. The year-to-year swings are
large — from 397 mm (1964) to 891 mm (2013) —
but the long-run slope (+19 mm/decade) is measurable and statistically significant (p = 0.00).</sub>

Rainfall tells its own story here: Moscow shows a real, if much smaller and slower, long-run trend toward wetter conditions (+19 mm/decade, p = 0.00) — alongside the much larger and faster warming signal above.

![Monthly rainfall through the year at Moscow, one line per year](outputs/moscow/figures/rain_climatology.png)

<sub>Rain through the year: each grey line is one year’s monthly totals, the dark line the
long-term monthly normal, the bold blue line 2025. July is the
wettest month on average (86 mm), March the driest
(37 mm) — but the spread between years is why that slow trend is easy to miss from the monthly shape alone.</sub>

### Methodology

- **Source.** Roshydromet / RIHMI-WDC — AISORI-M — AISORI-M daily archive, Сутки → TTTR (temperature + precipitation), Moscow, Russia. Full citation
  below.
- **Variables.** Minimum = `TN`, maximum = `TX`, mean = `(TN+TX)/2`, in °C;
  rainfall = `RR` (daily precipitation, in mm).
- **Annual aggregation.** Arithmetic mean of daily values over each calendar year. The
  long-term trend uses only complete years (≥ 330 valid days). Where the current
  year is still in progress, it is shown separately — as a hollow “to date” marker on the
  trend chart, and (for a fair record comparison) against the same calendar window
  (Jan 1 → cutoff) of every prior year, keeping only years with ≥ 150 valid
  days in that window.
- **Daily climatology.** Each year’s daily mean is smoothed with a centred
  3-day rolling mean (unweighted moving average, computed per year so
  December never bleeds into January; the first/last 1 day keep their raw
  value) for legibility; leap days are aligned across years. The normal is the per-day
  average over all prior years.
- **Threshold days.** Frost = `TN < 0`, hot day = `TX ≥ 30`, very hot =
  `TX ≥ 35`, tropical night = `TN ≥ 20`, counted per complete year and
  averaged over the first/last complete decade.
- **Rainfall.** Annual total of daily `RR` over complete years; the trend is a
  least-squares slope with its two-sided p-value. Monthly climatology keeps only months
  with ≥ 27 valid days.
- **Trend.** Slope estimated by linear regression (least squares); the line-chart curves
  use LOESS smoothing (span = 0.7).
- **Reproducibility.** A 4-stage R pipeline (`R/00_prepare_data.R` → `R/01_plot.R` →
  `R/02_report.R` → `R/03_readme.R`), driven by `SITE=moscow make all`. The figures
  above and the numbers in this section are regenerated from the source data on every
  run — see [Data source](#data-source--citation) below for the full citation.

<sub>Figures and numbers above are generated — edit `R/03_readme.R`, not this block.</sub>

<!-- END REPORT:moscow -->

<!-- BEGIN REPORT:voronezh -->

## A warming climate, seen from Voronezh

*Roshydromet / RIHMI-WDC — AISORI-M daily temperature records, 1940 to 2025 — plus 2026 so far.*

Roshydromet / RIHMI-WDC — AISORI-M daily records for the Voronezh area tell an unambiguous story:
since the mid-20th century, minimum, maximum and mean temperatures have all risen —
steadily and continuously.

| Headline number | Value |
|---|---:|
| Warming rate, mean temperature (Voronezh) | **+0.46 °C / decade** |
| Total rise over 85 years (1940 → 2025) | **+3.9 °C** |
| Mean of the last decade (vs 5.5 °C in 1940–1949) | **9.0 °C** |
| Frost days per year, 1940–1949 → 2016–2025 | **162 → 116** |
| Hot days (≥ 30 °C) per year, 1940–1949 → 2016–2025 | **18 → 28** |
| Complete station-years analysed | **82** |
| 2026 year-to-date (Jan 1 – Feb 28), against 83 prior years | **#55 of 84** |

### The long view: annual means

![Annual mean temperatures around Voronezh, 1940 to 2025](outputs/voronezh/figures/temperature_series.png)

<sub>Annual means of daily temperatures. The thick curves are LOESS smoothings that
highlight the climate trend; the points are annual means.</sub>

At Voronezh — the station with the longest record (1940→2025) — the annual
mean temperature rises by **+0.46 °C per decade**, about **+3.9 °C** over the
whole period. This site has no second station — Voronezh alone provides the temperature trend and the daily climatology.

### This year, against every year before it

![Per-year mean over the same Jan-to-cutoff window, as a departure from the long-term normal, with 2026 highlighted](outputs/voronezh/figures/temperature_ytd.png)

<sub>Each bar is a year’s mean over the <em>same window</em> — <strong>Jan 1 – Feb 28</strong> —
shown as its departure from the long-term normal (-7.5 °C): red above, blue
below. Comparing each year over the identical part-of-year is the only fair way to place
any one year against every other. The bars swing from blue to red over
the decades — the warming.</sub>

Measured like-for-like over Jan 1 – Feb 28, 2026 currently ranks **#55 of 84** at Voronezh (-8.4 °C). The warmest such window on record remains 2020 (-0.5 °C).

> [!NOTE]
> A partial year cannot be compared to other years' full-year means — it is still missing the rest of the year. That is why 2026 appears on the long-view chart above only as a marked, hollow "to date" point (seasonally incomplete, so lower than its eventual annual figure), while its real, like-for-like standing is the chart here.

### Every year, day by day

![Daily temperature climatology, every year January to December, hot years red and cold years blue](outputs/voronezh/figures/temperature_climatology.png)

<sub>Each thin line is a single year’s daily mean temperature from January to December
(1940–2025, 85 years), smoothed with a centred
<strong>3-day rolling mean</strong> (each day = the average of itself
±1 day) to tame day-to-day jitter while keeping the shape. The dark line
is the long-term daily normal; the bold red line is <strong>2026 so far</strong>.
Years whose smoothed daily mean ever rose above <strong>+30 °C</strong> are
highlighted in red and labelled; years that ever fell below
<strong>-5 °C</strong> in blue.</sub>

> [!NOTE]
> **Hottest and coldest years.** Measured on the smoothed daily-mean curve,
> **2** years pushed above +30 °C (2010, 2016) — all of them recent —
> while **85** years dropped below -5 °C (1940, 1941, 1942, 1944, 1945, 1946, 1947, 1948, 1949, 1950, 1951, 1952, 1953, 1954, 1955, 1956, 1957, 1958, 1959, 1960, 1961, 1962, 1963, 1964, 1965, 1966, 1967, 1968, 1969, 1970, 1971, 1972, 1973, 1974, 1975, 1976, 1977, 1978, 1979, 1980, 1981, 1982, 1983, 1984, 1985, 1986, 1987, 1988, 1989, 1990, 1991, 1992, 1993, 1994, 1995, 1996, 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025).
> Years hitting both extremes: 2010 and 2016.  <sub>(If the threshold is applied instead to the raw, unsmoothed daily mean, 1972, 1991, 1996, 2010, 2016 and 2020 each touch both extremes.)</sub>

### The record days

The single most extreme days in each station’s record. “Hottest” is the highest daily
maximum (TX), “coldest” the lowest daily minimum (TN).

| Station (record span) | Extreme | Date | Min (TN) | Max (TX) |
|---|---|---|---:|---:|
| Voronezh <sub>1940–2026</sub> | Hottest 🔥 | 2010-08-02 | 21.8 | **40.5** |
| Voronezh <sub>1940–2026</sub> | Coldest ❄️ | 1942-01-22 | **-36.5** | -26.3 |

At Voronezh, the all-time heat (2010-08-02) is far more recent than the all-time cold (1942-01-22) — the same warming signature seen throughout this report.

> [!NOTE]
> **Why only one station?** This export from Roshydromet's AISORI-M portal (aisori-m.meteo.ru) includes only WMO index 34123 (Voronezh) — the manual, login-gated query wasn't run for a second nearby station. Every other site in this project pairs a long regional reference with a shorter local one; re-querying AISORI-M with an additional station selected would let a future update add that pairing here too.

### The last decade (Voronezh)

| Year | Min (TN) | Max (TX) | Mean |
|---|---:|---:|---:|
| 2016 | 4.4 | 12.4 | **8.4** |
| 2017 | 4.4 | 12.7 | **8.5** |
| 2018 | 3.5 | 12.3 | **7.9** |
| 2019 | 4.7 | 13.6 | **9.2** |
| 2020 | 5.1 | 14.5 | **9.8** |
| 2021 | 4.2 | 13.2 | **8.7** |
| 2022 | 4.4 | 12.5 | **8.5** |
| 2023 | 4.8 | 13.1 | **9.0** |
| 2024 | 5.2 | 14.5 | **9.8** |
| 2025 | 5.5 | 14.2 | **9.9** |
| 2026 *(to date)* | -11.6 | -5.2 | **-8.4** |

### Frost days down, hot days up

A degree of warming is abstract; the count of extreme days is not. Comparing
Voronezh’s first complete decade (1940–1949) with its last (2016–2025),
the everyday texture of the year has changed sharply:

| Threshold days per year | 1940–1949 | 2016–2025 |
|---|---:|---:|
| Frost days (min < 0 °C) | 162 | **116** |
| Hot days (max ≥ 30 °C) | 18 | **28** |
| Very hot days (max ≥ 35 °C) | 1 | **2** |
| Tropical nights (min ≥ 20 °C) | 4 | **8** |

<sub>Counts of days per year crossing each threshold, averaged over the first and last
complete decades. Frost is retreating just as heat advances — the same warming, read off the calendar instead of the thermometer.</sub>

### What about the rain?

Temperature is only half of a climate. Rainfall tells a very different — and much
quieter — story: over the same 84 years, annual precipitation at
Voronezh shows **a statistically significant trend (+16 mm/decade, p = 0.00)**.

![Annual rainfall totals around Voronezh](outputs/voronezh/figures/rain_series.png)

<sub>Annual total precipitation. The dashed line is Voronezh’s long-term mean
(561 mm/yr); the thick curves are LOESS smoothings. The year-to-year swings are
large — from 333 mm (1949) to 871 mm (2022) —
but the long-run slope (+16 mm/decade) is measurable and statistically significant (p = 0.00).</sub>

Rainfall tells its own story here: Voronezh shows a real, if much smaller and slower, long-run trend toward wetter conditions (+16 mm/decade, p = 0.00) — alongside the much larger and faster warming signal above.

![Monthly rainfall through the year at Voronezh, one line per year](outputs/voronezh/figures/rain_climatology.png)

<sub>Rain through the year: each grey line is one year’s monthly totals, the dark line the
long-term monthly normal, the bold blue line 2026 so far. July is the
wettest month on average (65 mm), March the driest
(32 mm) — but the spread between years is why that slow trend is easy to miss from the monthly shape alone.</sub>

### Methodology

- **Source.** Roshydromet / RIHMI-WDC — AISORI-M — AISORI-M daily archive, Сутки → TTTR (temperature + precipitation), Voronezh Oblast, Russia. Full citation
  below.
- **Variables.** Minimum = `TN`, maximum = `TX`, mean = `(TN+TX)/2`, in °C;
  rainfall = `RR` (daily precipitation, in mm).
- **Annual aggregation.** Arithmetic mean of daily values over each calendar year. The
  long-term trend uses only complete years (≥ 330 valid days). Where the current
  year is still in progress, it is shown separately — as a hollow “to date” marker on the
  trend chart, and (for a fair record comparison) against the same calendar window
  (Jan 1 → cutoff) of every prior year, keeping only years with ≥ 50 valid
  days in that window.
- **Daily climatology.** Each year’s daily mean is smoothed with a centred
  3-day rolling mean (unweighted moving average, computed per year so
  December never bleeds into January; the first/last 1 day keep their raw
  value) for legibility; leap days are aligned across years. The normal is the per-day
  average over all prior years.
- **Threshold days.** Frost = `TN < 0`, hot day = `TX ≥ 30`, very hot =
  `TX ≥ 35`, tropical night = `TN ≥ 20`, counted per complete year and
  averaged over the first/last complete decade.
- **Rainfall.** Annual total of daily `RR` over complete years; the trend is a
  least-squares slope with its two-sided p-value. Monthly climatology keeps only months
  with ≥ 27 valid days.
- **Trend.** Slope estimated by linear regression (least squares); the line-chart curves
  use LOESS smoothing (span = 0.7).
- **Reproducibility.** A 4-stage R pipeline (`R/00_prepare_data.R` → `R/01_plot.R` →
  `R/02_report.R` → `R/03_readme.R`), driven by `SITE=voronezh make all`. The figures
  above and the numbers in this section are regenerated from the source data on every
  run — see [Data source](#data-source--citation) below for the full citation.

<sub>Figures and numbers above are generated — edit `R/03_readme.R`, not this block.</sub>

<!-- END REPORT:voronezh -->

<!-- BEGIN REPORT:irvine -->

## A warming climate, seen from Irvine

*NOAA (National Centers for Environmental Information) daily temperature records, 1915 to 2025 — plus 2026 so far.*

NOAA (National Centers for Environmental Information) daily records for the Irvine area tell an unambiguous story:
since the early 20th century, minimum, maximum and mean temperatures have all risen —
steadily and continuously.

| Headline number | Value |
|---|---:|
| Warming rate, mean temperature (Irvine) | **+0.27 °C / decade** |
| Total rise over 110 years (1915 → 2025) | **+3.0 °C** |
| Mean of the last decade (vs 15.8 °C in 1915–1924) | **19.3 °C** |
| Frost days per year, 1915–1924 → 2016–2025 | **12 → 0** |
| Hot days (≥ 30 °C) per year, 1915–1924 → 2016–2025 | **40 → 92** |
| Complete station-years analysed | **121** |
| 2026 year-to-date (Jan 1 – May 31), against 100 prior years | **#2 of 101** |

### The long view: annual means

![Annual mean temperatures around Irvine, 1915 to 2025](outputs/irvine/figures/temperature_series.png)

<sub>Annual means of daily temperatures. The thick curves are LOESS smoothings that
highlight the climate trend; the points are annual means. The green series (John Wayne Airport) is Orange County's regional airport, a few miles southwest on Irvine's border; it tracks the long Irvine reference mean almost exactly.</sub>

At Irvine — the station with the longest record (1915→2025) — the annual
mean temperature rises by **+0.27 °C per decade**, about **+3.0 °C** over the
whole period. The local John Wayne Airport station only covers 2000→2025. Its slope over that shorter, more recent window is steeper (+0.62 °C/decade) — but so is Irvine’s over the same years (+0.75 °C/decade): recent decades warm faster, and the local station sits almost exactly on the regional mean.

### This year, against every year before it

![Per-year mean over the same Jan-to-cutoff window, as a departure from the long-term normal, with 2026 highlighted](outputs/irvine/figures/temperature_ytd.png)

<sub>Each bar is a year’s mean over the <em>same window</em> — <strong>Jan 1 – May 31</strong> —
shown as its departure from the long-term normal (14.7 °C): red above, blue
below. Comparing each year over the identical part-of-year is the only fair way to place
any one year against every other. The bars swing from blue to red over
the decades — the warming.</sub>

Measured like-for-like over Jan 1 – May 31, 2026 currently ranks **#2 of 101** at Irvine (18.3 °C). The warmest such window on record remains 2014 (18.8 °C).

> [!NOTE]
> A partial year cannot be compared to other years' full-year means — it is still missing the rest of the year. That is why 2026 appears on the long-view chart above only as a marked, hollow "to date" point (seasonally incomplete, so lower than its eventual annual figure), while its real, like-for-like standing is the chart here.

### Every year, day by day

![Daily temperature climatology, every year January to December, hot years red and cold years blue](outputs/irvine/figures/temperature_climatology.png)

<sub>Each thin line is a single year’s daily mean temperature from January to December
(1915–2025, 111 years), smoothed with a centred
<strong>3-day rolling mean</strong> (each day = the average of itself
±1 day) to tame day-to-day jitter while keeping the shape. The dark line
is the long-term daily normal; the bold red line is <strong>2026 so far</strong>.
Years whose smoothed daily mean ever rose above <strong>+30 °C</strong> are
highlighted in red and labelled; years that ever fell below
<strong>-5 °C</strong> in blue.</sub>

> [!NOTE]
> **Hottest and coldest years.** Measured on the smoothed daily-mean curve,
> **15** years pushed above +30 °C (1939, 1963, 1984, 1994, 1997, 1998, 2006, 2007, 2014, 2016, 2017, 2018, 2020, 2022, 2024)
> while **0** years dropped below -5 °C.
> No single year managed to hit both extremes.  <sub>(On the raw, unsmoothed daily mean, no year touches both extremes.)</sub>

### The record days

The single most extreme days in each station’s record. “Hottest” is the highest daily
maximum (TX), “coldest” the lowest daily minimum (TN).

| Station (record span) | Extreme | Date | Min (TN) | Max (TX) |
|---|---|---|---:|---:|
| Irvine <sub>1915–2026</sub> | Hottest 🔥 | 2018-07-06 | 17.8 | **46.1** |
| Irvine <sub>1915–2026</sub> | Coldest ❄️ | 1937-01-21 | **-7.8** | 6.1 |
| John Wayne Airport <sub>1999–2026</sub> | Hottest 🔥 | 2010-09-27 | 21.1 | **43.3** |
| John Wayne Airport <sub>1999–2026</sub> | Coldest ❄️ | 2007-01-14 | **0.6** | 12.8 |

At Irvine, the all-time heat (2018-07-06) is far more recent than the all-time cold (1937-01-21) — the same warming signature seen throughout this report.

> [!NOTE]
> **Why John Wayne Airport?** John Wayne Airport (station USW00093184), a few miles southwest on Irvine's border, is the nearest continuously-sited station and provides the local comparison — but only since 1999, a much shorter record than the reference series. The reference series, labelled “Irvine”, splices the Irvine Ranch COOP station's original site (049087, “Tustin Irvine Ranch”, 1915–2003) with its direct successor a few miles away (044303, 2003–2026) for one gap-free record back to 1915; the two stations' own records do not quite touch (049087 ends June 2003, 044303 begins August 2003), which costs 2003 its “complete year” status.

### The last decade (Irvine)

| Year | Min (TN) | Max (TX) | Mean |
|---|---:|---:|---:|
| 2016 | 13.7 | 26.8 | **20.3** |
| 2017 | 13.3 | 26.7 | **20.0** |
| 2018 | 12.7 | 26.4 | **19.6** |
| 2019 | 12.8 | 25.2 | **19.0** |
| 2020 | 12.7 | 26.6 | **19.7** |
| 2021 | 13.3 | 25.5 | **19.4** |
| 2022 | 13.5 | 26.1 | **19.8** |
| 2023 | 11.4 | 23.1 | **17.3** |
| 2024 | 12.9 | 24.9 | **18.9** |
| 2025 | 12.9 | 24.7 | **18.8** |
| 2026 *(to date)* | 12.1 | 24.4 | **18.3** |

### Frost days down, hot days up

A degree of warming is abstract; the count of extreme days is not. Comparing
Irvine’s first complete decade (1915–1924) with its last (2016–2025),
the everyday texture of the year has changed sharply:

| Threshold days per year | 1915–1924 | 2016–2025 |
|---|---:|---:|
| Frost days (min < 0 °C) | 12 | **0** |
| Hot days (max ≥ 30 °C) | 40 | **92** |
| Very hot days (max ≥ 35 °C) | 4 | **18** |
| Tropical nights (min ≥ 20 °C) | 1 | **13** |

<sub>Counts of days per year crossing each threshold, averaged over the first and last
complete decades. Frost is retreating just as heat advances — the same warming, read off the calendar instead of the thermometer.</sub>

### What about the rain?

Temperature is only half of a climate. Rainfall tells a very different — and much
quieter — story: over the same 96 years, annual precipitation at
Irvine shows **no statistically significant trend**.

![Annual rainfall totals around Irvine](outputs/irvine/figures/rain_series.png)

<sub>Annual total precipitation. The dashed line is Irvine’s long-term mean
(315 mm/yr); the thick curves are LOESS smoothings. The year-to-year swings are
large — from 99 mm (1972) to 725 mm (1941) —
but the long-run slope (-0 mm/decade) is flat and not significant (p = 0.93).</sub>

That contrast is the point. The very same daily records that show an unmistakable, statistically strong warming signal show *no* comparable signal in how much it rains. A dataset that manufactured trends would have produced one here too; this one does not.

![Monthly rainfall through the year at Irvine, one line per year](outputs/irvine/figures/rain_climatology.png)

<sub>Rain through the year: each grey line is one year’s monthly totals, the dark line the
long-term monthly normal, the bold blue line 2026 so far. February is the
wettest month on average (68 mm), July the driest
(1 mm) — but the spread between years dwarfs the seasonal cycle, which is exactly why no annual trend emerges.</sub>

### Methodology

- **Source.** NOAA (National Centers for Environmental Information) — GHCN-Daily — Global Historical Climatology Network, daily summaries, California, USA. Full citation
  below.
- **Variables.** Minimum = `TN`, maximum = `TX`, mean = `(TN+TX)/2`, in °C;
  rainfall = `RR` (daily precipitation, in mm).
- **Annual aggregation.** Arithmetic mean of daily values over each calendar year. The
  long-term trend uses only complete years (≥ 330 valid days). Where the current
  year is still in progress, it is shown separately — as a hollow “to date” marker on the
  trend chart, and (for a fair record comparison) against the same calendar window
  (Jan 1 → cutoff) of every prior year, keeping only years with ≥ 128 valid
  days in that window.
- **Daily climatology.** Each year’s daily mean is smoothed with a centred
  3-day rolling mean (unweighted moving average, computed per year so
  December never bleeds into January; the first/last 1 day keep their raw
  value) for legibility; leap days are aligned across years. The normal is the per-day
  average over all prior years.
- **Threshold days.** Frost = `TN < 0`, hot day = `TX ≥ 30`, very hot =
  `TX ≥ 35`, tropical night = `TN ≥ 20`, counted per complete year and
  averaged over the first/last complete decade.
- **Rainfall.** Annual total of daily `RR` over complete years; the trend is a
  least-squares slope with its two-sided p-value. Monthly climatology keeps only months
  with ≥ 27 valid days.
- **Trend.** Slope estimated by linear regression (least squares); the line-chart curves
  use LOESS smoothing (span = 0.7).
- **Reproducibility.** A 4-stage R pipeline (`R/00_prepare_data.R` → `R/01_plot.R` →
  `R/02_report.R` → `R/03_readme.R`), driven by `SITE=irvine make all`. The figures
  above and the numbers in this section are regenerated from the source data on every
  run — see [Data source](#data-source--citation) below for the full citation.

<sub>Figures and numbers above are generated — edit `R/03_readme.R`, not this block.</sub>

<!-- END REPORT:irvine -->

## Data sources

Each site pulls from its own national weather service, all open data, all
attribution-only:

| Site | Source | Scope | Licence |
|---|---|---|---|
| Castanet-Tolosan | Météo-France — *Données climatologiques de base – quotidiennes* | dept. 31 (Haute-Garonne), `RR-T-Vent` daily files, three eras (`avant-1949`, `previous-1950-2024`, `latest-2025-2026`) | Licence Ouverte / Open Licence (Etalab 2.0) |
| Zurich | MeteoSwiss — Open Government Data | `ogd-nbcn` (homogeneous climate stations) + `ogd-smn` (automatic weather stations) | MeteoSwiss Open Data (attribution: "Source: MeteoSwiss") |
| Karlsruhe | DWD (Deutscher Wetterdienst) — Climate Data Center | `kl` (daily station observations) + `more_precip` (precipitation only) | Creative Commons BY 4.0 |
| Santa Fe | NOAA — GHCN-Daily, Access Data Service v1 | `daily-summaries` (TMAX/TMIN/PRCP), stations USC00298072/298085 (spliced) + USW00023049 | U.S. Government work — no copyright restriction |
| Honolulu | NOAA — GHCN-Daily, Access Data Service v1 | `daily-summaries` (TMAX/TMIN/PRCP), stations USW00022521 + USC00516395 | U.S. Government work — no copyright restriction |
| Nouméa | Météo-France — *Données climatologiques de base – quotidiennes* | dept. 988 (Nouvelle-Calédonie), `RR-T-Vent` daily files, same three eras | Licence Ouverte / Open Licence (Etalab 2.0) |
| Moscow | Roshydromet / RIHMI-WDC — AISORI-M | Сутки → TTTR (temp. + precip.), WMO 27612, manually exported (login-gated, no stable URL) | Not openly licensed — Rospatent 2019621537; personal, non-commercial use only |
| Voronezh | Roshydromet / RIHMI-WDC — AISORI-M | Сутки → TTTR (temp. + precip.), WMO 34123, manually exported (login-gated, no stable URL) | Not openly licensed — Rospatent 2019621537; personal, non-commercial use only |
| Irvine | NOAA — GHCN-Daily, Access Data Service v1 | `daily-summaries` (TMAX/TMIN/PRCP), stations USC00049087/044303 (spliced) + USW00093184 | U.S. Government work — no copyright restriction |

Full dataset URLs and citation text are in each site's report above and in
`R/sites/<site>.R`. Météo-France field definitions land in
`data/raw/Q_descriptif_champs_*.txt` after the first `make prepare`.

### Stations

| Site | Code | Name | Record | Role |
|---|------|------|--------|------|
| Castanet-Tolosan | `31035001` | Auzeville-Tolosane-INRAE | 2002→ | Local station, on the edge of Castanet-Tolosan (INRAE/ENSAT campus) |
| Castanet-Tolosan | `31069001` | Toulouse-Blagnac | 1947→ | Long regional reference; used for the trend and the daily climatology |
| Zurich | `REH` | Zürich-Affoltern | 1961→ (temp. 1978→) | Local station, in Zurich's Affoltern district (MeteoSwiss automatic network) |
| Zurich | `SMA` | Zürich-Fluntern | 1864→ (TN/TX 1881→) | Long regional reference; MeteoSwiss's homogeneous series for the trend and climatology |
| Karlsruhe | `02523` | Karlsruhe-Wolfartsweier | 1931→ | Local station — **rainfall only**, no temperature record near Grötzingen (see below) |
| Karlsruhe | `04177` | Rheinstetten | 1876→ | Long regional reference — spliced with predecessor 02522 (city-centre, 1876→2008) at its 2008-11-01 handoff to Rheinstetten, closing what would otherwise be a 1985–2008 gap in 04177's own record |
| Santa Fe | `USW00023049` | Santa Fe Airport | 1941→ | Local station — NOAA's own GHCN-Daily archive has no digitized daily temperature for it between 1959 and 1996 |
| Santa Fe | `USC00298085` | Santa Fe | 1874→ | Long reference — spliced with predecessor 298072 (in-town, 1874→1972) at its 1972-04-01 handoff to 298085, a few miles south |
| Honolulu | `USC00516395` | Honolulu-Moanalua | 1905→ | Local station — **rainfall only**; a valley neighbourhood between the airport and downtown, 107 complete years of 122 |
| Honolulu | `USW00022521` | Honolulu Airport | 1940→ | Long regional reference; one continuous record, no splice needed |
| Nouméa | `98818002` | Nouméa-Magenta | 1964→ | Local station, the in-town domestic airfield; complete, no gaps |
| Nouméa | `98818001` | Nouméa | 1950→ | Long regional reference; used for the trend and the daily climatology |
| Moscow | `27612` | Moscow | 1948→2025 | Single station — no local pairing; this export has no second WMO index |
| Voronezh | `34123` | Voronezh | 1940→2026 | Single station — no local pairing; this export has no second WMO index |
| Irvine | `USW00093184` | John Wayne Airport | 1999→ | Local station, on Irvine's border — no splice needed, but the shortest record of the pair |
| Irvine | `USC00044303` | Irvine | 1915→ | Long reference — spliced with predecessor 049087 (Tustin Irvine Ranch, 1915→2003) at its 2003 handoff to 044303, a few miles away |

> The "Record" column is each station's raw first→last year; the trend prose and
> "last decade" tables instead start from each station's first *complete* year
> (≥ 330 valid days) — a station can legitimately appear with three different
> start years across the report depending on whether the completeness filter
> applies.

> **Why these local stations?** None of the first three national datasets has a
> station literally named for its target town/district. Auzeville-Tolosane-INRAE
> sits on Castanet-Tolosan's boundary; Zürich-Affoltern is the closest full
> MeteoSwiss station to Zurich's Affoltern district; Karlsruhe-Wolfartsweier is
> the nearest *active* DWD station to Grötzingen, but the nearest one that once
> had a temperature record too (Augustenberg, under 1 km away) closed in 1985 —
> so Karlsruhe's local tier is rainfall-only. Santa Fe Airport's own digitized
> record has an unexplained 1959–1996 hole in NOAA's archive; Honolulu, like
> Karlsruhe, has no independent in-town temperature station, so its local tier
> is rainfall-only too; Nouméa-Magenta is the one exception — a genuinely
> complete, gap-free local record. John Wayne Airport, Irvine's local station,
> is gap-free too, but only from 1999 — much shorter than the spliced 1915→
> reference. Moscow and Voronezh are a different case
> entirely: manually exported from Roshydromet's AISORI-M with a single WMO
> index each, so there is no local pairing at all. Each report's own
> "Why...?" note has the full explanation.

## Project layout

```
climatudes/
├── README.md                  this file — each site's report block is generated
├── Makefile                   reproducible pipeline (make all SITE=<site>)
├── R/
│   ├── lib/
│   │   ├── common.R           shared constants, palette, deg_label(), fetch/verify/write helpers
│   │   └── narrative.R        shared report prose/number logic (build_common_fills())
│   ├── sites/
│   │   ├── castanet.R         Castanet-Tolosan: stations, paths, citation, narrative facts
│   │   ├── zurich.R           Zurich: same, for MeteoSwiss
│   │   ├── karlsruhe.R        Karlsruhe: same, for DWD
│   │   ├── santafe.R          Santa Fe: same, for NOAA GHCN-Daily
│   │   ├── honolulu.R         Honolulu: same, for NOAA GHCN-Daily
│   │   ├── noumea.R           Nouméa: same, for Météo-France dept. 988
│   │   ├── moscow.R           Moscow: same, for Roshydromet/AISORI-M (manual export)
│   │   ├── voronezh.R         Voronezh: same, for Roshydromet/AISORI-M (manual export)
│   │   └── irvine.R           Irvine: same, for NOAA GHCN-Daily
│   ├── sources/
│   │   ├── meteofrance.R      fetch + normalize Météo-France's format (Castanet-Tolosan, Nouméa)
│   │   ├── meteoswiss.R       fetch + normalize MeteoSwiss's format
│   │   ├── dwd.R              fetch + normalize DWD's format
│   │   ├── noaa.R             fetch + normalize NOAA GHCN-Daily's format (Santa Fe, Honolulu)
│   │   └── meteoru.R          read (not fetch) a manual AISORI-M export (Moscow, Voronezh)
│   ├── 00_prepare_data.R      generic: dispatches to R/sources/<site's source>.R
│   ├── 01_plot.R              generic: build the five figures + annual tables + stats
│   ├── 02_report.R            generic: assemble the self-contained HTML report
│   └── 03_readme.R            generic: render the same report into this site's README block
├── data/                      (created on first run, git-ignored)
│   ├── raw/                   Castanet-Tolosan's raw files (legacy root location)
│   ├── raw/<site>/            every other site's raw files
│   └── processed/[<site>/]    small gzipped station extract + intermediates, per site
└── outputs/                   (created on first run, mostly git-ignored)
    ├── figures/               Castanet-Tolosan's five PNGs (legacy root location)  ← tracked
    ├── <site>/figures/        every other site's five PNGs                        ← tracked
    ├── [<site>/]annual_temperatures.csv
    ├── [<site>/]annual_rainfall.csv
    └── [<site>/]temperature_report.html   ← the shareable deliverable (fully self-contained)
```

Every source module normalizes its site's raw data to the same six columns
(`NUM_POSTE`, `AAAAMMJJ`, `TN`, `TX`, `TNTXM`, `RR`) before writing the gzipped
extract, so stages 01–03 never need to know which upstream provider a site
uses — they only read `R/sites/<site>.R` for names, roles, thresholds and
citation text.

**Version-controlled: the R scripts, the Makefile, this README and every
site's PNG figures.** The figures are the one generated artifact that is
committed — GitHub can only render them in the README if they are in the
repository. The base64 HTML reports (~3–4 MB each) are *not* committed.
Everything else — including `data/raw/` — is downloaded or regenerated by
`make all`, so a fresh clone rebuilds any site in a few seconds.

**Everything stays compressed.** Raw archives are never decompressed to disk
— they are read directly via a streaming pipe (`gzip -dc`, or a per-call temp
dir for DWD's zips). Stage 00 slices them down to just the stations in use and
caches that as a single small gzipped extract per site (`stations_daily.csv.gz`,
well under 1 MB — vs. tens to well over a hundred MB of raw upstream data).

### Fetching the data

Stage 00 downloads any raw file missing from the site's raw directory, so
there is nothing to fetch by hand. Each source has its own quirks, documented
where the fetch logic lives (`R/sources/<source>.R`) rather than repeated here:

- **Météo-France** (Castanet-Tolosan) — three era-named files that rotate every
  January; when 2027 opens, `latest-2025-2026` starts 404ing and `MF_ERAS`-
  equivalent (`R/sites/castanet.R`'s `meteofrance$eras`) needs bumping. Stage
  00's error message says so if you hit it. `make refresh` re-downloads the
  current era.
- **MeteoSwiss** (Zurich) — fixed, non-rotating URLs (a `historical` file plus a
  rolling `recent` file per station/dataset); Zürich-Fluntern needs two
  datasets merged (temperature from the homogeneous `ogd-nbcn`, rainfall from
  `ogd-smn`, since the homogeneous series carries no daily precipitation).
- **DWD** (Karlsruhe) — one zip per station/period; the historical zip's
  filename embeds its own date range and shifts over time, so it is discovered
  from a live directory listing rather than hardcoded.
- **NOAA GHCN-Daily** (Santa Fe, Honolulu) — the tokenless Access Data Service
  v1 (`ncei.noaa.gov/access/services/data/v1`), one CSV request per station
  covering its whole history; no historical/recent split needed, since a
  station's full record is a few hundred KB either way.
- **Météo-France** (Nouméa) — same module and file layout as Castanet-Tolosan,
  just a different `dept` (`988`, New Caledonia's pseudo-département code in
  this dataset — it has no mainland département number of its own).
- **Roshydromet / AISORI-M** (Moscow, Voronezh) — the one source that is
  genuinely manual: `aisori-m.meteo.ru` is a login/session-gated web app with
  no stable, scriptable URL. `R/sources/meteoru.R` does not fetch anything —
  it reads whichever `.zip` export already sits in `data/raw/<site>/` (most
  recently modified wins) and errors with the exact query steps if none is
  found. Re-running the export by hand and dropping the new `.zip` in is how
  these two sites get fresher data; there is no `make refresh` for them.

`make refresh SITE=<site>` re-downloads that site's rolling/current data and
rebuilds everything (except Moscow/Voronezh — see above).

## How to run

Requirements: **R ≥ 4** with `data.table`, `ggplot2`, `scales`, `ragg`,
`ggrepel`, `base64enc`. No pandoc needed — every HTML report is built directly.

```sh
make all                  # castanet (default): fetch -> prepare -> plots -> report -> README
make all SITE=zurich      # same, for Zurich
make all SITE=karlsruhe   # same, for Karlsruhe
make all SITE=santafe     # same, for Santa Fe
make all SITE=honolulu    # same, for Honolulu
make all SITE=noumea      # same, for Nouméa
make all SITE=moscow      # same, for Moscow (reads data/raw/moscow/*.zip — see Fetching the data)
make all SITE=voronezh    # same, for Voronezh
make all-sites            # run every site in R/sites/
make refresh SITE=zurich  # re-download that site's rolling/current data, then rebuild it
make open SITE=zurich     # open that site's HTML report (macOS)
```

Or run the stages directly from the project root (`SITE` defaults to `castanet`):

```sh
SITE=zurich Rscript R/00_prepare_data.R
SITE=zurich Rscript R/01_plot.R
SITE=zurich Rscript R/02_report.R
SITE=zurich Rscript R/03_readme.R
```

`make clean` (optionally with `SITE=<site>`) removes everything regenerable for
that site (processed data + outputs), leaving the downloaded raw files and the
README in place.

## Two ways to read the same report

Both draw their **numbers** from one file per site
(`[data/processed/<site>/]trend_stats.rds`), so no figure in one can contradict
a figure in the other for that site. (The two templates share their prose
logic — `R/lib/narrative.R` — so wording can still differ in formatting but not
in substance; the clauses that depend on the data — "all of them recent", the
both-extremes footnote — are generated in R rather than hand-written precisely
so they can't drift.)

- **This README** — stage 03 rewrites the block between each site's
  `BEGIN REPORT:<site>` / `END REPORT:<site>` markers and links the committed
  PNGs, so every site's analysis renders straight away on the repository page.
  Edit `R/03_readme.R` or `R/lib/narrative.R`, never the blocks themselves.
- **`<outputs>/temperature_report.html`** — stage 02 embeds that site's figures
  as base64 in a single styled file that needs nothing else to display. Email
  it, copy it to a USB stick, or open it offline.

## Licence

Source data:

- Castanet-Tolosan © Météo-France, *Licence Ouverte / Open Licence (Etalab 2.0)*.
- Zurich © MeteoSwiss Open Data — attribution required: "Source: MeteoSwiss".
- Karlsruhe © DWD (Deutscher Wetterdienst), *Creative Commons BY 4.0*.
- Santa Fe and Honolulu — NOAA / NCEI GHCN-Daily, U.S. Government work, no copyright restriction.
- Nouméa © Météo-France, *Licence Ouverte / Open Licence (Etalab 2.0)*.
- Moscow and Voronezh © Roshydromet / RIHMI-WDC (AISORI-M) — not openly
  licensed (registered as an official reference publication, Rospatent
  2019621537); used here for personal, non-commercial analysis only.

Please retain the attribution above when reusing the figures or data.
