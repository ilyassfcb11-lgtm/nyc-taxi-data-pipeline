# KPI Dictionary
## NYC Taxi Operations Intelligence Platform

**Last updated:** Phase 3 complete  
**Data source:** NYC TLC Yellow Taxi 2025 · 44.2M cleaned trips  
**Pipeline:** BigQuery `core.fact_trips` → `mart.mart_zone_kpis` + 3 other mart tables

---

## How KPIs Are Organized

| Layer | Table | Grain | Purpose |
|---|---|---|---|
| `mart` | `mart_hourly_demand` | Hour × Day × Zone | When and where demand occurs |
| `mart` | `mart_zone_kpis` | One row per zone | Zone-level efficiency and priority |
| `mart` | `mart_revenue_efficiency` | Hour × Borough × Month | Revenue optimization by time and location |
| `mart` | `mart_route_analysis` | One row per pickup→dropoff pair | Route profitability |

---

## Volume KPIs

### `total_trips`
**Definition:** Count of cleaned taxi trips in the group.  
**Cleaning applied:** Trips with fare ≤ $0, distance ≤ 0, duration ≤ 0, fare > $500, or distance > 100 miles were removed before this count.  
**Why it matters:** Raw demand signal. Used to size fleet allocation and identify peak periods.  
**Source column:** `COUNT(*)` in all mart tables.

### `demand_pct_of_total`
**Definition:** `total_trips / SUM(total_trips) OVER()` — share of all 2025 trips belonging to this group.  
**Interpretation:** A zone with `demand_pct = 4.5` captures 4.5% of all NYC taxi demand.  
**Source table:** `mart_hourly_demand`

---

## Revenue KPIs

### `avg_revenue_per_trip`
**Definition:** `AVG(total_amount)` — average total fare including base fare, surcharges, tolls, and tips.  
**Note:** `total_amount` in TLC data includes tip only for credit card trips. Cash tips are not recorded.  
**City average:** $28.84 · JFK average: $81.66 · LaGuardia: $69.74

### `avg_revenue_per_mile`
**Definition:** `total_amount / trip_distance_miles` for each trip, then averaged.  
**Why it matters:** Measures how efficiently distance is converted to revenue. Short, high-fare trips (airports, CBD) score higher than long low-fare trips.  
**City average:** ~$22/mile

### `avg_revenue_per_hour`
**Definition:** `total_amount / (trip_duration_minutes / 60)` for each trip, then averaged.  
**Why it matters:** The core operational efficiency metric. A driver earning $120/hour is twice as efficient as one earning $60/hour regardless of distance.  
**Interpretation:** 5 AM has the highest avg_revenue_per_hour ($53.18) due to airport runs.

### `total_revenue`
**Definition:** `SUM(total_amount)` — total gross revenue for the group.  
**2025 total:** $1.27B across all 44.2M trips.

### `avg_fare`
**Definition:** `AVG(fare_amount)` — metered fare only, excluding surcharges and tips.  
**Differs from avg_revenue_per_trip:** avg_revenue_per_trip includes all charges; avg_fare is the base meter reading only.

### `avg_tip`
**Definition:** `AVG(tip_amount)`.  
**Caveat:** Only populated for credit card trips. Cash tips appear as $0 in TLC data even when paid.  
**Airport average:** significantly higher than city average due to large fares.

---

## Efficiency KPIs

### `zone_efficiency_score`
**Definition:** `AVG(revenue_per_mile) × AVG(revenue_per_hour) / 100`  
**Why this formula:** Combines both dimensions of taxi efficiency — distance and time. A zone that scores well on both earns consistently more per unit of resource consumed.  
**Interpretation scale:**
| Score | Zone type |
|---|---|
| > 100 | Airport zone — extremely high |
| 30–100 | Premium Manhattan zones |
| 10–30 | Standard Manhattan zones |
| < 10 | Outer boroughs |

**Top scorer:** JFK Airport (148.95) — 4.8× higher than Upper East Side South (31.02)

---

## Advanced KPIs (Operations Intelligence)

### `fleet_priority_score` (0–100)
**Definition:** Composite score indicating where to deploy additional taxis.  
**Formula:**
```
fleet_priority_score = (
    (total_trips / MAX(total_trips) OVER ALL ZONES)      × 0.50  -- volume weight
  + (avg_revenue_per_trip / MAX(avg_revenue_per_trip))   × 0.30  -- revenue weight
  + (zone_efficiency_score / MAX(zone_efficiency_score)) × 0.20  -- efficiency weight
) × 100
```
**Weights rationale:**
- 50% volume: a zone with high demand but average revenue still needs more taxis
- 30% revenue: higher-revenue zones justify more resource allocation
- 20% efficiency: efficient zones are better long-term investments

