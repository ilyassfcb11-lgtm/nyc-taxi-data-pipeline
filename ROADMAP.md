# Roadmap — NYC Taxi Operations Intelligence Platform

**Total budget:** 8–10 weeks at ~8 hours/week  
**Target start:** Phase 0 now  
**Checkpoint 1 (start applying):** End of Phase 3 (~4–5 weeks)  
**Checkpoint 2 (full project):** End of Phase 6 (~8–10 weeks)

---

## How to Read This Roadmap

Each phase has four things:
- **What we build** — the concrete deliverable
- **Why it matters** — what it demonstrates to employers
- **Role** — which job title this work belongs to (DE, AE, DA)
- **Risk** — what could make this phase take longer

Time estimates assume 8 hours per week. If a phase takes longer, the roadmap notes will be updated here.

---

## Phase 0 — Setup

**Duration:** 1–2 days (4–8 hours)  
**Status:** ✅ Complete  
**Role:** Data Engineering

### What we build
- GitHub repository with full folder structure
- Python virtual environment with all dependencies installed
- Google Cloud project with BigQuery enabled
- Four BigQuery datasets created: `raw`, `staging`, `core`, `mart`
- Service account credentials configured
- `.env` file for local secrets management

### Deliverables produced this phase
- `README.md` — public-facing project overview
- `requirements.txt` — Python dependencies
- `.gitignore` — keeps credentials and large files out of Git
- `ROADMAP.md` — this file
- `PROJECT_BRIEF.md` — full project overview
- `ARCHITECTURE.md` — technical architecture

### Why it matters
A project that cannot be set up from scratch is not a real project. Employers who look at your GitHub repo will check whether it can be reproduced. Clean setup signals professionalism.

### Risk
GCP IAM and billing setup can be confusing the first time. Service account permissions often need troubleshooting. Budget 2–3 extra hours if this is your first time with Google Cloud.

---

## Phase 1 — Ingestion

**Duration:** 3–4 days (10–16 hours)  
**Status:** ⏳ Pending  
**Role:** Data Engineering

### What we build
- `ingestion/ingest.py` — the main ingestion script
- Downloads all 12 monthly Yellow Taxi Parquet files from the TLC website
- Validates schema before loading (catches TLC format changes early)
- Loads data to `raw.raw_taxi_trips` in BigQuery, partitioned by `pickup_date`
- Loads the zone lookup CSV to `raw.raw_zone_lookup`
- `ingestion/config.py` — configuration constants (URLs, dataset names, table names)

### Deliverables produced this phase
- Working ingestion script (tested on January 2025 first, then all 12 months)
- `raw.raw_taxi_trips` table in BigQuery (~38M rows, partitioned)
- `raw.raw_zone_lookup` table in BigQuery (265 rows)

### Why it matters
Ingestion is the foundation. If raw data is not in BigQuery, nothing else can be built. This phase demonstrates: Python scripting, file handling, schema validation, cloud data loading, and reliability thinking (what happens if a file fails halfway through?).

### Risk
Downloading 12 files × ~500MB each takes time and bandwidth. We load January first to validate the full pipeline, then run all 12 months. Idempotent loading (safe to re-run) is built in from the start.

---

## Phase 1.5 — Exploratory Data Analysis (EDA)

**Duration:** 1–2 days (6–10 hours)  
**Status:** ⏳ Pending  
**Role:** Data Analysis + Analytics Engineering

### What we build
- `analysis/eda.ipynb` — Jupyter notebook with structured data exploration
- Distribution analysis: fares, distances, durations, passenger counts
- Missing value audit: which columns have nulls, how many, what pattern
- Outlier detection: impossibly long trips, negative fares, zero distances
- Temporal patterns: trips by hour, day of week, month
- Geographic patterns: top pickup and dropoff zones
- Key findings that inform cleaning decisions in Phase 2

### Why this phase exists
EDA is not optional. You cannot write good cleaning rules without knowing what is wrong with the data. You cannot design meaningful KPIs without knowing what patterns the data actually shows. EDA is also what feeds the `ANALYSIS.md` document and the business insights in Tableau.

