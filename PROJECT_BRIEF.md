# Project Brief — NYC Taxi Operations Intelligence Platform

**Author:** Ilyass  
**Status:** In Progress  
**Started:** Phase 0 — Setup  
**Goal:** A professional, end-to-end data analytics portfolio project built for Data Analyst, Analytics Engineer, and Data Engineer job applications.

---

## What Is This Project? (Plain English)

Imagine you are a data analyst hired by a company that manages thousands of taxi drivers in New York City. Your job is to help the company answer questions like:

- When is demand highest? Which neighborhoods need more taxis at 8am?
- Which routes make the most money per hour?
- Are drivers spending too much time waiting for passengers in low-demand areas?
- How should the company allocate its fleet on a Monday morning versus a Saturday night?

You have access to every single taxi trip that happened in New York City in 2025 — about 38 million trips. But raw trip records are useless on their own. A spreadsheet with 38 million rows crashes Excel. A manager cannot read it. A business decision cannot be made from it.

This project builds the full system that takes those 38 million raw trip records and turns them into clean, trusted, interactive dashboards that any manager can use to make operational decisions.

That system — from raw data to business-ready dashboard — is what data engineers and analytics engineers are paid to build. That is what this project demonstrates.

---

## Why NYC Taxi Data?

Three reasons:

**1. It is real.** This is not made-up data. The NYC Taxi & Limousine Commission (TLC) publishes the actual trip records from every licensed taxi in New York City. Every row in this dataset is a real taxi trip that happened in 2025.

**2. It is large enough to be meaningful.** 38 million rows is big enough that you cannot just open it in Excel and start clicking around. It requires real engineering tools — a cloud data warehouse, SQL transformations, and a proper data pipeline. This is exactly what employers want to see.

**3. It matches the job.** Operations, logistics, and transportation analytics are common in industry. The KPIs and analysis in this project translate directly to fleet management, delivery operations, retail demand planning, and supply chain analytics. Your Industrial Engineering background makes this especially strong.

---

## What Is the Final Product?

When this project is finished, you will have:

1. **A Python script** that automatically downloads the taxi data from the internet and loads it into a cloud database — reliably, with error handling, ready to be scheduled.

2. **A cloud data warehouse** (Google BigQuery) with four organized layers of data — raw, cleaned, structured, and summarized — each layer building on the last.

3. **A dbt project** — a professional set of SQL models that transform the raw data into analysis-ready tables, with automated tests that catch bad data before it reaches any dashboard.

4. **Five Tableau dashboards** showing demand patterns, revenue efficiency, zone performance, route analysis, and business recommendations — all built on top of clean, tested data.

5. **A GitHub repository** with CI/CD automation — meaning every time you push new code, the entire pipeline runs automatically and checks that nothing is broken.

6. **Seven written documents** — a project brief, architecture document, KPI definitions, a published analysis, a data quality guide, a roadmap, and interview preparation notes.

All of this together tells a hiring manager: this person can build a data product from scratch, test it, automate it, visualize it, and explain every decision they made.

---

## The Dataset

**Source:** NYC Taxi & Limousine Commission  
**URL:** https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page

**What we use:**
- Yellow Taxi Trip Records for all 12 months of 2025
- Taxi Zone Lookup Table (a small reference file that maps zone numbers to borough and neighborhood names)

**What each trip record contains:**
Every row in the dataset is one taxi trip. For each trip, we know:
- When the passenger was picked up (date and time)
- When they were dropped off (date and time)
- Which zone they were picked up in (one of 265 zones across NYC)
- Which zone they were dropped off in
- How many passengers were in the cab
- The distance of the trip in miles
- How long the trip took
- How much the passenger paid (fare, tip, tolls, taxes)
- How they paid (credit card or cash)

**Scale:**
- About 3–4 million trips per month
- About 38–40 million trips for the full year
- Roughly 10–12 GB of raw data files
- Stored as Parquet files (a compressed, efficient file format — more on this below)

---

## The Technology Stack — Every Tool Explained Simply

This project uses 7 main tools. Here is what each one is, what it does, and why we use it — in plain English.

---

### 1. Python

**What it is:** A programming language. One of the most widely used languages in data work.

