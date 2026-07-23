# Architecture — NYC Taxi Operations Intelligence Platform

## Overview

This document describes the full technical architecture of the project: every layer, every tool, every design decision, and the reasoning behind each one. It is a living document — it will be updated as the project evolves.

---

## System Architecture at a Glance

```
NYC TLC Website
      │
      │  12 × Parquet files (Yellow Taxi 2025) + Zone Lookup CSV
      ▼
Python Ingestion Script
      │
      │  Downloads, validates schema, loads to BigQuery
      ▼
┌─────────────────────────────────────────────────────────┐
│                    BIGQUERY PROJECT                     │
│                                                         │
│  raw dataset          staging dataset                   │
│  ─────────────        ───────────────                   │
│  raw_taxi_trips  ──►  stg_trips                         │
│  raw_zone_lookup ──►  stg_zones                         │
│                            │                            │
│                    core dataset                         │
│                    ────────────                         │
│                    fact_trips                           │
│                    dim_zone                             │
│                    dim_date                             │
│                            │                            │
│                    mart dataset                         │
│                    ────────────                         │
│                    mart_hourly_demand                   │
│                    mart_zone_kpis                       │
│                    mart_revenue_efficiency              │
│                    mart_route_analysis                  │
└─────────────────────────────────────────────────────────┘
      │                            │
      │ dbt Core                   │ Tableau Public
      │ (transforms all layers)    │ (reads mart only)
      ▼                            ▼
  GitHub Actions CI/CD        5 Dashboard Pages
  (runs dbt on every push)
```

---

## Layer-by-Layer Breakdown

### Layer 1 — Data Source

**What:** NYC Taxi & Limousine Commission (TLC) publishes monthly trip record files for every licensed taxi and rideshare vehicle in New York City.

**Files we use:**
- Yellow Taxi Trip Records — January 2025 through December 2025
- Format: Apache Parquet (a compressed, columnar binary format — more efficient than CSV)
- Taxi Zone Lookup Table — a small CSV file mapping zone IDs to borough and neighborhood names

**Scale:** Each monthly file contains roughly 3–4 million rows. All 12 months combined: approximately 38–40 million rows and 10–12 GB of raw data.

**URL:** https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page

---

### Layer 2 — Python Ingestion

**Role:** Data Engineering (DE)

**What it does:**
The ingestion script is responsible for one thing only: getting raw data from the source into BigQuery reliably. It does not clean or transform — that is intentional. Raw data lands exactly as it was published by the TLC.

**Tools:**
- `requests` — downloads files from the TLC URL
- `pyarrow` / `pandas` — reads and validates Parquet files
- `google-cloud-bigquery` — Python client for loading data into BigQuery

**Key design decisions:**
- Schema validation happens before loading — if the TLC changes a column name, the script fails loudly rather than silently loading bad data
- Loading is idempotent — running the script twice does not create duplicate rows (uses `WRITE_TRUNCATE` per partition)
- Each monthly file is loaded as a separate batch to enable restart from failure without reloading everything

**Output:** Raw tables in BigQuery `raw` dataset, partitioned on `pickup_date`.

---

### Layer 3 — BigQuery (Four Datasets)

**Role:** Data Engineering (DE) + Analytics Engineering (AE)

BigQuery is Google's fully managed, serverless data warehouse. It charges per byte scanned — this is why partition filtering is mandatory on every query.

#### Dataset: `raw`

Contains data exactly as received from the TLC. No transformations, no business logic.

| Table | Description |
|---|---|
| `raw_taxi_trips` | All 12 months of yellow taxi trip records |
| `raw_zone_lookup` | 265 taxi zone IDs mapped to borough and neighborhood |

**Rules for this dataset:**
- Never query without a `WHERE pickup_date BETWEEN ...` clause
- Never join heavy tables in this dataset
- Never use `SELECT *` in production queries

#### Dataset: `staging`

Cleaned and standardized versions of raw tables. Column names are renamed to be consistent and readable. Data types are cast correctly. Obvious bad rows are filtered out (e.g., trips with zero passengers, negative fares, or pickup times before 2025).

| Table | Description |
|---|---|
| `stg_trips` | Cleaned trip records with standardized column names |
| `stg_zones` | Zone lookup with borough and neighborhood cleaned |

#### Dataset: `core`

Dimensional model (star schema). This is where the data becomes analysis-ready.

| Table | Grain | Description |
|---|---|---|
| `fact_trips` | One row per trip | All trip metrics and foreign keys to dimensions |
| `dim_zone` | One row per zone | Zone ID, borough, neighborhood, zone type |
| `dim_date` | One row per date | Date, day of week, week number, month, is_weekend flag |

**Why a star schema?** It is the standard model for analytics workloads. It separates facts (things that happened — trips) from dimensions (context — when, where). Tableau and SQL queries run faster and are easier to write against a star schema.

#### Dataset: `mart`

Pre-aggregated summary tables built for Tableau. Tableau connects only to these tables. This means every dashboard query reads thousands of rows, not tens of millions.

| Table | Description |
|---|---|
| `mart_hourly_demand` | Trip counts and revenue aggregated by hour, date, and zone |
| `mart_zone_kpis` | Zone-level KPIs: utilization, efficiency, revenue per trip |
| `mart_revenue_efficiency` | Revenue KPIs by time period, route, and zone |
| `mart_route_analysis` | Pickup-to-dropoff zone pairs with efficiency metrics |

