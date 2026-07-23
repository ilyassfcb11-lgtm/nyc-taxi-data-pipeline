# =============================================================
# config.py — Configuration for NYC Taxi Ingestion Pipeline
# =============================================================
# What is this file?
#   Instead of hardcoding values like URLs, table names, and
#   project IDs directly inside ingest.py, we put them all
#   here. This way, if something changes (e.g. a new year,
#   a new dataset name), we change it in ONE place, not
#   scattered across multiple files.
#
#   This is called "separation of concerns" — each file has
#   one job. config.py stores settings. ingest.py runs logic.
# =============================================================


# --- Google Cloud ---
PROJECT_ID = "nyc-taxi-intelligence"
# Your GCP project ID. Every BigQuery table name is prefixed
# with this: nyc-taxi-intelligence.raw.raw_taxi_trips

DATASET_RAW = "raw"
# The BigQuery dataset where raw, untransformed data lands.

TABLE_TRIPS = "raw_taxi_trips"
# The table that stores all yellow taxi trip records.

TABLE_ZONES = "raw_zone_lookup"
# The table that stores the taxi zone reference data (265 zones).


# --- Data Source ---
YEAR = 2025
# The year of data we are ingesting. Change this to re-run
# for a different year — everything else adapts automatically.

MONTHS = list(range(1, 13))
# [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
# All 12 months. During development, we test with MONTHS = [1]
# (January only), then switch to the full list.

TLC_BASE_URL = "https://d37ci6vzurychx.cloudfront.net/trip-data"
# The base URL for all TLC Parquet files. Each file is at:
# {TLC_BASE_URL}/yellow_tripdata_{YEAR}-{MM}.parquet
# Example: .../yellow_tripdata_2025-01.parquet

ZONE_LOOKUP_URL = "https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv"
# The zone lookup table is a small CSV (265 rows) that maps
# zone IDs (integers) to borough and neighborhood names.
# It does not change monthly — we load it once.


# --- Schema Validation ---
# These are the columns we expect to find in every monthly
# Parquet file. If the TLC ever changes their schema (they
# have done this before), our script will fail loudly
# instead of silently loading wrong data.
EXPECTED_COLUMNS = [
    "VendorID",
    "tpep_pickup_datetime",
    "tpep_dropoff_datetime",
    "passenger_count",
    "trip_distance",
    "RatecodeID",
    "store_and_fwd_flag",
    "PULocationID",
    "DOLocationID",
    "payment_type",
    "fare_amount",
    "extra",
    "mta_tax",
    "tip_amount",
    "tolls_amount",
    "improvement_surcharge",
    "total_amount",
    "congestion_surcharge",
    "Airport_fee",
    "cbd_congestion_fee",
]
# What each column means:
# VendorID          — which taxi vendor (1 = Creative Mobile, 2 = VeriFone)
# tpep_pickup_datetime  — when passenger was picked up
# tpep_dropoff_datetime — when passenger was dropped off
# passenger_count   — number of passengers (self-reported by driver)
# trip_distance     — trip distance in miles
# RatecodeID        — rate type (1=Standard, 2=JFK, 3=Newark, etc.)
# store_and_fwd_flag — Y/N whether trip was stored in vehicle memory
# PULocationID      — pickup zone ID (links to zone lookup table)
# DOLocationID      — dropoff zone ID (links to zone lookup table)
# payment_type      — 1=Credit, 2=Cash, 3=No charge, 4=Dispute
# fare_amount       — base fare calculated by meter
# extra             — surcharges (rush hour, overnight)
# mta_tax           — $0.50 MTA tax
# tip_amount        — tip (only populated for credit card payments)
# tolls_amount      — tolls paid during trip
# improvement_surcharge — $0.30 surcharge
# total_amount      — total charged to passenger
# congestion_surcharge  — NYC congestion pricing surcharge
# Airport_fee       — JFK/LaGuardia pickup fee (capital A in 2025 TLC schema)
# cbd_congestion_fee — NYC Central Business District congestion pricing fee
#                      (new column in 2025 — NYC congestion pricing launched Jan 5, 2025)


# --- Local Storage ---
DOWNLOAD_DIR = "data/raw"
# Temporary local folder where Parquet files are saved before
# being loaded to BigQuery. Files here are excluded from Git
# via .gitignore — they are too large for version control.