**What we use it for:** Writing the ingestion script — the program that automatically downloads the taxi data files from the internet and loads them into BigQuery.

**Why Python and not something else?** Python is the standard language for data engineering. It has libraries (pre-written code packages) for everything: downloading files, reading data, connecting to databases, handling errors. It is also what most data jobs expect.

**What you will write:** A script called `ingest.py` that runs once per month, downloads the new Parquet file from the TLC website, checks that the columns look correct, and loads the data into BigQuery.

---

### 2. Apache Parquet

**What it is:** A file format for storing data. Think of it like a very efficient, compressed spreadsheet — but one designed for computers to read, not humans.

**Why it matters:** The TLC publishes its data as Parquet files. A CSV file with 4 million rows might be 800 MB. The same data as Parquet might be 150 MB. Parquet is also much faster to read because it stores data by column, not by row — which means if you only need the "fare amount" column, you only read that column, not the entire file.

**What you need to know for interviews:** Parquet is columnar storage. It is efficient because analytics queries almost always read a few columns across many rows, not all columns of one row. This is the opposite of how transactional databases (like a cash register system) work.

---

### 3. Google BigQuery

**What it is:** A cloud data warehouse made by Google. A data warehouse is like a very large, very fast database designed specifically for analytics — for running complex queries over millions or billions of rows.

**Why not just use a regular database like PostgreSQL?** A regular database (like PostgreSQL) is designed for transactional workloads — looking up one customer's record, inserting one new order, updating one row. BigQuery is designed for analytical workloads — scanning 38 million rows and computing averages, sums, and counts across all of them.

**How BigQuery charges money:** BigQuery charges based on how much data your queries scan. If you run `SELECT * FROM raw_taxi_trips` with no filters, it scans all 10 GB and charges you for it. This is why we partition our tables (group them by date) and always filter by date in every query.

**What we store in BigQuery:** All four layers of data — raw, staging, core, and mart. Each layer is a separate "dataset" (like a folder) inside the same BigQuery project.

**Free tier:** BigQuery gives you 10 GB of storage and 1 TB of queries per month for free. With careful partitioning and query filtering, this project can be built almost entirely within the free tier.

---

### 4. SQL

**What it is:** Structured Query Language. The language used to query and transform data in databases.

**What you already know:** You have used SQL for 3 years in your analyst roles. In this project, SQL does the heavy lifting for every data transformation — cleaning, joining, aggregating, and computing KPIs.

**What is different here:** In a typical analyst job, you write SQL to answer one-off questions. In this project, you write SQL that runs automatically, in a specific order, and is tested for correctness. This is what analytics engineers do.

---

### 5. dbt (Data Build Tool)

**What it is:** A tool that lets you write SQL transformations as organized, version-controlled, testable files — and then runs them in the correct order automatically.

**The problem dbt solves:** Imagine you have 10 SQL scripts that must run in a specific order. Script 3 depends on Script 1 and 2. If you run them in the wrong order, everything breaks. If you change Script 2, you have to remember to re-run Script 3 and everything after it. Tracking this manually is error-prone and does not scale.

dbt solves this by understanding the dependencies between your SQL models. You tell it "this model reads from that model" and dbt figures out the correct order to run everything. It also runs tests automatically and generates documentation showing how every table is connected.

**What you write in dbt:** SQL `SELECT` statements. That is it. dbt wraps them in `CREATE TABLE AS` or `CREATE VIEW AS` automatically. You focus on the logic; dbt handles the execution.

**Why dbt is important for your job search:** dbt is now standard in analytics engineering roles and increasingly expected in data analyst roles. Showing dbt on your resume, with a working project, makes you significantly more competitive than candidates who only list SQL.

---

### 6. GitHub Actions

**What it is:** An automation tool built into GitHub. You write a small configuration file that tells GitHub: "whenever I push new code, run these commands automatically."

**What we use it for:** Every time you push an update to the project, GitHub automatically runs the entire dbt pipeline and all data quality tests. If anything fails, you get an immediate notification. If everything passes, the pipeline is considered healthy.

