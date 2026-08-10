# Climatudes — temperatures around Castanet-Tolosan

A small, reproducible analytics project that turns Météo-France daily
climatological records into a readable report on local warming around
**Castanet-Tolosan** (Haute-Garonne, France).

The report below is generated. `make all` (a few seconds, including the
download) refreshes the data, rebuilds the five figures, regenerates this
section from them, and writes a self-contained
`outputs/temperature_report.html` you can email or read offline.

<!-- BEGIN REPORT -->

## A warming climate, seen from Castanet-Tolosan

*Météo-France daily temperature records, 1947 to 2025 — plus 2026 so far.*

Météo-France daily records for the Castanet-Tolosan area tell an unambiguous story:
since the mid-20th century, minimum, maximum and mean temperatures have all risen —
steadily and continuously.

| Headline number | Value |
|---|---:|
| Warming rate, mean temperature (Toulouse-Blagnac) | **+0.34 °C / decade** |
| Total rise over 78 years (1947 → 2025) | **+2.7 °C** |
| Mean of the last decade (vs 12.9 °C in 1947–1956) | **15.2 °C** |
| Frost days per year, 1947–1956 → 2016–2025 | **46 → 18** |
| Hot days (≥ 30 °C) per year, 1947–1956 → 2016–2025 | **24 → 47** |
| Complete station-years analysed | **101** |
| 2026 year-to-date (Jan 1 – Aug 8), against 79 prior years | **#1 of 80 — record** |

### The long view: annual means

![Annual mean temperatures around Castanet-Tolosan, 1947 to 2025, all three series rising](outputs/figures/temperature_series.png)

<sub>Annual means of daily temperatures. The thick curves are LOESS smoothings that
highlight the climate trend; the points are annual means. The green series
(Auzeville-Tolosane-INRAE) is the station on the edge of Castanet-Tolosan; it tracks
the long Toulouse-Blagnac reference mean almost exactly.</sub>

At Toulouse-Blagnac — the station with the longest record (1947→2025) — the annual
mean temperature rises by **+0.34 °C per decade**, about **+2.7 °C** over the
whole period. The local Auzeville-Tolosane-INRAE station, on the edge of
Castanet-Tolosan, only covers 2004→2025. Its slope over that shorter,
more recent window is steeper (+0.83 °C/decade) — but so is Blagnac’s over
the *same* years (+0.91 °C/decade): recent decades warm faster, and
the local station sits almost exactly on the regional mean. The local and regional
signals are the same.

### This year, against every year before it

![Per-year mean over the same Jan-to-cutoff window, as a departure from the long-term normal, with 2026 the largest bar](outputs/figures/temperature_ytd.png)

<sub>Each bar is a year’s mean over the <em>same window</em> — <strong>Jan 1 – Aug 8</strong> —
shown as its departure from the long-term normal (13.4 °C): red above, blue
below. Comparing each year over the identical part-of-year is the only fair way to place
a year that is still in progress against history. The bars swing from blue to red over
the decades — the warming.</sub>

Measured like-for-like, **2026 is the warmest Jan 1 – Aug 8 in 80 years** at Toulouse-Blagnac: **16.7 °C** — +0.9 °C above the previous record (2025, 15.8 °C) and **+3.2 °C above the long-term normal** (13.4 °C). This is exactly the point of the chart: a year still in progress can already stand out against the whole record.

> [!NOTE]
> A partial year cannot be compared to other years’ *full-year* means — it is still
> missing the warm late-summer and autumn tail. That is why 2026 appears on the
> long-view chart above only as a marked, hollow “to date” point (seasonally incomplete,
> so lower than its eventual annual figure), while its real, like-for-like standing is
> the chart here.

### Every year, day by day

![Daily temperature climatology, every year January to December, hot years red and cold years blue](outputs/figures/temperature_climatology.png)