### Why it matters to employers
EDA shows analytical thinking. It proves you did not just run a pipeline — you understood the data. In interviews, you will be asked "what surprised you about this dataset?" EDA gives you real answers.

---

## Phase 2 — Cleaning and KPIs

**Duration:** 3–4 days (12–18 hours)  
**Status:** ⏳ Pending  
**Role:** Analytics Engineering + Data Analysis

### What we build
- SQL cleaning logic for staging layer (applied in dbt Phase 4, written as raw SQL here)
- `staging.stg_trips` — cleaned, typed, renamed trip records
- `staging.stg_zones` — cleaned zone lookup
- `core.fact_trips` — star schema fact table
- `core.dim_zone` — zone dimension
- `core.dim_date` — date dimension
- `mart.mart_hourly_demand` — trips and revenue aggregated by hour + zone
- `mart.mart_zone_kpis` — zone-level KPI table
- `mart.mart_revenue_efficiency` — revenue KPIs by time period
- `mart.mart_route_analysis` — pickup-to-dropoff route metrics
- `KPIS.md` — full KPI definitions document

### Cleaning rules applied
- Remove trips outside 2025
- Remove trips with fare_amount ≤ 0
- Remove trips with trip_distance ≤ 0
- Remove trips with passenger_count = 0
- Remove trips with pickup_datetime = dropoff_datetime (zero duration)
- Cap extreme outliers (trips > 6 hours, fares > $500) — flag, not delete
- Cast all columns to correct types (timestamps, floats, integers)

### Why it matters
Clean data is trusted data. Dirty data produces wrong KPIs. Wrong KPIs produce wrong decisions. Cleaning is where analytical judgment lives — knowing which rows to remove and why, and being able to defend those decisions in an interview.

---

## Phase 3 — Visualization

**Duration:** 4–5 days (20–25 hours)  
**Status:** ⏳ Pending  
**Role:** Data Analysis

### What we build
- Tableau Public dashboard with five pages
- All five pages connect to BigQuery mart tables only
- Business insights and written interpretation for each page

### Five dashboard pages
1. **Executive Overview** — Total trips, total revenue, avg fare, avg distance for 2025. Month-over-month trend. Borough summary.
2. **Demand Analysis** — Heatmap of trips by hour and day of week. Peak hour demand index by zone. Weekend vs. weekday comparison.
3. **Revenue Efficiency** — Revenue per hour, per trip, per mile by zone and time period. Top and bottom performing zones.
4. **Zone & Route Analysis** — Top pickup zones, top dropoff zones, busiest routes. Zone efficiency scores mapped geographically.
5. **Recommendations** — Key findings stated as operational recommendations. Fleet allocation suggestions based on demand + efficiency KPIs.

### Deliverables produced this phase
- Published Tableau Public dashboard (live URL)
- Written insights for each page (added to `ANALYSIS.md`)

### Why it matters
This is what non-technical hiring managers see first. A polished dashboard communicates that you can translate data into business decisions, not just compute numbers.

### Risk
This is the highest-risk phase due to Tableau being a new tool. Plan for 20–25 hours. We build one page at a time, starting simple.

---

## CHECKPOINT 1 — First Portfolio-Ready Version

**Target:** End of Week 4–5  
**Action: Start applying for jobs here.**

At this point you have:
- A working Python ingestion pipeline
- Clean data in BigQuery with KPI tables
- Five Tableau dashboard pages published online
- Four written documents (PROJECT_BRIEF, ARCHITECTURE, ROADMAP, KPIS)
- A GitHub repo that demonstrates end-to-end thinking

What you tell employers: "I built an end-to-end operations analytics pipeline on NYC taxi data — Python ingestion, BigQuery, SQL KPI modeling, and Tableau dashboards. The second half of the project adds dbt and CI/CD, which I'm currently completing."

That is a complete, honest, impressive answer.

---

## Phase 4 — dbt

**Duration:** 5–7 days (15–25 hours)  
**Status:** ⏳ Pending  
**Role:** Analytics Engineering

### What we build
- Full dbt project initialized in `dbt_project/`
- All staging, core, and mart SQL migrated into dbt models
- `schema.yml` files with column descriptions for every model
- `dbt docs generate` — auto-generated documentation site
- dbt lineage graph showing how all tables depend on each other

