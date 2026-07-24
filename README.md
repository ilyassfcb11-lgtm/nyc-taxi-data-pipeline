# NYC Taxi Operations Intelligence Platform

End-to-end data pipeline analyzing 44.2M NYC Yellow Taxi trips (2025) to surface operational insights on demand, revenue, and fleet efficiency across all 265 NYC taxi zones.

**[→ Live Dashboard](https://ilyassfcb11-lgtm.github.io/nyc-taxi-data-pipeline/dashboard.html)**

---

## Overview

I built this project to demonstrate a complete data engineering and analytics workflow — from raw data ingestion to a production-ready, tested pipeline with an interactive dashboard.

The data comes from NYC's Taxi & Limousine Commission (TLC). I downloaded 12GB of raw Parquet files, loaded them into BigQuery, applied 8 data cleaning rules to remove bad records, then modeled the clean data across three dbt layers (staging → core → mart). The mart tables power a 5-page interactive dashboard covering demand patterns, revenue efficiency, zone KPIs, and route analysis.

**Pipeline:** Python → BigQuery (raw) → dbt (staging / core / mart) → Dashboard

**Scale:** 44.2M trips · $1.27B revenue · 265 zones · 12 months · 8 cleaning rules · 55 automated tests

---

## Tech Stack

| Layer | Tools |
|-------|-------|
| Ingestion | Python, pandas, google-cloud-bigquery |
| Storage | Google BigQuery (date-partitioned tables) |
| Transformation | dbt Core, dbt-bigquery adapter |
| Data Quality | 55 tests — generic schema tests + custom business rule SQL tests |
| CI/CD | GitHub Actions |
| Visualization | HTML, JavaScript, Chart.js |

---

## Project Structure

```
nyc_taxi_dbt/
├── models/
│   ├── staging/    # stg_trips, stg_zones — raw cleaning
│   ├── core/       # fact_trips, dim_zone, dim_date — data model
│   └── mart/       # pre-aggregated KPI tables for the dashboard
└── tests/          # custom business rule tests
sql/                # original SQL before dbt migration
ingestion/          # Python data ingestion scripts
dashboard.html      # interactive 5-page dashboard
```

---

## Key Findings

- Evening peak (5–7PM) accounts for 22% of all daily trips — strongest fleet deployment signal
- Airport routes (JFK, LaGuardia) average $58 per trip vs $28 citywide — 2× the network average
- Top 10 zones by fleet priority score generate 31% of total revenue across 265 zones
- NYC CBD congestion pricing (launched Jan 2025) collected $24.2M in fees across the year

---

## Author

Ilyass — M.S. Computer Science, CUNY Brooklyn College (GPA: 3.97)  
Background in manufacturing & operations data analytics
