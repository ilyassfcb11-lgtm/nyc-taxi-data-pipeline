# Phase 0 Setup Guide
## NYC Taxi Operations Intelligence Platform

This guide walks you through every setup step in exact order.
Every command is explained. Every term is defined.
Do not skip steps — each one is a dependency for the next.

---

## What You Need Before Starting

- A Mac (you have this)
- A Google account with Google Cloud access (you have this)
- A GitHub account (create one free at github.com if you don't have it)
- Terminal open (press Cmd + Space, type "Terminal", press Enter)

---

## STEP 1 — Create the GitHub Repository

**What is GitHub?**
GitHub is where your code lives online. It is version control (tracks every change you make), a portfolio display (employers browse it), and the platform where CI/CD will run in Phase 6.

**What is a repository?**
A repository (repo) is a project folder tracked by Git. Every file, every change, every version is recorded. You can see the full history of every file.

**Do this in your browser:**

1. Go to https://github.com and sign in
2. Click the **+** button in the top right → **New repository**
3. Fill in:
   - Repository name: `nyc-taxi-intelligence`
   - Description: `End-to-end analytics pipeline — NYC Yellow Taxi 2025 | Python · BigQuery · dbt · Tableau`
   - Visibility: **Public** (employers need to see it)
   - Do NOT initialize with README (we already have one)
4. Click **Create repository**
5. GitHub will show you a page with setup commands. Keep this tab open.

---

## STEP 2 — Connect Your Local Folder to GitHub

**What is Git (vs GitHub)?**
Git is software that runs on your computer and tracks changes to files.
GitHub is a website that stores Git repositories online.
Think of Git as the engine and GitHub as the garage where you park it.

**Open Terminal and run these commands one at a time:**

```bash
# Navigate to your project folder
# (adjust the path if yours is different)
cd "/Users/ilyass/Documents/PROJECT 1/DATA ENGINER/ ANALYST"
```

```bash
# Initialize Git in this folder
# This tells Git: "start tracking this folder as a repository"
git init
```

```bash
# Tell Git who you are
# (use the same email as your GitHub account)
git config user.name "Ilyass"
git config user.email "ilyassfcb11@gmail.com"
```

```bash
# Add all existing files to Git's tracking list
# The dot (.) means "all files in this folder and subfolders"
git add .
```

```bash
# Create the first commit — a snapshot of the project right now
# The -m flag adds a message describing what this commit contains
git commit -m "Phase 0: project setup — folder structure, config files, documentation"
```

```bash
# Connect your local folder to the GitHub repository you just created
# Replace YOUR_USERNAME with your actual GitHub username
git remote add origin https://github.com/YOUR_USERNAME/nyc-taxi-intelligence.git
```

```bash
# Push your code to GitHub
# -u origin main sets GitHub as the default destination for future pushes
git push -u origin main
```

Go to your GitHub repo URL and refresh — you should see all your files.

**What just happened?**
You took a snapshot of your project (commit), connected it to GitHub (remote add), and uploaded it (push). From now on, whenever you make changes, you run `git add .` → `git commit -m "message"` → `git push` and your changes go to GitHub.

---

## STEP 3 — Set Up Python Virtual Environment

**What is a virtual environment?**
When you install Python packages, they go into a global folder on your computer. If Project A needs pandas version 1.5 and Project B needs pandas version 2.0, they conflict. A virtual environment is an isolated Python installation just for this project — its own packages, its own versions, completely separate from everything else.

**In Terminal, run these commands:**

```bash
# Make sure you are in your project folder
cd "/Users/ilyass/Documents/PROJECT 1/DATA ENGINER/ ANALYST"
```

```bash
# Check your Python version — should be 3.9 or higher
python3 --version
```

```bash
# Create a virtual environment called "venv" inside your project folder
# python3 -m venv = "run Python's built-in virtual environment tool"
# venv = the name of the folder it will create
python3 -m venv venv
```

```bash
# Activate the virtual environment
# "activate" is a script inside venv/ that switches your terminal
# into the isolated environment
source venv/bin/activate
```

After this command, you will see `(venv)` at the start of your terminal prompt.
This means the virtual environment is active. Any package you install now
goes into venv/ and only affects this project.

```bash
# Upgrade pip (Python's package installer) to the latest version
# pip is what runs when you type "pip install something"
pip install --upgrade pip
```

```bash
# Install all project dependencies from requirements.txt
# pip reads every line in requirements.txt and installs each package
pip install -r requirements.txt
```

This will take 2–4 minutes. You will see a list of packages being downloaded.

**Verify it worked:**
```bash
python3 -c "import pandas; import google.cloud.bigquery; print('All good!')"
```
If you see "All good!" — your environment is ready.

**Important rule:** Every time you open a new Terminal session to work on this project, you must re-activate the virtual environment:
```bash
source venv/bin/activate
```
You will know it is active when you see `(venv)` in your prompt.

---

## STEP 4 — Set Up Google Cloud Project

**What is Google Cloud Platform (GCP)?**
GCP is Google's cloud computing platform. It hosts BigQuery (our data warehouse), manages storage, handles authentication, and controls who can access what. Think of it as the infrastructure layer that makes BigQuery possible.

**What is a GCP Project?**
Everything in GCP lives inside a "project" — a billing unit with its own set of services, permissions, and resources. We create one project for this portfolio project.

**Do this in your browser:**

1. Go to https://console.cloud.google.com
2. Click the project dropdown at the top → **New Project**
3. Fill in:
   - Project name: `nyc-taxi-intelligence`
   - Leave the organization field as-is
4. Click **Create**
5. Wait ~30 seconds, then select your new project from the dropdown

**Enable the BigQuery API:**
1. In the left sidebar → **APIs & Services** → **Library**
2. Search for "BigQuery API"
3. Click it → click **Enable**

**What is an API?**
An API (Application Programming Interface) is how software talks to other software. When our Python script uploads data to BigQuery, it is calling the BigQuery API. Enabling the API is like flipping a switch that says "allow external programs to talk to BigQuery in this project."

---

## STEP 5 — Create a Service Account and Download Credentials

**What is a service account?**
A service account is a special Google account for programs (not humans). When your Python script connects to BigQuery, it logs in as this service account, not as you personally. This is the professional way to handle authentication — you never put your personal Google password in code.

**Do this in your browser:**

1. In GCP Console → left sidebar → **IAM & Admin** → **Service Accounts**
2. Click **+ Create Service Account**
3. Fill in:
   - Service account name: `nyc-taxi-pipeline`
   - Service account ID: auto-fills to `nyc-taxi-pipeline`
   - Description: `Service account for NYC Taxi ingestion and dbt`
4. Click **Create and Continue**
5. On the "Grant this service account access" step:
   - Click **Select a role**
   - Search for and select: **BigQuery Admin**
   - Click **Continue**
   - Click **Done**

**Download the credentials key:**
1. You are now on the Service Accounts list page
2. Click the `nyc-taxi-pipeline` service account
3. Click the **Keys** tab
4. Click **Add Key** → **Create new key**
5. Select **JSON** → click **Create**
6. A JSON file downloads automatically — something like `nyc-taxi-intelligence-abc123.json`

**CRITICAL — do these three things immediately:**
1. Move this file into your project folder, into a `credentials/` subfolder
2. Rename it to `service_account.json` for simplicity
3. Double-check that `credentials/` is in your `.gitignore` (it is — we already added it)

**Why is this file dangerous?**
This JSON file is a complete set of credentials for your GCP project. Anyone who has this file can access your BigQuery, run queries, and generate cloud costs charged to your account. Never commit it to GitHub. Never share it. The `.gitignore` protects you as long as the file is in `credentials/`.

```bash
# Create the credentials folder and verify the file is there
mkdir -p "/Users/ilyass/Documents/PROJECT 1/DATA ENGINER/ ANALYST/credentials"
# Move your downloaded file here and rename it service_account.json
```

---

## STEP 6 — Create the .env File

**What is a .env file?**
Instead of hardcoding your GCP project ID and credentials path directly in Python scripts, we store them in a `.env` file. Python reads this file at startup using `python-dotenv`. The `.gitignore` prevents this file from ever going to GitHub.

**Create this file in your project root:**

```bash
# In your project folder, create .env
touch "/Users/ilyass/Documents/PROJECT 1/DATA ENGINER/ ANALYST/.env"
```

Open it with any text editor and add these lines:

```
# Google Cloud
GCP_PROJECT_ID=nyc-taxi-intelligence
GOOGLE_APPLICATION_CREDENTIALS=/Users/ilyass/Documents/PROJECT 1/DATA ENGINER/ ANALYST/credentials/service_account.json

# BigQuery datasets
BQ_RAW_DATASET=raw
BQ_STAGING_DATASET=staging
BQ_CORE_DATASET=core
BQ_MART_DATASET=mart

# BigQuery table names
BQ_RAW_TRIPS_TABLE=raw_taxi_trips
BQ_RAW_ZONES_TABLE=raw_zone_lookup
```

**Replace `nyc-taxi-intelligence` with your actual GCP Project ID** if it differs. You can find your Project ID in the GCP Console at the top of the page.

**Test that Python can read it:**
```bash
python3 -c "
from dotenv import load_dotenv
import os
load_dotenv()
print('Project ID:', os.getenv('GCP_PROJECT_ID'))
print('Credentials:', os.getenv('GOOGLE_APPLICATION_CREDENTIALS'))
"
```
You should see your project ID and credentials path printed.

---

## STEP 7 — Create the Four BigQuery Datasets

**What is a BigQuery dataset?**
In BigQuery, a "dataset" is like a folder or a database schema. Tables live inside datasets. We have four datasets: `raw`, `staging`, `core`, `mart`. Each one contains the tables for that layer of the pipeline.

**Run this Python script in Terminal to create all four:**

```bash
python3 -c "
from google.cloud import bigquery
from dotenv import load_dotenv
import os

load_dotenv()
project_id = os.getenv('GCP_PROJECT_ID')
client = bigquery.Client(project=project_id)

datasets = ['raw', 'staging', 'core', 'mart']

for dataset_id in datasets:
    dataset_ref = bigquery.Dataset(f'{project_id}.{dataset_id}')
    dataset_ref.location = 'US'
    dataset_ref.description = f'NYC Taxi Intelligence — {dataset_id} layer'
    try:
        client.create_dataset(dataset_ref, exists_ok=True)
        print(f'Created dataset: {dataset_id}')
    except Exception as e:
        print(f'Error creating {dataset_id}: {e}')

print('Done. All datasets ready.')
"
```

**What this script does line by line:**
- `load_dotenv()` — reads your `.env` file
- `bigquery.Client()` — creates a connection to BigQuery using your service account credentials
- For each dataset name, it creates a dataset in BigQuery in the US region
- `exists_ok=True` — if the dataset already exists, do not throw an error, just continue

**Verify in browser:**
Go to https://console.cloud.google.com/bigquery — you should see four datasets: `raw`, `staging`, `core`, `mart` in the left panel.

---

## STEP 8 — Final Git Commit

Push the setup state to GitHub:

```bash
cd "/Users/ilyass/Documents/PROJECT 1/DATA ENGINER/ ANALYST"
source venv/bin/activate

# Check what Git sees as changed
git status

# Add everything (credentials/ is excluded by .gitignore automatically)
git add .

# Commit
git commit -m "Phase 0 complete: environment, BigQuery datasets, documentation"

# Push
git push
```

**Verify on GitHub:** Go to your repo and confirm all files are there. Confirm `credentials/` and `.env` do NOT appear — they should be invisible to Git.

---

## Phase 0 Checklist

When all of these are true, Phase 0 is done:

- [ ] GitHub repo created and code pushed
- [ ] `(venv)` shows in terminal after `source venv/bin/activate`
- [ ] `pip install -r requirements.txt` completed with no errors
- [ ] `python3 -c "import pandas; import google.cloud.bigquery; print('OK')"` prints OK
- [ ] Service account JSON file downloaded and in `credentials/` folder
- [ ] `.env` file created with correct project ID and credentials path
- [ ] Python can read `.env` (test in Step 6 passes)
- [ ] Four BigQuery datasets visible in GCP Console: raw, staging, core, mart
- [ ] Final git commit pushed to GitHub
- [ ] `credentials/` and `.env` are NOT visible on GitHub

---

## What Each Step Taught You

| Step | Concept | Interview relevance |
|---|---|---|
| Step 1–2 | Git and GitHub | "How do you version-control your work?" |
| Step 3 | Python virtual environments | "How do you manage dependencies?" |
| Step 4 | GCP project and API | "Have you worked with cloud platforms?" |
| Step 5 | Service accounts and IAM | "How do you handle credentials securely?" |
| Step 6 | Environment variables | "How do you keep secrets out of code?" |
| Step 7 | BigQuery dataset creation | "Have you used BigQuery?" |
| Step 8 | Git workflow | "Walk me through your development workflow" |

---

*Next: Phase 1 — Writing the Python ingestion script*
