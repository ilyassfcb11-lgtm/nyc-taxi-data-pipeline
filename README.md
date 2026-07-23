# NYC Taxi Operations Intelligence Platform

**End-to-end analytics pipeline | NYC Yellow Taxi 2025 | BigQuery · dbt · Python · Tableau**

---

## What This Project Is

An operations intelligence system that transforms 38 million raw NYC taxi trip records into clean, tested, business-ready dashboards — built to answer real operational questions about fleet demand, revenue efficiency, and zone performance.

This is not a school assignment. It is a portfolio project designed to demonstrate end-to-end data skills across three roles: Data Engineer, Analytics Engineer, and Data Analyst.

---

## Business Questions Answered

- When and where is taxi demand highest across NYC?
- Which zones and routes generate the most revenue per hour?
- How efficiently is fleet capacity being used relative to demand?
- Where should fleet resources be allocated during peak hours?
- Which operational KPIs best describe system performance?

---

## Architecture

```
NYC TLC Website (Parquet files)
        │
        ▼
Python Ingestion Script
        │
        ▼
BigQuery — raw dataset (raw_taxi_trips, raw_zone_lookup)
        │
        ▼ dbt
BigQuery — staging dataset (stg_trips, stg_zones)
        │
        ▼ dbt
BigQuery — core dataset (fact_trips, dim_zone, dim_date)
        │
        ▼ dbt
BigQuery — mart dataset (mart_hourly_demand, mart_zone_kpis, ...)
        │
        ▼
Tableau Public Dashboards (5 pages)
```

CI/CD via GitHub Actions — runs `dbt run` + `dbt test` on every push.

---

## Tech Stack

| Layer | Tool |
|---|---|
| Ingestion | Python 3.11, pandas, pyarrow, google-cloud-bigquery |
| Storage | Google BigQuery (partitioned tables) |
| Transformation | dbt Core 1.7 + dbt-bigquery adapter |
| Testing | dbt built-in tests + custom SQL tests |
| CI/CD | GitHub Actions |
| Visualization | Tableau Public |

---

## Project Structure

```
├── ingestion/          # Python ingestion scripts
├── dbt_project/        # dbt models, tests, documentation
│   ├── models/
│   │   ├── staging/    # stg_trips, stg_zones
│   │   ├── core/       # fact_trips, dim_zone, dim_date
│   │   └── mart/       # pre-aggregated KPI tables
│   └── tests/          # custom data quality tests
├── analysis/           # EDA notebooks
├── dashboards/         # Tableau workbook files
├── .github/workflows/  # GitHub Actions CI/CD
├── PROJECT_BRIEF.md    # Full project overview (plain English)
├── ARCHITECTURE.md     # Technical architecture details
├── ROADMAP.md          # Phase-by-phase timeline
├── KPIS.md             # KPI definitions and formulas
├── ANALYSIS.md         # Published business analysis
├── DATA_QUALITY.md     # Testing strategy and results
└── INTERVIEW_PREP.md   # Phase-by-phase interview Q&A
```

---

## Dataset

- **Source:** NYC Taxi & Limousine Commission (TLC)
- **Scope:** Yellow Taxi Trip Records, January–December 2025
- **Scale:** ~38 million rows, ~12 GB raw
- **Supplementary:** TLC Taxi Zone Lookup (265 zones)
- **URL:** https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page

---

## Key KPI Categories

- **Demand KPIs** — trips per hour, peak hour demand index, weekend vs. weekday ratio
- **Productivity KPIs** — revenue per hour, revenue per trip, revenue per mile
- **Efficiency KPIs** — route efficiency score, congestion proxy, zone efficiency score
- **IE / Operations KPIs** — fleet allocation priority score, peak load factor, zone utilization proxy

Full definitions with formulas and business meaning in [`KPIS.md`](KPIS.md).

---

## Dashboards

Published on Tableau Public — link added after Phase 3.

| Page | Business Question |
|---|---|
| Executive Overview | Overall system performance |
| Demand Analysis | When and where is demand highest? |
| Revenue Efficiency | Which zones and hours maximize revenue? |
| Zone & Route Analysis | Which routes and zones are most efficient? |
| Recommendations | What operational actions do the data support? |

---

## How to Run

### 1. Clone the repository
```bash
git clone https://github.com/YOUR_USERNAME/nyc-taxi-intelligence.git
cd nyc-taxi-intelligence
```

### 2. Set up Python environment
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 3. Configure credentials
```bash
cp .env.example .env
# Edit .env with your GCP project ID and credentials path
```

### 4. Run ingestion
```bash
python ingestion/ingest.py
```

### 5. Run dbt
```bash
cd dbt_project
dbt run
dbt test
```

---

## Project Status

| Phase | Description | Status |
|---|---|---|
| Phase 0 | Setup — repo, environment, GCP | ✅ Complete |
| Phase 1 | Ingestion — Python + BigQuery raw load | 🔄 In Progress |
| Phase 2 | Cleaning + KPIs — staging, core, mart | ⏳ Pending |
| Phase 3 | Visualization — Tableau dashboards | ⏳ Pending |
| Phase 4 | dbt — full model layer | ⏳ Pending |
| Phase 5 | Testing — data quality checks | ⏳ Pending |
| Phase 6 | CI/CD + polish | ⏳ Pending |

---

## Author

**Ilyass**  
M.S. Computer Science, CUNY Brooklyn College (GPA: 3.97, Dec 2025)  
Background: Manufacturing & Operations Data Analytics (Leoni, Heidelberg)  

*Built as a professional portfolio project for Data Analyst, Analytics Engineer, and Data Engineer applications.*