**Why this matters:** In a real company, data pipelines run on a schedule (every day, every hour). Someone needs to know when something breaks. CI/CD (Continuous Integration / Continuous Deployment) is the industry-standard way to catch failures automatically. Having CI/CD in your portfolio shows you think about data as a product that needs to be maintained, not just a one-time analysis.

**What you will write:** One YAML file (`.github/workflows/dbt_ci.yml`) that is about 30 lines long. We will build it together in Phase 6.

---

### 7. Tableau

**What it is:** A data visualization tool. One of the most widely used business intelligence (BI) tools in the world.

**What we use it for:** Building the five dashboard pages that turn the mart tables into interactive, visual insights for business users.

**Tableau Public vs Tableau Desktop:** Tableau Public is the free version. Dashboards are published publicly online. For a portfolio project, this is exactly what you want — a public URL you can share with any hiring manager.

**How it connects to BigQuery:** Tableau has a native connector for BigQuery. You give it your project credentials, select the mart dataset, and it pulls the data. All dashboards connect to the pre-aggregated mart tables — never to the raw data.

**Your learning plan for Tableau:** We will cover Tableau step by step in Phase 3. The tool is learnable. You already understand data and KPIs. Tableau is just the interface for communicating what you already know.

---

## The Data Pipeline — How Everything Connects

Here is the full story of a single taxi trip record, from the TLC website to a Tableau dashboard:

**Step 1 — The TLC publishes a Parquet file**  
Once per month, the TLC uploads a new file to their website. Each file contains every yellow taxi trip from that month.

**Step 2 — Python downloads and loads it**  
Your ingestion script (`ingest.py`) downloads the file, checks that all the expected columns are present with the right data types, and loads it into BigQuery as-is — no changes, no cleaning. This lands in the `raw` dataset.

**Step 3 — dbt cleans it (staging)**  
The `stg_trips` model reads from `raw_taxi_trips` and applies cleaning rules: rename messy column names to readable ones, cast strings to proper types, remove obviously bad rows (trips with negative fares, trips in years other than 2025, zero-distance trips). This lands in the `staging` dataset.

**Step 4 — dbt structures it (core)**  
The `fact_trips` model reads from `stg_trips` and joins it with zone and date dimension tables. This creates the star schema — a structured, efficient format for analytics queries. This lands in the `core` dataset.

**Step 5 — dbt aggregates it (mart)**  
The mart models read from `fact_trips` and pre-compute the KPIs: hourly demand by zone, average revenue per trip per hour, zone utilization scores, route efficiency metrics. Instead of 38 million rows, each mart table has a few thousand rows. This is what Tableau reads.

**Step 6 — Tableau visualizes it**  
Tableau connects to the mart tables and renders interactive dashboards. A manager can filter by date, borough, or hour and immediately see how the fleet is performing.

**Step 7 — GitHub Actions monitors it**  
Every time you push a code change (a new dbt model, a new test, a fixed bug), GitHub Actions automatically runs `dbt run` and `dbt test`. If a test fails, the pipeline stops and you are notified. Nothing broken reaches the dashboards.

---

## The Four Layers of BigQuery — Explained Simply

Think of the four BigQuery datasets like four rooms in a building, each with a different purpose:

**Room 1 — Raw (the loading dock)**  
This is where data arrives from the outside world. Nobody is allowed to transform it here. It looks exactly as it came from the TLC. If something goes wrong later, you can always come back to this room and re-process from scratch.

**Room 2 — Staging (the workshop)**  
This is where the data gets cleaned and standardized. Bad rows get removed. Column names get fixed. Data types get corrected. The data coming out of this room is trustworthy and consistent.

**Room 3 — Core (the library)**  
This is where the data gets organized into a structure designed for analysis — the star schema. Facts (trips) are separated from context (zones, dates). Every analyst query becomes simpler and faster when the data is organized this way.

**Room 4 — Mart (the display case)**  
This is what the outside world sees. Pre-computed, aggregated, fast. Tableau reads from here. Business users look at data from here. Nothing heavy runs in this room — just fast lookups of pre-computed answers.

---

## The KPIs — What We Measure and Why

KPIs (Key Performance Indicators) are the specific numbers a business tracks to understand how it is performing. Generic KPIs (like "total revenue") are easy. Strong KPIs tell you something operational and actionable.

