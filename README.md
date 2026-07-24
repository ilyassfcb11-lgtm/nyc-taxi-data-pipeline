# NYC Taxi Operations Intelligence Platform

Analysis of 44.2M NYC Yellow Taxi trips (2025) — built as a full end-to-end data pipeline from raw ingestion to a live interactive dashboard.

**[→ Live Dashboard](https://ilyassfcb11-lgtm.github.io/nyc-taxi-data-pipeline/dashboard.html)**

---

## What I Built

I ingested 12GB of raw trip data from NYC TLC, cleaned and modeled it in BigQuery using dbt, and built an interactive dashboard to surface operational insights on demand patterns, revenue efficiency, and fleet allocation.

**Pipeline:** Python ingestion → BigQuery → dbt (staging / core / mart) → Dashboard

**Scale:** 44.2M trips · $1.27B revenue · 265 NYC zones · 12 months

---

## Tech Stack

| | |
|--|--|
| Ingestion | Python, pandas, google-cloud-bigquery |
| Storage | Google BigQuery (partitioned tables) |
| Transformation | dbt Core + dbt-bigquery |
| Testing | 55 automated data quality tests |
| CI/CD | GitHub Actions |
| Visualization | HTML, Chart.js |

---

## Key Findings

- Evening peak (5–7PM) drives 22% of all daily demand
- Airport trips average $58 per trip vs $28 citywide
- Top 10 zones generate 31% of total revenue
- CBD congestion pricing collected $24.2M in its first year (Jan 2025)

---

## Author

Ilyass — M.S. Computer Science, CUNY Brooklyn College (GPA: 3.97)
