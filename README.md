# GitBoard – A Flutter Desktop GitHub Dashboard

**GitBoard** is a Flutter desktop application (Windows, macOS, Linux) that polls your GitHub repository and displays key metrics in a clean, automated “signage‐style” dashboard. It runs full-screen, requires no user input, and automatically refreshes on a configurable interval.

---

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

- **Flutter** ≥ 2.17 with desktop support  
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
    GITHUB_TOKEN=ghp_XXXXXXXXXXXXXXXXXXXXXXXX
    GITHUB_REPO=owner/repo
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
GITHUB_TOKEN |Your GitHub personal access token |ghp_ABC...
GITHUB_REPO| Repository to track (owner/repo) | flutter/flutter
POLLING_INTERVAL_SECONDS|Refresh interval in seconds |30
LINES_ADDED_COLOR|Hex color for “added” number (with #)|#01E6B3
LINES_DELETED_COLOR|Hex color for “deleted” number| #FD7A7A

## 📁 Project Structure

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