This project uses four categories of KPIs, inspired by Industrial Engineering principles:

### Demand KPIs
*What they answer: When and where do people need taxis?*

- Trips per hour per zone
- Peak hour demand index (how much busier is the peak hour versus the daily average?)
- Weekend vs. weekday demand ratio
- Borough-level demand by time of day

### Productivity KPIs
*What they answer: How much value does each hour or trip generate?*

- Revenue per hour
- Revenue per trip
- Revenue per mile
- Revenue per minute (useful for comparing short high-fare trips vs. long low-fare trips)

### Efficiency KPIs
*What they answer: How effectively is the system operating?*

- Route efficiency score (actual distance vs. straight-line distance — a proxy for congestion or detour)
- Average trip duration per mile (longer = more congested or less efficient)
- Congestion proxy index
- Zone efficiency score (revenue generated relative to time spent in zone)

### IE / Operations KPIs
*What they answer: Where should fleet resources be deployed?*

- Fleet allocation priority score (combines demand + efficiency to score each zone)
- Zone utilization proxy (how busy is a zone relative to its capacity?)
- Peak load factor (ratio of peak-hour trips to average-hour trips — borrowed from manufacturing OEE concepts)
- Operational cost proxy (fare minus tip as a rough measure of net operational revenue)

For each KPI, the `KPIS.md` document will contain the exact formula, definition, business meaning, and limitations.

---

## The Phase-by-Phase Plan

### Phase 0 — Setup (1–2 days)
*What we do:* Create the GitHub repository, set up the Python environment, create the Google Cloud project and BigQuery datasets, and make sure every tool is installed and working.

*Why this matters:* A project that cannot be reproduced from scratch is not a real portfolio project. Setup done right means anyone (including a hiring manager) could clone your repo and run it.

*What you will have at the end:* An empty but fully configured project ready for real work.

*Role:* Data Engineering

---

### Phase 1 — Ingestion (3–4 days)
*What we do:* Write the Python script that downloads all 12 monthly Parquet files from the TLC website and loads them into the BigQuery `raw` dataset. Write the script to load the zone lookup CSV as well.

*Why this matters:* Ingestion is the foundation of any data pipeline. If data does not get in reliably, nothing downstream works. This phase teaches you how real data engineers think about reliability, schema validation, and error handling.

*What you will have at the end:* Two tables in BigQuery — `raw.raw_taxi_trips` (~38M rows, partitioned by date) and `raw.raw_zone_lookup` (265 rows). The ingestion script runs cleanly with no errors.

*Role:* Data Engineering

---

### Phase 2 — Cleaning and KPIs (3–4 days)
*What we do:* Write the SQL transformations for the staging and core layers. Design and implement all KPIs as SQL queries that produce the mart tables.

*Why this matters:* This is where raw data becomes trusted data. Cleaning is not glamorous, but it is what separates real data work from a student project. The KPI design phase is where your Industrial Engineering background adds the most value.

*What you will have at the end:* Staging tables, core tables (fact + dims), and mart tables with all KPIs computed. The SQL is clean, commented, and explains the business logic.

*Role:* Analytics Engineering + Data Analysis

---

### Phase 3 — Visualization (3–4 days)
*What we do:* Connect Tableau to BigQuery, build five dashboard pages, and write the business insights that accompany them.

*Why this matters:* The dashboards are what non-technical hiring managers see first. A well-built dashboard shows you can communicate data insights, not just compute them.

*What you will have at the end:* A published Tableau Public dashboard with five pages, a live URL you can share, and a written summary of the key business findings.

*Role:* Data Analysis

---

### CHECKPOINT 1 — First Version Ready (~4–5 weeks)
At this point, you have a working end-to-end project. Raw data flows through Python ingestion into BigQuery, gets transformed via SQL into KPI tables, and is visualized in Tableau. The written deliverables are drafted. **This is when you start applying for jobs.**

---

### Phase 4 — dbt (5–7 days)
*What we do:* Rebuild all the SQL transformations as proper dbt models. This means moving the staging, core, and mart SQL into the dbt project structure, adding dbt documentation and descriptions, and verifying that dbt runs the models in the correct order.