### Why dbt changes everything
Before dbt: you have SQL files you run manually in a specific order. If you change one model, you must remember to re-run everything downstream. There is no documentation. There is no testing framework.

After dbt: you run `dbt run` and it figures out the order automatically. You run `dbt test` and it checks data quality. You run `dbt docs serve` and you have a full documentation website. Every transformation is version-controlled.

### Why it matters to employers
dbt is the standard tool for analytics engineering. Any company with a modern data stack uses it or is moving toward it. Having a working dbt project with proper layering is one of the highest-value things you can have on a resume for AE roles.

---

## Phase 5 — Testing and Data Quality

**Duration:** 3–4 days (8–12 hours)  
**Status:** ⏳ Pending  
**Role:** Analytics Engineering + Data Engineering

### What we build
- dbt built-in tests on every model: `not_null`, `unique`, `accepted_values`, `relationships`
- Custom SQL tests for business rules: fare > 0, distance > 0, pickup before dropoff
- `DATA_QUALITY.md` — documents what is tested, why, and what was found

### Why it matters
Bad data silently corrupts analysis. A manager who makes a fleet allocation decision based on a wrong number is worse off than a manager with no data at all. Testing is the professional's answer to "how do you know your data is correct?"

In interviews: "my dbt test suite catches X types of data issues before they reach the dashboards" is a strong answer that most junior candidates cannot give.

---

## Phase 6 — CI/CD and Final Polish

**Duration:** 2–4 days (8–16 hours)  
**Status:** ⏳ Pending  
**Role:** Data Engineering

### What we build
- `.github/workflows/dbt_ci.yml` — GitHub Actions workflow
- On every push: `dbt run` + `dbt test` run automatically
- GitHub Actions status badge added to README
- Final cleanup: remove dead code, complete all documentation
- `INTERVIEW_PREP.md` — all six phases worth of Q&A

### Why it matters
CI/CD for data pipelines is a skill almost no junior analyst has. It shows you think about data as an operational system that needs monitoring, not a one-time project.

---

## CHECKPOINT 2 — Full Professional Portfolio Project

**Target:** End of Week 8–10  
**Deliverables complete:**

| File | Status |
|---|---|
| `README.md` | ✅ |
| `PROJECT_BRIEF.md` | ✅ |
| `ARCHITECTURE.md` | ✅ |
| `ROADMAP.md` | ✅ |
| `KPIS.md` | ⏳ Phase 2 |
| `ANALYSIS.md` | ⏳ Phase 3 |
| `DATA_QUALITY.md` | ⏳ Phase 5 |
| `INTERVIEW_PREP.md` | ⏳ Phase 6 |
| `ingestion/ingest.py` | ⏳ Phase 1 |
| `analysis/eda.ipynb` | ⏳ Phase 1.5 |
| `dbt_project/` (full) | ⏳ Phase 4 |
| Tableau dashboard (live) | ⏳ Phase 3 |
| GitHub Actions CI | ⏳ Phase 6 |

---

## Timeline Summary

| Week | Phase | Hours | Cumulative |
|---|---|---|---|
| 1 | Phase 0 + Phase 1 start | 8 | 8 |
| 2 | Phase 1 complete + EDA | 8 | 16 |
| 3 | Phase 2 — Cleaning + KPIs | 8 | 24 |
| 4 | Phase 3 — Tableau (part 1) | 8 | 32 |
| 5 | Phase 3 — Tableau (part 2) | 8 | 40 |
| **—** | **CHECKPOINT 1 — START APPLYING** | | |
| 6 | Phase 4 — dbt (part 1) | 8 | 48 |
| 7 | Phase 4 — dbt (part 2) | 8 | 56 |
| 8 | Phase 5 — Testing | 8 | 64 |
| 9 | Phase 6 — CI/CD + Polish | 8 | 72 |
| 10 | Buffer / overflow | 8 | 80 |
| **—** | **CHECKPOINT 2 — FULL PROJECT DONE** | | |

---

*Last updated: Phase 0 — Setup complete*
