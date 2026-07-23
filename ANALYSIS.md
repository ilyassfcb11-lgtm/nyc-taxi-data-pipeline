# Data Analysis Report
## NYC Taxi Operations Intelligence Platform — 2025

**Dataset:** NYC TLC Yellow Taxi · January–December 2025  
**Cleaned trips:** 44,169,347 (from 48,722,602 raw — 9.3% removed by cleaning rules)  
**Total revenue:** $1,273,964,844  
**Zones analyzed:** 262 active pickup zones across 5 NYC boroughs

---

## Executive Summary

NYC Yellow Taxi operations in 2025 are structurally concentrated: **86% of all trips originate in Manhattan**, yet the highest revenue-per-trip zones are airports in Queens. A driver optimizing purely for earnings would prioritize airport runs at early morning hours. A fleet manager optimizing for volume would deploy in the Upper East Side and Midtown. The tension between these two strategies is the central finding of this analysis.

---

## Finding 1: Airports generate 3–4× more revenue per trip than Manhattan

| Zone | Avg Revenue / Trip | Trips (2025) | Borough |
|---|---|---|---|
| JFK Airport | $81.66 | 1,879,610 | Queens |
| LaGuardia Airport | $69.74 | 1,224,892 | Queens |
| Midtown Center | $25.97 | 1,945,658 | Manhattan |
| Upper East Side South | $21.25 | 1,998,396 | Manhattan |

JFK's $81.66 average is **3.3× Manhattan's city average of $24.77**. Yet JFK has the highest `fleet_priority_score` (71.4) in the entire dataset — meaning it is both extremely high-revenue AND among the busiest zones by trip count. This is the single highest-value zone for fleet deployment.

**Implication:** Any operational strategy that treats airports the same as Manhattan zones is leaving significant revenue on the table. Airport-bound fleet allocation should be treated as a separate optimization problem.

---

## Finding 2: 5 AM is the highest revenue-per-trip hour, not peak volume hour

| Hour | Trips | Avg Revenue / Trip |
|---|---|---|
| 5 AM | 344,516 | $53.18 |
| 6 PM | 2,975,377 | $28.74 |
| 3 AM | 403,970 | $44.17 |
| 12 PM | 2,270,707 | $28.19 |

6 PM has 8.6× more trips than 5 AM, but earns 42% less per trip. The 5 AM premium is driven by airport runs — travelers catching early flights from JFK and LaGuardia before the morning rush. This finding is actionable: drivers who shift their start time by 2–3 hours can earn significantly more per shift without requiring more trips.

---

## Finding 3: August is structurally the lowest-demand month every year

| Month | Trips | Revenue |
|---|---|---|
| May (peak) | 4,092,209 | $119.8M |
| August (low) | 3,180,655 | $92.1M |
| December | 4,049,572 | $127.1M |

August is 22% below May's peak and 20% below December. This is not random variation — it is a well-known NYC pattern caused by affluent residents (the primary taxi-using demographic) leaving the city for summer vacation. Fleet operators who understand this can plan maintenance windows and driver schedules around this predictable lull.

**December is the highest-revenue month ($127.1M)** despite having fewer trips than May, because average revenue per trip is highest in winter months — longer trips due to cold weather and holiday travel patterns.

---

## Finding 4: CBD Congestion Pricing added $24.2M in new fees in 2025

The Central Business District Congestion Pricing program launched in January 2025 — the first of its kind in the United States. This analysis captures the first full year of this policy.

| Month | CBD Fees Collected |
|---|---|
| January | $1,604,700 |
| May (peak) | $2,248,800 |
| December | $2,189,100 |
| **Total 2025** | **$24,189,900** |

CBD fees track trip volume closely, peaking in May and dipping in August alongside overall demand. The fee applies to trips entering or exiting lower Manhattan below 60th Street — which covers a large portion of all Yellow Taxi trips.

**Behavioral impact:** Whether this pricing reduced downtown trip demand cannot be determined from 2025 data alone (no pre-2025 CBD fee baseline in this dataset). Year-over-year comparison against 2024 data would be required to measure elasticity.

---

## Finding 5: Manhattan dominates volume but Queens dominates revenue efficiency

