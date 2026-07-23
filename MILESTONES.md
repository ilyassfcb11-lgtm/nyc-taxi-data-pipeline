# Project Milestones & Deliverables
## NYC Taxi Operations Intelligence Platform

**Last updated:** Phase 2 complete  
**Overall progress:** 4 of 7 phases done

---

## ✅ PHASE 0 — Setup
**Status: Complete**

| Deliverable | Description |
|---|---|
| GitHub repository | Public repo with full folder structure |
| Python virtual environment | All dependencies installed via requirements.txt |
| GCP project | `nyc-taxi-intelligence` with BigQuery API enabled |
| 4 BigQuery datasets | `raw`, `staging`, `core`, `mart` created |
| Application Default Credentials | ADC configured via gcloud CLI |
| `README.md` | Public-facing project overview |
| `PROJECT_BRIEF.md` | Plain English project description |
| `ARCHITECTURE.md` | Technical architecture document |
| `ROADMAP.md` | Phase-by-phase timeline |
| `SETUP_GUIDE.md` | Step-by-step reproduction guide |
| `.gitignore` | Credentials and large files excluded from Git |
| `requirements.txt` | All Python dependencies pinned |

---

## ✅ PHASE 1 — Ingestion
**Status: Complete**

| Deliverable | Description |
|---|---|
| `ingestion/config.py` | All configuration constants in one place |
| `ingestion/ingest.py` | Full ingestion pipeline with 7 functions |
| `raw.raw_taxi_trips` | **48,722,602 rows** loaded, partitioned by pickup_date |
| `raw.raw_zone_lookup` | 265 NYC taxi zones loaded |

**Key technical decisions made:**
- Partitioned by `pickup_date` for BigQuery cost control
- `WRITE_TRUNCATE` on first month, `WRITE_APPEND` on subsequent months
- Schema validation catches TLC schema changes before loading
- Found and handled real 2025 schema change: `airport_fee` → `Airport_fee` + new `cbd_congestion_fee` column

---

## ✅ PHASE 1.5 — Exploratory Data Analysis
**Status: Complete**

| Deliverable | Description |
|---|---|
| `analysis/EDA.ipynb` | Jupyter notebook with 9 analysis cells and 3 charts |

**Key findings from EDA:**

| Finding | Detail |
|---|---|
| Null passenger_count | 11,611,894 rows (23.8%) — both Vendor 1 and 2 affected |
| Undocumented vendors | VendorID 6 and 7 not in TLC data dictionary |
| Max fare | $863,372.12 — clear meter malfunction |
| Zero/negative fares | 2,870,234 rows (5.9%) |
| Zero/negative distances | 1,402,958 rows (2.9%) |
| Max distance | 397,994 miles — GPS error |
| Peak hour | 6 PM (3,015,308 trips) |
| Highest fare hour | 5 AM ($26.02 avg) — airport runs |
| Busiest day | Saturday (6,927,597 trips) |
| Highest fare day | Sunday ($20.85 avg) |
| Quietest weekday | Monday — remote work effect |
| Peak month | May (4,155,275 trips) |
| Summer dip | August is the yearly LOW — residents leave NYC |
| Highest fare month | December ($22.44 avg) |
| Top pickup zone | Upper East Side South (2,035,569 trips, $13.36 avg) |
| Highest revenue zone | JFK Airport ($63.56 avg fare, 5× Manhattan zones) |

---

## ✅ PHASE 2 — Cleaning + KPIs
**Status: Complete**

| Deliverable | Description |
|---|---|
| `sql/staging/stg_trips.sql` | 48.7M rows cleaned, 6 filtering rules |
| `sql/staging/stg_zones.sql` | Zone lookup cleaned and renamed |
| `sql/core/fact_trips.sql` | Star schema fact table with revenue KPIs |
| `sql/core/dim_zone.sql` | Zone dimension with airport flag |
| `sql/core/dim_date.sql` | Full 2025 calendar with time attributes |
| `sql/mart/mart_hourly_demand.sql` | Demand KPIs by hour/day/zone |
| `sql/mart/mart_zone_kpis.sql` | Zone efficiency scores + peak hour |
| `sql/mart/mart_revenue_efficiency.sql` | Revenue KPIs by hour/borough |
| `sql/mart/mart_route_analysis.sql` | Pickup→dropoff route metrics |
| `transform.py` | Runs all 9 SQL files in correct order (25 seconds end to end) |