**Cost control rule:** Tableau never queries `raw`, `staging`, or `core` directly. All dashboard traffic hits `mart` tables only.

---

### Layer 4 — dbt Core

**Role:** Analytics Engineering (AE)

**What dbt does:**
dbt (data build tool) lets you write SQL `SELECT` statements and it handles the rest — creating tables or views in BigQuery, running them in the correct order, testing the output, and generating documentation.

Without dbt, you would write raw SQL scripts and run them manually in a specific order. dbt automates the order, adds testing, and makes every transformation version-controlled and reproducible.

**Project structure:**
```
dbt_project/
├── models/
│   ├── staging/
│   │   ├── stg_trips.sql
│   │   └── stg_zones.sql
│   ├── core/
│   │   ├── fact_trips.sql
│   │   ├── dim_zone.sql
│   │   └── dim_date.sql
│   └── mart/
│       ├── mart_hourly_demand.sql
│       ├── mart_zone_kpis.sql
│       ├── mart_revenue_efficiency.sql
│       └── mart_route_analysis.sql
├── tests/
│   └── (custom data quality tests)
├── dbt_project.yml
└── profiles.yml
```

**dbt tests used in this project:**
- `not_null` — required fields cannot be empty
- `unique` — primary keys must be unique
- `accepted_values` — payment type must be one of the known values
- `relationships` — foreign keys in fact_trips must exist in dim_zone
- Custom tests for business rules (e.g., fare amount must be positive)

---

### Layer 5 — GitHub Actions CI/CD

**Role:** Data Engineering (DE)

**What it does:**
Every time code is pushed to the main branch on GitHub, GitHub Actions automatically runs:
1. `dbt run` — rebuilds all staging, core, and mart models
2. `dbt test` — runs all data quality tests
3. If any test fails, the run is marked as failed and no broken model reaches Tableau

**Why this matters for a portfolio:**
CI/CD for data pipelines is a skill most junior analysts do not have. It shows you understand that data quality is an ongoing operational concern, not a one-time cleanup task.

**File:** `.github/workflows/dbt_ci.yml`

---

### Layer 6 — Tableau Public

**Role:** Data Analyst (DA)

Tableau connects to BigQuery using the native connector. It reads only from the `mart` dataset.

**Five dashboard pages:**

| Page | Business Question Answered |
|---|---|
| Executive Overview | How is the overall operation performing? |
| Demand Analysis | When and where is demand highest? |
| Revenue Efficiency | Which zones and hours generate the most revenue? |
| Zone & Route Analysis | Which routes and zones are most efficient? |
| Recommendations | What operational actions do the data support? |

**Cost control rule:** Every Tableau extract or live query must filter on a date range. No full-table scans against mart tables.

---

## Cost Control Policy

BigQuery charges $5 per terabyte scanned. With ~12 GB of raw data, a full scan of the raw table costs roughly $0.06 — cheap in isolation, expensive if done hundreds of times during development.

Rules enforced throughout this project:

1. All BigQuery tables are partitioned on `pickup_date`
2. Every query in every layer filters on the partition column
3. Tableau connects to mart tables only (pre-aggregated, small)
4. During development, queries are tested on a single month (January 2025) before running on the full year
5. `SELECT *` is never used in production models
6. BigQuery sandbox (free tier) is used where possible

---

## Technology Stack

| Tool | Version | Purpose |
|---|---|---|
| Python | 3.11+ | Ingestion script |
| pandas | 2.x | Data validation during ingestion |
| pyarrow | latest | Reading Parquet files |
| google-cloud-bigquery | latest | Python BigQuery client |
| BigQuery | — | Cloud data warehouse |
| dbt Core | 1.7+ | SQL transformation and testing |
| dbt-bigquery adapter | 1.7+ | dbt connector for BigQuery |
| GitHub Actions | — | CI/CD automation |
| Tableau Public | latest | Dashboards and visualization |

---

## Data Flow Summary

```
TLC Website
  → Python script downloads Parquet
    → raw.raw_taxi_trips (partitioned, untransformed)
      → dbt staging: stg_trips (cleaned, typed)
        → dbt core: fact_trips + dim_zone + dim_date (star schema)
          → dbt mart: mart_hourly_demand + mart_zone_kpis + ... (aggregated)
            → Tableau dashboards (reads mart only)
```

Every arrow is tested. Every model is documented. Every push is validated by CI/CD.

---

## What Each Role Builds

| Layer | Role | Skills Demonstrated |
|---|---|---|
| Ingestion script | Data Engineer | Python, API/file handling, BigQuery loading, schema validation |
| Raw + staging | Data Engineer + AE | SQL cleaning, type casting, partitioning |
| Core (star schema) | Analytics Engineer | Dimensional modeling, dbt, SQL |
| Mart tables | Analytics Engineer | KPI design, aggregation, performance optimization |
| CI/CD | Data Engineer | GitHub Actions, automated testing |
| Dashboards | Data Analyst | Tableau, business communication, IE-flavored KPIs |
| Written deliverables | All | Analytical thinking, communication, documentation |

---

*Last updated: Phase 0 — Architecture design*
*Next update: After Phase 1 (ingestion) is complete*