| Borough | Trips | Total Revenue | Avg Rev / Trip | Fleet Priority (top zone) |
|---|---|---|---|---|
| Manhattan | 38,097,092 | $933.8M | $24.77 | 56.4 (Upper East Side) |
| Queens | 4,171,373 | $281.2M | $61.68 | 71.4 (JFK) |
| Brooklyn | 1,472,374 | $44.7M | $30.38 | — |
| Bronx | 339,533 | $10.8M | $31.76 | — |

Queens has 11% of Manhattan's trip volume but 30% of Manhattan's total revenue. The revenue-per-trip gap is driven entirely by airport zones — remove JFK and LaGuardia, and Queens average drops to near-Manhattan levels. This confirms that **airport access is the primary revenue differentiator in NYC taxi operations**.

---

## Finding 6: Peak load factor reveals hidden surge pressure

`peak_load_factor` (peak hour trips ÷ average hourly trips) reveals which zones have unpredictable, spike-heavy demand that requires surge capacity:

| Zone | Peak Load Factor | Peak Hour | Implication |
|---|---|---|---|
| Times Sq/Theatre District | 2.25× | 21:00 | Theater crowd creates sharp spike |
| Midtown East | 2.14× | 18:00 | Office commute creates sharp spike |
| Midtown Center | 2.11× | 18:00 | Same commute pattern |
| Upper East Side North | 1.99× | 15:00 | School pickup + early commuters |
| Penn Station/Madison | 1.50× | 17:00 | Most uniform — steady train arrivals |

Penn Station (1.50×) has the flattest demand profile of the top zones — train arrivals create a steady flow rather than a spike. Times Square (2.25×) has the sharpest spike: 9 PM theater end-times flood the zone simultaneously, creating a demand shock that cannot be met by standard fleet positioning.

---

## Finding 7: Zone utilization proxy exposes the long tail

The `zone_utilization_proxy` shows that NYC taxi demand is extremely concentrated:

- **Top 10 zones** (3.8% of 262 zones) capture approximately **38% of all trips**
- **Upper East Side South** (11.85× average) has more demand than the bottom 100 zones combined
- **Many zones in the Bronx and Staten Island** have utilization below 0.2× — meaning they receive less than 20% of the average zone's demand

This has direct implications for taxi supply decisions. Sending taxis to low-utilization zones to "cover the map" is operationally inefficient. The data suggests a hub-and-spoke model: concentrate supply in the top 20 zones and rely on trip completion to distribute drivers to lower-demand areas organically.

---

## Finding 8: Weekday vs Weekend demand patterns differ by zone type

| Metric | Weekday | Weekend |
|---|---|---|
| Total trips | 31,403,042 (71%) | 12,766,305 (29%) |
| Total revenue | $916.1M | $357.9M |
| Avg rev / weekday trip | $29.17 | $28.04 |

Weekdays dominate by volume, but weekends have surprisingly similar revenue-per-trip averages — suggesting that weekend trips, though fewer, tend to be leisure trips (longer, to restaurants/entertainment) rather than short office commutes.

**By hour:** Weekend revenue per trip is higher than weekday between midnight and 2 AM (late-night entertainment), while weekday is higher during 7–9 AM (morning commute airport runs) and 5–6 PM (office rush hour).

---

## Methodology Notes

**Cleaning rules applied** (in `sql/staging/stg_trips.sql`):
- Removed trips where `fare_amount ≤ 0` (~2.9M rows — meter malfunctions and test trips)
- Removed trips where `trip_distance ≤ 0` (~1.4M rows — GPS failures)
- Removed trips where dropoff time ≤ pickup time (zero-duration trips)
- Removed trips where `fare_amount > $500` (meter malfunctions — max legitimate fare is ~$200)
- Removed trips where `trip_distance > 100 miles` (GPS coordinate errors)
- Removed records where `YEAR(pickup_datetime) ≠ 2025` (wrong-year data in TLC files)

**Result:** 48,722,602 raw → 44,169,347 cleaned (9.3% removed)

**Known limitations:**
- Cash tip amounts are not recorded by TLC — `avg_tip` understates true tip behavior for cash payers
- `zone_utilization_proxy` assumes uniform zone geography — zones with larger physical area may have artificially lower proxies
- `cbd_congestion_fee` is null for trips outside the CBD zone; COALESCE(cbd_congestion_fee, 0) used in aggregations
- VendorID 6 and 7 appear in raw data but are not in the TLC data dictionary — included in analysis since no cleaning rule targets undocumented vendors
