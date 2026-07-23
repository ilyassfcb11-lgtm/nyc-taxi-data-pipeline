# =============================================================
# export_to_csv.py — Export mart tables to CSV for Tableau
# =============================================================
# Exports all 4 mart tables as full CSV files so Tableau
# can connect to them with complete data (not 500-row previews).
#
# How to run:
#   cd "/Users/ilyass/Documents/PROJECT 1/DATA ENGINER/ ANALYST"
#   source venv/bin/activate
#   python export_to_csv.py
# =============================================================

import os
from google.cloud import bigquery

PROJECT_ID = "nyc-taxi-intelligence"
OUTPUT_DIR = "tableau_data"

TABLES = [
    "mart_hourly_demand",
    "mart_zone_kpis",
    "mart_revenue_efficiency",
    "mart_route_analysis",
]

def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    client = bigquery.Client(project=PROJECT_ID)

    for table in TABLES:
        print(f"Exporting {table}...", end=" ", flush=True)
        query = f"SELECT * FROM `{PROJECT_ID}.mart.{table}`"
        df = client.query(query).to_dataframe()
        out_path = os.path.join(OUTPUT_DIR, f"{table}.csv")
        df.to_csv(out_path, index=False)
        print(f"{len(df):,} rows → {out_path}")

    print("\nDone! All 4 files in tableau_data/")

if __name__ == "__main__":
    main()
