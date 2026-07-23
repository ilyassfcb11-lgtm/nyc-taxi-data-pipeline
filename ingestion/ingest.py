# =============================================================
# ingest.py — NYC Taxi Ingestion Pipeline
# =============================================================
# What this script does:
#   1. Downloads yellow taxi Parquet files from the TLC website
#   2. Validates that the schema (columns) looks correct
#   3. Adds a pickup_date column for BigQuery partitioning
#   4. Loads the data into BigQuery raw.raw_taxi_trips
#   5. Loads the zone lookup CSV into BigQuery raw.raw_zone_lookup
#
# How to run (one month — for testing):
#   python ingestion/ingest.py --months 1
#
# How to run (full year):
#   python ingestion/ingest.py
#
# Prerequisites:
#   - venv activated: source venv/bin/activate
#   - gcloud authenticated: gcloud auth application-default login
#   - BigQuery datasets created (raw, staging, core, mart)
# =============================================================

import os
import argparse
import requests
import pandas as pd
from google.cloud import bigquery
from tqdm import tqdm

# Import our configuration constants
from config import (
    PROJECT_ID,
    DATASET_RAW,
    TABLE_TRIPS,
    TABLE_ZONES,
    YEAR,
    MONTHS,
    TLC_BASE_URL,
    ZONE_LOOKUP_URL,
    EXPECTED_COLUMNS,
    DOWNLOAD_DIR,
)


# =============================================================
# FUNCTION 1: download_file
# =============================================================
def download_file(url: str, destination: str) -> str:
    """
    Downloads a file from a URL and saves it locally.

    Why stream=True?
        Large files (500MB+) cannot be downloaded all at once
        into memory. stream=True downloads in small chunks,
        so we only hold one chunk in memory at a time.

    Why tqdm?
        Shows a progress bar so you know the download is
        working and how far along it is.

    Returns the local file path where the file was saved.
    """
    # Make sure the download folder exists
    os.makedirs(os.path.dirname(destination), exist_ok=True)

    # Skip download if file already exists (saves time on re-runs)
    if os.path.exists(destination):
        print(f"  Already downloaded: {destination}")
        return destination

    print(f"  Downloading: {url}")

    # Send HTTP GET request, stream the response
    response = requests.get(url, stream=True, timeout=120)

    # Raise an error if the request failed (e.g. 404 Not Found)
    response.raise_for_status()

    # Get total file size from the response header (for progress bar)
    total_size = int(response.headers.get("content-length", 0))

    # Write the file in 8KB chunks, showing progress bar
    chunk_size = 8192
    with open(destination, "wb") as f, tqdm(
        total=total_size,
        unit="B",
        unit_scale=True,
        desc=os.path.basename(destination),
    ) as progress_bar:
        for chunk in response.iter_content(chunk_size=chunk_size):
            f.write(chunk)
            progress_bar.update(len(chunk))

    print(f"  Saved to: {destination}")
    return destination


# =============================================================
# FUNCTION 2: validate_schema
# =============================================================
def validate_schema(df: pd.DataFrame, month: int) -> None:
    """
    Checks that all expected columns are present in the DataFrame.

    Why do this?
        The TLC has changed their schema before (adding columns,
        renaming columns). If we don't check, we might load a
        file missing key columns and not notice until much later
        when our SQL queries fail.

        "Fail loudly" is better than "fail silently."

    Raises a ValueError if any expected column is missing.
    """
    missing = [col for col in EXPECTED_COLUMNS if col not in df.columns]

    if missing:
        raise ValueError(
            f"Schema validation failed for month {month:02d}.\n"
            f"Missing columns: {missing}\n"
            f"Found columns: {list(df.columns)}\n"
            f"The TLC may have changed their schema."
        )

    print(f"  Schema OK — {len(df.columns)} columns, {len(df):,} rows")