*Why this matters:* dbt is what turns you from a data analyst who writes SQL into an analytics engineer who builds data products. It adds version control, testing, documentation, and reproducibility to your transformations. It is one of the most in-demand skills in modern data roles.

*What you will have at the end:* A fully working dbt project with all models organized by layer, dbt lineage graph generated (a visual diagram showing how all tables depend on each other), and dbt docs published.

*Role:* Analytics Engineering

---

### Phase 5 — Testing and Data Quality (3–4 days)
*What we do:* Add dbt tests to every model. Built-in tests (not null, unique, accepted values, relationships) plus custom SQL tests for business rules specific to taxi data.

*Why this matters:* Bad data silently corrupts analysis. A dashboard showing the wrong number is worse than no dashboard at all. Testing is how professionals guarantee data quality. Most junior candidates skip this — it is a differentiator.

*What you will have at the end:* Every model has at least two tests. Running `dbt test` produces zero failures. The `DATA_QUALITY.md` document explains what is tested and why.

*Role:* Analytics Engineering + Data Engineering

---

### Phase 6 — CI/CD and Final Polish (2–4 days)
*What we do:* Write the GitHub Actions workflow that automatically runs dbt on every code push. Clean up the repository (clear README, organized folders, no dead code). Write or complete the final written deliverables.

*Why this matters:* CI/CD shows you understand that a data pipeline is not a one-time project — it is a system that runs continuously and needs monitoring. A polished repo shows professional attention to detail.

*What you will have at the end:* A GitHub Actions badge on your README showing the pipeline is passing. A clean, well-organized repository that you are proud to share with any employer.

*Role:* Data Engineering

---

### CHECKPOINT 2 — Full Portfolio Project Complete (~8–10 weeks)
At this point, the project demonstrates skills across all three target roles: Data Analyst (KPIs, Tableau, business insights), Analytics Engineer (dbt, star schema, data modeling), and Data Engineer (Python ingestion, BigQuery, CI/CD).

---

## What This Project Demonstrates to Employers

### For Data Analyst roles
- You can take raw operational data and extract meaningful business insights
- You know how to design KPIs that actually drive decisions (not just vanity metrics)
- You can build professional dashboards that non-technical managers can use
- Your Industrial Engineering background gives the analysis an operational depth most DA candidates lack

### For Analytics Engineer roles
- You know how to build a proper dbt project with staging, core, and mart layers
- You understand dimensional modeling and the star schema
- Your transformations are tested, documented, and reproducible
- You think about data as a product, not just a query result

### For Data Engineer roles
- You can write a reliable Python ingestion pipeline
- You know how to work with a cloud data warehouse at scale
- You understand partitioning, cost optimization, and data loading strategies
- You have CI/CD experience for data pipelines

---

## The Seven Written Deliverables

These documents are produced alongside the code, not saved for the end. Each one is a real portfolio artifact.

| File | Purpose |
|---|---|
| `PROJECT_BRIEF.md` | This file. The complete project overview. |
| `ROADMAP.md` | Phase-by-phase timeline with milestones. |
| `ARCHITECTURE.md` | Technical architecture, layer by layer. |
| `KPIS.md` | Every KPI with formula, definition, and business meaning. |
| `ANALYSIS.md` | 1500–2000 word published analysis of key findings. |
| `DATA_QUALITY.md` | What is tested, how, and why. |
| `INTERVIEW_PREP.md` | Phase-by-phase interview questions with practice answers. |

---

## A Note on Business Framing

This project is not a school assignment. It is an operations intelligence system for urban mobility.

That framing matters because it changes how you present the work. Instead of saying "I analyzed NYC taxi data," you say "I built a pipeline that transforms 38 million trip records into operational KPIs for fleet allocation and demand planning."

Both sentences describe the same project. The second one gets interviews.

Throughout this project, every design decision will be framed in business terms. Every KPI will have a business explanation, not just a formula. Every dashboard will answer a specific operational question. The ANALYSIS.md will read like a report you would send to a VP of Operations, not like a homework submission.

---

*This document will be updated at the end of every phase to reflect what has been built and what has been learned.*

*Last updated: Phase 0 — Project setup*
