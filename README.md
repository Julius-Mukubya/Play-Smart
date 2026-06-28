# PlaySmart

PlaySmart is a mobile-first talent discovery platform for athletes in Uganda and the wider East African region. The app serves as a discovery bridge, allowing grassroots athletes to get noticed by scouts, recruiters, and clubs. Real evaluation and contracting happen off-platform through trials and direct contact.

---

## Key Features

*   **Athlete Profiles:** Professional sports resumes detailing positions, physical metrics, locations, and availability statuses.
*   **Highlight Galleries:** Media uploads (videos, photos, posts) tagged with moments like Goals, Assists, Sprints, Tackles, and Saves.
*   **Trust Badges:** A verification model tiering player achievements into Self-Reported, Coach-Endorsed, and Club-Verified levels.
*   **Recruiter Search & Filtering:** Powerful filters to query athletes by age, sport, position, location, and verified badges.
*   **Double-Consent Messaging:** Gated messaging threads that only open once the athlete explicitly accepts a message request.
*   **Trial Postings:** Opportunity boards for clubs to broadcast open trials, matching criteria, and capacity limits.
*   **Video Recommendation Engine:** A Postgres-level RPC query that ranks feed content based on matching sports, proximity, active boosts, and freshness.

---

## Architecture & Tech Stack

*   **Framework:** Flutter 3.x
*   **State Management:** Flutter Riverpod
*   **Routing:** GoRouter (centralized app router)
*   **Database & Backend:** Supabase (PostgreSQL, custom triggers, storage, and RLS policies)
*   **Dependencies:** `supabase_flutter`, `flutter_secure_storage`, `cached_network_image`, `go_router`

---

## Directory Structure

```
lib/
├── auth/            # Sign up, sign in, splash, and session management
├── profiles/        # Athlete profile CRUD, achievements, and onboarding
├── discovery/       # Feed page, advanced search, and recommendation query
├── shortlisting/    # Recruiter shortlists and private notes
├── opportunities/   # Trial postings, applications, and capacity checks
├── messaging/       # Message requests and double-consent threads
├── notifications/   # System push and read/unread events
├── payments/        # Subscriptions, transactions, and boost products
├── analytics/       # Profile view statistics (gated analytics)
├── admin/           # Account moderation and credential verification
├── core/            # App routing and light blue branding theme
└── shared/          # Central domain types and reusable widgets
```

---

## Setup & Running Locally

### 1. Prerequisite Packages
Verify Flutter is installed:
```bash
flutter doctor
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run the App
Launch on an emulator or connected device:
```bash
flutter run
```

### 4. Running Tests
Run the complete unit, widget, and integration test suite:
```bash
flutter test
```