**Cleaning rules applied in stg_trips.sql:**

| Rule | Rows removed |
|---|---|
| Year ≠ 2025 | Unknown (wrong-year records) |
| fare_amount ≤ 0 | ~2,870,234 |
| trip_distance ≤ 0 | ~1,402,958 |
| dropoff ≤ pickup | Zero-duration trips |
| fare_amount > $500 | Meter malfunctions |
| trip_distance > 100 miles | GPS errors |

**BigQuery tables created:**

| Layer | Table | Rows (approx) |
|---|---|---|
| raw | raw_taxi_trips | 48,722,602 |
| raw | raw_zone_lookup | 265 |
| staging | stg_trips | ~44M (after cleaning) |
| staging | stg_zones | 265 |
| core | fact_trips | ~44M |
| core | dim_zone | 265 |
| core | dim_date | 365 |
| mart | mart_hourly_demand | ~50K |
| mart | mart_zone_kpis | ~265 |
| mart | mart_revenue_efficiency | ~1K |
| mart | mart_route_analysis | ~10K |

**KPIs built so far:**
- Revenue per trip, per mile, per hour
- Zone efficiency score
- Demand % of total
- Peak hour per zone
- Weekend vs weekday flag
- CBD congestion fee impact
- Route volume + revenue

**KPIs pending (Phase 3 — Tableau calculated fields):**
- Fleet allocation priority score
- Peak load factor
- Zone utilization proxy

---

## ⏳ PHASE 3 — Tableau Dashboards
**Status: Starting next session**

| Deliverable | Status |
|---|---|
| Tableau Public installed | ✅ Done |
| Connect Tableau to BigQuery | ⏳ Next |
| Page 1: Executive Overview | ⏳ Pending |
| Page 2: Demand Analysis | ⏳ Pending |
| Page 3: Revenue Efficiency | ⏳ Pending |
| Page 4: Zone & Route Analysis | ⏳ Pending |
| Page 5: Recommendations | ⏳ Pending |
| Published Tableau Public URL | ⏳ Pending |
| `KPIS.md` | ⏳ Pending (written after Tableau) |
| `ANALYSIS.md` | ⏳ Pending (written after Tableau) |

---

## ⏳ PHASE 4 — dbt
**Status: Pending**

| Deliverable | Status |
|---|---|
| dbt project initialized | ⏳ Pending |
| All SQL migrated to dbt models | ⏳ Pending |
| schema.yml with column descriptions | ⏳ Pending |
| dbt docs generated | ⏳ Pending |

---

## ⏳ PHASE 5 — Testing
**Status: Pending**

| Deliverable | Status |
|---|---|
| dbt built-in tests (not_null, unique, etc.) | ⏳ Pending |
| Custom SQL business rule tests | ⏳ Pending |
| `DATA_QUALITY.md` | ⏳ Pending |

---

## ⏳ PHASE 6 — CI/CD + Polish
**Status: Pending**

| Deliverable | Status |
|---|---|
| GitHub Actions workflow | ⏳ Pending |
| CI badge in README | ⏳ Pending |
| `INTERVIEW_PREP.md` | ⏳ Pending |
| Final GitHub push | ⏳ Pending |

---

## Checkpoint Summary

**CHECKPOINT 1 (start applying for jobs):** End of Phase 3
- Working ingestion pipeline ✅
- Clean data in BigQuery ✅
- KPI tables built ✅
- Tableau dashboards ⏳ Phase 3
- KPIS.md ⏳ Phase 3

**CHECKPOINT 2 (full project complete):** End of Phase 6
- All of the above plus dbt, testing, and CI/CD