# =============================================================
# FUNCTION 3: add_partition_column
# =============================================================
def add_partition_column(df: pd.DataFrame) -> pd.DataFrame:
    """
    Adds a pickup_date DATE column derived from tpep_pickup_datetime.

    Why is this needed?
        BigQuery charges per byte scanned. If we partition the
        table by pickup_date, a query that filters on date
        (e.g. WHERE pickup_date = '2025-01-15') only scans
        that day's data — not the whole table.

        Without partitioning, every query scans all 38M rows.
        With partitioning, a daily query scans ~100K rows.

    This single column is our most important cost control measure.
    """
    # Convert pickup datetime to date only (drop the time part)
    df["pickup_date"] = pd.to_datetime(df["tpep_pickup_datetime"]).dt.date

    return df


# =============================================================
# FUNCTION 4: load_to_bigquery
# =============================================================
def load_to_bigquery(df: pd.DataFrame, table_id: str, first_month: bool = False) -> None:
    """
    Loads a pandas DataFrame into a BigQuery table.

    table_id format: "project.dataset.table"
    Example: "nyc-taxi-intelligence.raw.raw_taxi_trips"

    Why two write modes?
        - First month (first_month=True): WRITE_TRUNCATE — wipes the table
          clean before loading. This resets the table so re-running the full
          year never creates duplicates.
        - Subsequent months (first_month=False): WRITE_APPEND — adds rows
          to whatever is already there. This is how we accumulate 12 months
          into one table without overwriting previous months.

    Why TimePartitioning?
        Tells BigQuery to organize data by the pickup_date column.
        See add_partition_column() above for why this matters.
    """
    # Create BigQuery client
    # Uses Application Default Credentials automatically
    client = bigquery.Client(project=PROJECT_ID)

    # First month truncates (resets); subsequent months append
    write_mode = (
        bigquery.WriteDisposition.WRITE_TRUNCATE
        if first_month
        else bigquery.WriteDisposition.WRITE_APPEND
    )

    # Configure the load job
    job_config = bigquery.LoadJobConfig(
        write_disposition=write_mode,
        # Partition the table by pickup_date
        time_partitioning=bigquery.TimePartitioning(
            type_=bigquery.TimePartitioningType.DAY,
            field="pickup_date",
        ),
        # Let BigQuery detect column types from the DataFrame
        autodetect=True,
    )

    print(f"  Loading {len(df):,} rows to {table_id} ...")

    # Start the load job
    job = client.load_table_from_dataframe(df, table_id, job_config=job_config)

    # Wait for the job to complete
    job.result()

    # Verify the row count in BigQuery
    table = client.get_table(table_id)
    print(f"  Loaded successfully. BigQuery table now has {table.num_rows:,} rows.")


# =============================================================
# FUNCTION 5: ingest_month
# =============================================================
def ingest_month(year: int, month: int, first_month: bool = False) -> None:
    """
    Orchestrates the full pipeline for one month:
      1. Build the URL and local file path
      2. Download the Parquet file
      3. Read it into a DataFrame
      4. Validate the schema
      5. Add the partition column
      6. Load to BigQuery

    first_month=True triggers WRITE_TRUNCATE (wipe + reload).
    first_month=False triggers WRITE_APPEND (add to existing data).
    This function is called once per month in the main loop.
    """
    month_str = f"{month:02d}"  # "1" becomes "01", "12" stays "12"
    filename = f"yellow_tripdata_{year}-{month_str}.parquet"
    url = f"{TLC_BASE_URL}/{filename}"
    local_path = os.path.join(DOWNLOAD_DIR, filename)
    table_id = f"{PROJECT_ID}.{DATASET_RAW}.{TABLE_TRIPS}"

    print(f"\n{'='*60}")
    print(f"Processing: {year}-{month_str}")
    print(f"{'='*60}")

    # Step 1: Download
    download_file(url, local_path)

    # Step 2: Read into DataFrame
    print(f"  Reading Parquet file ...")
    df = pd.read_parquet(local_path)
    print(f"  Read {len(df):,} rows")

    # Step 3: Validate schema
    validate_schema(df, month)

    # Step 4: Add partition column
    df = add_partition_column(df)

    # Step 5: Load to BigQuery
    load_to_bigquery(df, table_id, first_month=first_month)

    print(f"  Done: {year}-{month_str}")


