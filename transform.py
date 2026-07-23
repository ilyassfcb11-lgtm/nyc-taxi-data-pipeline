# =============================================================
# transform.py — SQL Transformation Orchestrator
# =============================================================
# What this script does:
#   Runs all SQL transformation files in the correct order.
#   Each file creates or replaces a BigQuery table.
#
# Why order matters:
#   staging depends on raw
#   core depends on staging
#   mart depends on core
#   If you run mart before core, it fails — the source doesn't exist yet.
#
# How to run:
#   cd "/Users/ilyass/Documents/PROJECT 1/DATA ENGINER/ ANALYST"
#   source venv/bin/activate
#   python transform.py
#
# How to run one layer only:
#   python transform.py --layer staging
#   python transform.py --layer core
#   python transform.py --layer mart
# =============================================================

import os
import argparse
import time
from google.cloud import bigquery

PROJECT_ID = "nyc-taxi-intelligence"

# SQL files in execution order
# Each tuple is (description, file_path)
PIPELINE = {
    "staging": [
        ("Staging: clean zone lookup",  "sql/staging/stg_zones.sql"),
        ("Staging: clean trip records", "sql/staging/stg_trips.sql"),
    ],
    "core": [
        ("Core: zone dimension",        "sql/core/dim_zone.sql"),
        ("Core: date dimension",        "sql/core/dim_date.sql"),
        ("Core: fact trips",            "sql/core/fact_trips.sql"),
    ],
    "mart": [
        ("Mart: hourly demand KPIs",    "sql/mart/mart_hourly_demand.sql"),
        ("Mart: zone KPIs",             "sql/mart/mart_zone_kpis.sql"),
        ("Mart: revenue efficiency",    "sql/mart/mart_revenue_efficiency.sql"),
        ("Mart: route analysis",        "sql/mart/mart_route_analysis.sql"),
    ],
}


def run_sql_file(client: bigquery.Client, description: str, file_path: str) -> None:
    """
    Reads a SQL file and executes it as a BigQuery job.
    Prints timing and row count on success.
    Raises an exception on failure (stops the pipeline).
    """
    print(f"\n  Running: {description}")
    print(f"  File:    {file_path}")

    # Read the SQL file
    with open(file_path, "r") as f:
        sql = f.read()

    start_time = time.time()

    # Execute the SQL
    job = client.query(sql)
    job.result()  # Wait for completion

    elapsed = round(time.time() - start_time, 1)
    print(f"  Done in {elapsed}s ✓")


def main():
    parser = argparse.ArgumentParser(
        description="Run SQL transformation pipeline"
    )
    parser.add_argument(
        "--layer",
        choices=["staging", "core", "mart", "all"],
        default="all",
        help="Which layer to run. Default: all layers in order.",
    )
    args = parser.parse_args()

    client = bigquery.Client(project=PROJECT_ID)

    # Determine which layers to run
    if args.layer == "all":
        layers = ["staging", "core", "mart"]
    else:
        layers = [args.layer]

    print(f"\nNYC Taxi Transformation Pipeline")
    print(f"Project: {PROJECT_ID}")
    print(f"Layers:  {layers}")

    total_start = time.time()
    failed = []

    for layer in layers:
        print(f"\n{'='*60}")
        print(f"Layer: {layer.upper()}")
        print(f"{'='*60}")

        for description, file_path in PIPELINE[layer]:
            try:
                run_sql_file(client, description, file_path)
            except Exception as e:
                print(f"\n  ERROR: {e}")
                failed.append(file_path)
                # Stop on first failure — downstream tables depend on upstream
                print(f"\nPipeline stopped. Fix the error above and re-run.")
                return

    total_elapsed = round(time.time() - total_start, 1)
    print(f"\n{'='*60}")
    print(f"Pipeline complete in {total_elapsed}s")
    print(f"Tables created:")
    for layer in layers:
        for _, file_path in PIPELINE[layer]:
            table = os.path.basename(file_path).replace(".sql", "")
            print(f"  ✓ {table}")
    print(f"{'='*60}\n")


if __name__ == "__main__":
    main()