<sub>Each thin line is a single year’s daily mean temperature from January to December
(1947–2025, 79 years), smoothed with a centred
<strong>3-day rolling mean</strong> (each day = the average of itself
±1 day(s)) to tame day-to-day jitter while keeping the shape. The dark line
is the long-term daily normal; the bold red line is <strong>2026 so far</strong>.
Years whose smoothed daily mean ever rose above <strong>+30 °C</strong> are
highlighted in red and labelled; years that ever fell below
<strong>-5 °C</strong> in blue.</sub>

> [!NOTE]
> **Hottest and coldest years.** Measured on the smoothed daily-mean curve,
> **5** years pushed above +30 °C (2003, 2019, 2022, 2023, 2025) — all of them recent —
> while **10** years dropped below -5 °C (1947, 1954, 1956, 1960, 1962, 1963, 1971, 1985, 1987, 2012), all but one before 2000.
> No single year managed to hit both extremes. The hot extremes and the cold extremes fall in different
> eras, which is itself a fingerprint of the warming trend. <sub>(If the threshold is applied instead to the raw, unsmoothed daily mean, 1947 and 1987 each touch both extremes.)</sub>

### The record days

The single most extreme days in each station’s record. “Hottest” is the highest daily
maximum (TX), “coldest” the lowest daily minimum (TN).

| Station (record span) | Extreme | Date | Min (TN) | Max (TX) |
|---|---|---|---:|---:|
| Auzeville-Tolosane-INRAE <sub>2002–2026</sub> | Hottest 🔥 | 2023-08-23 | 21.9 | **42.1** |
| Auzeville-Tolosane-INRAE <sub>2002–2026</sub> | Coldest ❄️ | 2012-02-09 | **-12.1** | -1.4 |
| Toulouse-Blagnac <sub>1947–2026</sub> | Hottest 🔥 | 2023-08-23 | 24.1 | **42.4** |
| Toulouse-Blagnac <sub>1947–2026</sub> | Coldest ❄️ | 1956-02-15 | **-19.2** | -4.1 |

The all-time heat (Aug 2023) is recent at both stations, while the deepest cold is
decades old (Feb 1956 at Blagnac) — the same warming signature seen above.

### The last decade (Toulouse-Blagnac)

| Year | Min (TN) | Max (TX) | Mean |
|---|---:|---:|---:|
| 2016 | 10.0 | 19.3 | **14.7** |
| 2017 | 9.7 | 19.5 | **14.6** |
| 2018 | 10.7 | 19.5 | **15.1** |
| 2019 | 10.0 | 19.9 | **15.0** |
| 2020 | 10.6 | 20.2 | **15.4** |
| 2021 | 9.7 | 19.1 | **14.4** |
| 2022 | 11.2 | 21.3 | **16.3** |
| 2023 | 10.7 | 20.8 | **15.8** |
| 2024 | 10.5 | 19.6 | **15.1** |
| 2025 | 10.7 | 20.6 | **15.7** |
| 2026 *(to date)* | 11.4 | 21.9 | **16.7** |

### Frost days halved, hot days doubled

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
complete decades. Frost is retreating just as heat advances — the same warming, read
off the calendar instead of the thermometer.</sub>

### What about the rain?

Temperature is only half of a climate. Rainfall tells a very different — and much
quieter — story: over the same 79 years, annual precipitation at
Toulouse-Blagnac shows **no statistically significant trend**.

![Annual rainfall totals around Castanet-Tolosan, with a flat long-term trend](outputs/figures/rain_series.png)

<sub>Annual total precipitation. The dashed line is Toulouse-Blagnac’s long-term mean
(633 mm/yr); the thick curves are LOESS smoothings. The year-to-year swings are
large — from 378 mm (1967) to 915 mm (1993) —
but the long-run slope (-8 mm/decade) is flat and not significant
(p = 0.16).</sub>

That contrast is the point. The very same daily records that show an unmistakable,
statistically strong warming signal show *no* comparable signal in how much it rains. A
dataset that manufactured trends would have produced one here too; this one does not.

![Monthly rainfall through the year at Toulouse-Blagnac, one line per year](outputs/figures/rain_climatology.png)