# =============================================================
# FUNCTION 6: ingest_zones
# =============================================================
def ingest_zones() -> None:
    """
    Downloads and loads the Taxi Zone Lookup CSV to BigQuery.

    This is a small reference table (265 rows) that maps zone IDs
    (integers like 132) to human-readable names like "JFK Airport"
    and boroughs like "Queens".

    We load it once. It rarely changes.
    """
    table_id = f"{PROJECT_ID}.{DATASET_RAW}.{TABLE_ZONES}"

    print(f"\n{'='*60}")
    print(f"Processing: Zone Lookup Table")
    print(f"{'='*60}")
    print(f"  Downloading zone lookup CSV ...")

    # Download via requests (handles SSL certs correctly on macOS)
    # then read from the local file — same pattern as ingest_month()
    local_path = os.path.join(DOWNLOAD_DIR, "taxi_zone_lookup.csv")
    download_file(ZONE_LOOKUP_URL, local_path)
    df = pd.read_csv(local_path)

    print(f"  Read {len(df):,} zones")
    print(f"  Columns: {list(df.columns)}")

    # Load to BigQuery (no partitioning needed — it's a tiny table)
    client = bigquery.Client(project=PROJECT_ID)
    job_config = bigquery.LoadJobConfig(
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
        autodetect=True,
    )

    job = client.load_table_from_dataframe(df, table_id, job_config=job_config)
    job.result()

    table = client.get_table(table_id)
    print(f"  Loaded {table.num_rows} zones to {table_id}")


# =============================================================
# MAIN — Entry point
# =============================================================
def main():
    """
    Entry point for the ingestion script.

    Parses command-line arguments so you can run:
      python ingest.py --months 1        (January only)
      python ingest.py --months 1 2 3    (Q1 only)
      python ingest.py                   (all 12 months)
    """
    # Set up argument parser
    parser = argparse.ArgumentParser(
        description="NYC Taxi Ingestion Pipeline — loads TLC data into BigQuery"
    )
    parser.add_argument(
        "--months",
        nargs="+",       # accepts one or more values
        type=int,
        default=MONTHS,  # defaults to all 12 months from config.py
        help="Months to ingest (e.g. --months 1 2 3). Default: all 12.",
    )
    parser.add_argument(
        "--skip-zones",
        action="store_true",
        help="Skip loading the zone lookup table.",
    )
    args = parser.parse_args()

    print(f"\nNYC Taxi Ingestion Pipeline")
    print(f"Year: {YEAR}")
    print(f"Months: {args.months}")
    print(f"Project: {PROJECT_ID}")
    print(f"Destination: {PROJECT_ID}.{DATASET_RAW}.{TABLE_TRIPS}")

    # Load zone lookup table (once, unless skipped)
    if not args.skip_zones:
        ingest_zones()

    # Load each month
    # first_month=True on the first iteration → WRITE_TRUNCATE (reset table)
    # first_month=False on all others → WRITE_APPEND (accumulate)
    failed_months = []
    for i, month in enumerate(args.months):
        try:
            ingest_month(YEAR, month, first_month=(i == 0))
        except Exception as e:
            print(f"\n  ERROR on month {month}: {e}")
            failed_months.append(month)
            # Continue to next month instead of stopping everything
            continue

    # Final summary
    print(f"\n{'='*60}")
    print(f"Ingestion complete.")
    print(f"Months processed: {[m for m in args.months if m not in failed_months]}")
    if failed_months:
        print(f"Months failed: {failed_months}")
    print(f"{'='*60}\n")


# This block only runs when you execute the script directly.
# It does NOT run when another file imports from this module.
if __name__ == "__main__":
    main()
