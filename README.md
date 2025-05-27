# GitBoard – A Flutter Desktop GitHub Dashboard

**GitBoard** is a Flutter desktop application (Windows, macOS, Linux) that polls your GitHub repository and displays key metrics in a clean, automated “signage‐style” dashboard. It runs full-screen, requires no user input, and automatically refreshes on a configurable interval.

---

> [!IMPORTANT]
> Newest update: now supporting enterprise GitHub Instances.

> [!CAUTION]
> This repo currently stores your access token in plain and might log it for development purposes. Make sure to properly scope your token (for public repositories, an unscoped token may be used; for private repositories, check "Repository metadata: read-only" and "Contents: read only"). This system will soon be changed so the application asks for an access token on first run, then stores it in your OS secure storage.

## Screenshots

### Dashboard is online:

![Screenshot of "gitboard" project in online state.](<images/online.png>)

### Dashboard is offline (more caching will be implemented soon):

![Screenshot of "gitboard" project in offline state](<images/offline.png>)

## 🔍 Features (Current)

- **Polling & Offline Support**  
  - Fetches data in configurable frequency via GitHub GraphQL + REST search.  
  - Caches last result up to 48 hrs; shows a offline banner if a refresh fails but stale data is available.

- **Sub-Header Metrics (full-width)**  
  - **PRs opened / merged (24 h)**  
  - **Latest commit** (author, commit-title, short SHA, “_XX_ m ago”)  
  - **Branch count** (total `refs/heads/`)  
  - **Star count**

- **Grid Widgets**  
  1. **Code Lines Added / Deleted(last 24 h):**  
  2. **Language Breakdown**  

- **Theming & Layout**  
  - Mostly fixed at the Moment, will be configurable soon.

- **State Management**  
  - BLoC pattern (`flutter_bloc` + `equatable`)  
  - `MetricsBloc` drives periodic fetch → loading / success / error + stale transitions  

---

## 🛠️ Prerequisites

- **Flutter** built and confirmed working on 3.8.0-177.0.dev
- A **GitHub Personal Access Token** with at least `repo` read permissions  
- A **`.env`** file at project root (see Config below)  

---

## 🚀 Getting Started

1. **Clone & Prepare**  

   ```bash
   git clone https://github.com/your-org/gitboard.git
   cd gitboard
   flutter channel stable
   flutter upgrade

2. Create .env (in project root)

    ```dotenv
    IS_ENTERPRISE=false # Set to true if using GitHub Enterprise
    GITHUB_API_URL=https://ghe.mycompany.com # Change this to your GitHub Enterprise URL if IS_ENTERPRISE is true
    GITHUB_TOKEN=ghp_XXXXXXXXXXXXXXXXXXXXXXXX
    GITHUB_REPO=owner/repo e.g. flutter/flutter
    POLLING_INTERVAL_SECONDS=30
    # Colors (hex, 6 or 8 digits)
    LINES_ADDED_COLOR=#01E6B3
    LINES_DELETED_COLOR=#FD7A7A

3. Install & Run

    ```bash
      flutter pub get
      flutter run -d windows   # or -d macos, -d linux

## ⚙️ Configuration

Env Var | Description| Example
---|---|---
IS_ENTERPRISE | Wether the application should be built to track a repo on an enterprise instance of GitHub | true or false
GITHUB_API_URL | The URL at which your enterprise instance is running (if any) | ghe.mycompany.com
GITHUB_TOKEN |Your GitHub personal access token |ghp_ABC...
GITHUB_REPO| Repository to track (owner/repo) | flutter/flutter
POLLING_INTERVAL_SECONDS|Refresh interval in seconds |30
LINES_ADDED_COLOR|Hex color for “added” number (with #)|#01E6B3
LINES_DELETED_COLOR|Hex color for “deleted” number| #FD7A7A

## 📁 Project Structure (deprecated, will be updated soon)

```pgsql
lib/
 ├─ models/
 │   ├─ language_stat.dart       # name, colorHex, percentage
 │   ├─ latest_commit.dart       # author, title, SHA, minutesAgo
 │   └─ metrics.dart             # DTO for all metrics
 ├─ repository/
 │   └─ metrics_repository.dart  # GraphQL + search logic
 ├─ services/
 │   └─ graphql_service.dart     # GraphQL client wrapper
 ├─ blocs/
 │   ├─ metrics_bloc.dart
 │   ├─ metrics_event.dart
 │   └─ metrics_state.dart
 ├─ ui/
 │   ├─ dashboard_page.dart
 │   ├─ widgets/
 │   │   ├─ header.dart
 │   │   ├─ sub_header.dart
 │   │   ├─ lines_metric.dart
 │   │   ├─ language_breakdown.dart
 │   │   └─ offline_banner.dart
 └─ main.dart                    # App setup & DI