<sub>Rain through the year: each grey line is one year’s monthly totals, the dark line the
long-term monthly normal, the bold blue line 2026 so far. May is the
wettest month on average (72 mm), July the driest
(41 mm) — but the spread between years dwarfs the seasonal cycle, which is
exactly why no annual trend emerges.</sub>

### Methodology

- **Variables.** Minimum = `TN`, maximum = `TX`, mean = `(TN+TX)/2` (field `TNTXM`), in °C;
  rainfall = `RR` (daily precipitation, in mm).
- **Annual aggregation.** Arithmetic mean of daily values over each calendar year. The
  long-term trend uses only complete years (≥ 330 valid days). The in-progress
  year is shown separately — as a hollow “to date” marker on the trend chart, and (for a
  fair record comparison) against the same calendar window (Jan 1 → cutoff) of every
  prior year, keeping only years with ≥ 150 valid days in that window.
- **Daily climatology.** Each year’s daily mean is smoothed with a centred
  3-day rolling mean (unweighted moving average, computed per year so
  December never bleeds into January; the first/last 1 day(s) keep their raw
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
  `R/02_report.R` → `R/03_readme.R`), driven by `make all`. The figures above and the
  numbers in this section are regenerated from the source data on every run — see
  [Data source](#data-source) below for the full citation.

<sub>Figures and numbers above are generated — edit `R/03_readme.R`, not this block.</sub>

<!-- END REPORT -->

## Data source

Météo-France — **Données climatologiques de base – quotidiennes**, published
under the *Licence Ouverte / Open Licence (Etalab)* on the Météo-France open
data portal:

- Dataset: <https://meteo.data.gouv.fr/datasets/6569b51ae64326786e4e8e1a>
- Portal: <https://meteo.data.gouv.fr> · also mirrored on <https://data.gouv.fr>
- Scope used here: department **31** (Haute-Garonne), the `RR-T-Vent`
  (rainfall / temperature / wind) daily files, split into three eras
  (`avant-1949`, `previous-1950-2024`, `latest-2025-2026`).

Field definitions are in `data/raw/Q_descriptif_champs_*.txt`.

### Stations

| Code | Name | Record | Role |
|------|------|--------|------|
| `31035001` | Auzeville-Tolosane-INRAE | 2002→ | Local station, on the edge of Castanet-Tolosan (INRAE/ENSAT campus) |
| `31069001` | Toulouse-Blagnac | 1947→ | Long regional reference; used for the trend and the daily climatology |

> The "Record" column is each station's raw first→last year. The trend prose and
> the "last decade" table instead start Auzeville at **2004**, its first *complete*
> year (≥ 330 valid days); 2002–2003 exist but are too sparse to average. The
> record-days table shows the raw span, ending 2026 (it scans every day, complete
> year or not) — so the same station legitimately appears as 2002, 2004 and 2026
> in different places depending on whether the completeness filter applies.

> There is no Météo-France station named literally "Castanet-Tolosan".
> Auzeville-Tolosane-INRAE sits on its boundary and is the most representative
> local record.

## Project layout

```
climatudes/
├── README.md                  this file — the report block is generated
├── Makefile                   reproducible pipeline (make all)
├── R/
│   ├── config.R               mirror URL, era names, paths, station codes, palette
│   ├── 00_prepare_data.R      download raw .csv.gz -> small gzipped station extract
│   ├── 01_plot.R              build the five figures + annual tables + stats
│   ├── 02_report.R            assemble the self-contained HTML report
│   └── 03_readme.R            render the same report into README.md
├── data/                      (created on first run, git-ignored)
│   ├── raw/                   downloaded .csv.gz (kept compressed) + field docs
│   └── processed/             small gzipped station extract + intermediates
└── outputs/                   (created on first run, mostly git-ignored)
    ├── figures/               temperature_series/_ytd/_climatology + rain_series/_climatology .png  ← tracked
    ├── annual_temperatures.csv
    ├── annual_rainfall.csv
    └── temperature_report.html   ← the shareable deliverable (fully self-contained)
```

**Version-controlled: the R scripts, the Makefile, this README and the five
PNG figures.** The figures are the one generated artifact that is committed —
GitHub can only render them in the README if they are in the repository. The
base64 HTML report (~3 MB) is *not* committed. Everything else — including
`data/raw/` — is downloaded or regenerated by `make all`, so a fresh clone
rebuilds the whole project in a few seconds.

**Everything stays compressed.** The raw `.csv.gz` files are never decompressed
to disk — they are read directly via a streaming `gzip -dc` pipe. Stage 00
slices them down to just the two stations we use and caches that as a single
small gzipped extract (`data/processed/stations_daily.csv.gz`, ~0.35 MB vs
~140 MB if the raw files were fully unzipped).

### Fetching the data

Stage 00 downloads any raw file that is missing from `data/raw/`, so there is
nothing to fetch by hand. Details, all defined in `R/config.R`:

- **Mirror** — `MF_BASE_URL`, currently the OVH object store
  (`meteofrance.s3.sbg.io.cloud.ovh.net/data/synchro_ftp/BASE/QUOT`); a
  data.gouv mirror is noted alongside it as a fallback. Plain HTTPS, public,
  no credentials.
- **Files** — `Q_31_<era>_RR-T-Vent.csv.gz` for the three eras in `MF_ERAS`,
  plus the field-definition doc. The sibling `autres-parametres` files
  (humidity, pressure, sunshine) are not used and are not downloaded.
- **Transformation** — the gzipped data is stored exactly as served, verified
  with `gzip -t`. The field doc is served as `.csv` with CRLF endings; it is
  normalised to LF and saved as `.txt`. Downloads land in a `.part` file and are
  only moved into place after verification, so an interrupted transfer cannot
  masquerade as a cached file.
- **Refreshing** — only the `latest-*` era changes day to day:
  `make refresh` re-downloads it and rebuilds everything. Météo-France publishes
  roughly 3 days behind the current date, so a small gap is normal.

> ⚠️ **The upstream filenames encode years and rotate every January.** When 2027
> opens, `latest-2025-2026` starts returning 404 and its rows reappear inside
> `previous-1950-2026`. Nothing is lost upstream, but `MF_ERAS` in `R/config.R`
> must be bumped for the new cycle — stage 00's error message says so if you hit
> it.

## How to run

Requirements: **R ≥ 4** with `data.table`, `ggplot2`, `scales`, `ragg`,
`ggrepel`, `base64enc`. No pandoc needed — the HTML is built directly.

```sh
make all      # fetch -> prepare -> plots -> report -> README (works on a fresh clone)
make refresh  # re-download the current era, then rebuild
make open     # open the HTML report (macOS)
```

Or run the stages directly from the project root:

```sh
Rscript R/00_prepare_data.R
Rscript R/01_plot.R
Rscript R/02_report.R
Rscript R/03_readme.R
```

`make clean` removes everything regenerable (processed data + outputs), leaving
the downloaded raw files and the README in place.

## Two ways to read the same report

Both draw their **numbers** from one file (`data/processed/trend_stats.rds`), so
no figure in one can contradict a figure in the other. (The two templates carry
their own prose, so wording can still drift; the clauses that depend on the data
— "all of them recent", the both-extremes footnote — are generated in R rather
than hand-written precisely so they can't.)

- **This README** — stage 03 rewrites the block between the `BEGIN REPORT` /
  `END REPORT` markers and links the committed PNGs, so the analysis renders
  straight away on the repository page. Edit `R/03_readme.R`, never the block.
- **`outputs/temperature_report.html`** — stage 02 embeds the figures as base64
  in a single styled file that needs nothing else to display. Email it, copy it
  to a USB stick, or open it offline.

## Licence

Source data © Météo-France, *Licence Ouverte / Open Licence (Etalab 2.0)*.
Please retain the attribution above when reusing the figures or data.