**Interpretation:**
| Score | Meaning |
|---|---|
| 70–100 | Top priority — maximize fleet presence |
| 50–70 | High priority |
| 30–50 | Medium — serve adequately |
| < 30 | Low priority — minimal fleet needed |

**Top scorer:** JFK Airport (71.4) — only zone above 70, reflecting unique combination of high volume AND high revenue.

---

### `peak_load_factor`
**Definition:** How "spikey" demand is in a zone — ratio of peak hour trips to average hourly trips.  
**Formula:**
```
peak_load_factor = peak_hour_trips / (total_trips / 24.0)
```
Where `peak_hour_trips` = trips in the single busiest hour for that zone.

**Interpretation:**
| Factor | Meaning |
|---|---|
| 1.0 | Perfectly flat demand — same number of trips every hour |
| 2.0 | Peak hour is 2× busier than average |
| 4.0+ | Extreme spikiness — surge capacity needed at peak hour |

**Operational use:** High peak load factor = zone needs surge pricing or extra fleet at a specific hour. Low factor = predictable, easy to plan.  
**Range in 2025 data:** 1.30 (very flat) to 9.60 (extreme spike)  
**Times Square at 21:00 has the highest load factor** — theater crowds create sharp demand spikes.

---

### `zone_utilization_proxy`
**Definition:** How busy a zone is relative to the average zone across all 265 NYC taxi zones.  
**Formula:**
```
zone_utilization_proxy = total_trips / AVG(total_trips ACROSS ALL ZONES)
```
**Interpretation:**
| Proxy | Meaning |
|---|---|
| 1.0 | Average zone — exactly as busy as the typical zone |
| > 1.0 | Above average — zone receives more demand than typical |
| < 1.0 | Below average — potentially under-served or low-demand area |

**Examples:**
- Upper East Side South: 11.85× average → extremely high utilization
- JFK Airport: 11.15× average → despite being "outer borough", as busy as top Manhattan zones
- A quiet Bronx zone: ~0.1× average → far below average demand

**Operational use:** Zones with high utilization AND low fleet_priority_score may be under-monetized. Zones with low utilization may be candidates for service reduction.

---

## Demand KPIs

### `avg_revenue_per_hour` (time-dimension version in mart_revenue_efficiency)
Same formula as above but aggregated by `pickup_hour × borough × month` rather than by zone.  
Used for heatmaps and hourly revenue patterns.

### `avg_cbd_fee`
**Definition:** `AVG(cbd_congestion_fee)` — average Central Business District congestion fee per trip.  
**Context:** NYC's CBD Congestion Pricing program launched January 2025. Applies to trips entering/exiting lower Manhattan below 60th Street.  
**2025 total collected:** $24.2M across all affected trips.  
**Why it matters:** New cost passed to passengers in 2025. Affects demand behavior in downtown Manhattan zones.

---

## Route KPIs (mart_route_analysis)

### Route grain
One row per unique (pickup_zone, dropoff_zone) pair with at least 100 trips in 2025.  
Total routes captured: 14,389 unique pickup→dropoff combinations.

### `is_airport_route`
TRUE if either the pickup or dropoff zone is an airport (JFK or LaGuardia).  
Airport routes average $80–126/trip vs $13–25/trip for Manhattan-to-Manhattan routes.

### `is_same_borough`
TRUE if pickup and dropoff are in the same borough.  
Intra-Manhattan trips dominate by volume but are short and lower-revenue.

---

## KPI Summary Table

| KPI | Table | Type | Best zone | Worst zone |
|---|---|---|---|---|
| avg_revenue_per_trip | all | Revenue | JFK ($81.66) | Short Manhattan trips |
| zone_efficiency_score | mart_zone_kpis | Efficiency | JFK (148.95) | Outer borough (< 5) |
| fleet_priority_score | mart_zone_kpis | Advanced | JFK (71.4) | Quiet zones (< 5) |
| peak_load_factor | mart_zone_kpis | Advanced | Times Sq (2.25) | Penn Station (1.50) |
| zone_utilization_proxy | mart_zone_kpis | Advanced | Upper East Side (11.85×) | Quiet zones (0.1×) |
| avg_cbd_fee | mart_revenue_efficiency | Regulatory | Manhattan CBD | Outer boroughs ($0) |
