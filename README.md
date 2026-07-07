# GitHub Repository Search - Flutter Evaluation Task

This is a Flutter application that authenticates with a GitHub personal access token, searches public repositories, and displays detailed repository information - built with `flutter_bloc`, feature-based architecture, and secure on-device token storage.

# Versions

Check these versions run on your machine before running

Flutter **3.34.4** 
Dart **3.12.2** 

Run `flutter --version` to confirm your local environment matches. Mismatched SDK versions are the most common cause of a "works on my machine" build failure during review.

## How to Run

# 1. Clone the repository
git clone the git hub repository - https://github.com/SithijaSankalpa/github_repository_search
cd github_repository_search

# 2. Install dependencies
flutter pub get

# 3. Run on a connected device or emulator
flutter run

The app builds and runs from a clean checkout with no additional configuration files required - **no `.env` file is needed**

## GitHub Token Setup

Required before the app is usable.

The app requires a **GitHub Personal Access Token (classic)** to search repositories. Here's how to generate one:

1 Go to **github.com** - log in

2 Click your profile picture (top right) - **Settings**

3 Scroll to the bottom of the left sidebar - **Developer settings**

4 **Personal access tokens** - **Tokens (classic)**

5 **Generate new token** - **Generate new token (classic)**

6 Fill in:
    **Note**: any label, e.g. `flutter-repo-search`
    **Expiration**: any duration (30 days is fine)
    **Scopes**: **leave all checkboxes unchecked** - public repository search requires no scopes at all. An unscoped token still authenticates and raises the API rate limit from 10/min to ~30/min for search.
    
7 Click **Generate token** and **copy it immediately** - GitHub only shows it once

Paste the token into the app's **token entry screen** on first launch. It is stored via `flutter_secure_storage` (Keychain on iOS, Keystore on Android) and reused automatically on subsequent app launches.

**The token is never hardcoded, never committed to source control, and never stored in plaintext.**

## Architecture Overview

### Layered structure

Widget (UI)  -  Bloc / Cubit (logic + state)  -  Repository (data access)  -  ApiClient (raw HTTP)

**Widgets** are intentionally "dumb" - they render whatever state is handed to them and dispatch events/method calls. No business logic or direct API calls live in the UI layer.
**Blocs/Cubits** own all business logic - they receive events, decide what to do, call the repository, and emit new states.
**Repositories** are the only classes aware of HTTP/JSON. They return clean Dart model objects, never raw response maps, which keeps Blocs fully decoupled from network details and easy to test with fakes.
**`ApiClient`** is a single shared class that centralizes request building, auth headers, and - critically - **maps every HTTP status code to a specific typed exception** 

### Feature-based folder structure

```
lib/
  core/
    network/
      api_client.dart          # shared HTTP client + status-code handling
      api_exception.dart       # typed exception hierarchy
    theme/
      app_theme.dart           # light/dark ThemeData definitions
      theme_cubit.dart         # theme mode state (light/dark toggle)
    presentation/
      splash_screen.dart       # routes to token screen or search screen on launch
  features/
    token/
      data/
        token_repository.dart      # flutter_secure_storage wrapper
      bloc/
        token_cubit.dart
        token_state.dart
      presentation/
        token_screen.dart
    repository_search/
      data/
        models/
          repository_model.dart
        repository_search_repository.dart
      bloc/
        search_bloc.dart
        search_event.dart
        search_state.dart
      presentation/
        search_screen.dart
        widgets/
          repo_list_item.dart
    repo_detail/
      presentation/
        repo_detail_screen.dart
  main.dart

Grouping by **feature** (not by file type) was chosen because each feature is self-contained and can be understood, tested, or modified in isolation - a new contributor working on "search" never needs to touch `token/` files, and vice versa. This scales far better than a `blocs/`, `screens/`, `repositories/` top-level split as the app grows.

# Key Decisions & Justifications

### 1. State management split: Cubit vs Bloc


Token **Cubit** Only simple, direct actions exist (save / load / clear) - no branching event logic needed. A Cubit's method-call API is simpler and avoids unnecessary Event boilerplate. 
Search **Bloc** Multiple distinct event types exist (query changed, next page requested, refreshed, reset) that each need different handling logic - the Event/State separation makes this explicit and testable. 
Theme **Cubit** Single toggle action (light / dark) - no event complexity. 

### 2. Debounced search - **Manual `Timer` + `Completer` inside the Bloc**

**Directly addresses the mandatory requirement:** *"Search must be debounced  do not fire a request on every keystroke."*

**What was implemented:** Every `SearchQueryChanged` event cancels any previously pending debounce timer before starting a new one. Only after **500ms with no further keystrokes** does the Bloc actually call the repository and hit the network. This is implemented with a `Timer` + `Completer` pair inside `SearchBloc._onQueryChanged`, using `emit.isDone` to safely bail out if a newer keystroke has superseded the pending one.

**Why manual `Timer` over `bloc_concurrency`'s `restartable()` transformer:** Both achieve the same debounce behavior. A manual timer was chosen to avoid an additional package dependency for a single, well-understood piece of logic, and to make the debounce mechanism fully visible and self-contained within the Bloc rather than abstracted into a transformer decorator. `bloc_concurrency`'s `restartable()` is a legitimate and arguably more idiomatic alternative for larger Bloc codebases - noted here as a considered alternative

**Verification:** typing a full word quickly (e.g. "flutter" in under a second) triggers exactly **one** network request, ~500ms after the last keystroke - not one request per character.

### 3. Pagination / infinite scroll - **Scroll-position detection + page-based GitHub Search API**

** Directly addresses the mandatory requirement:** *"Paginated / infinite scroll (load more as the user scrolls)."*

**What was implemented:**
- The GitHub Search API's native `page` and `per_page` query parameters are used (`GET /search/repositories?q={query}&page={n}&per_page={size}`).
- A `NotificationListener<ScrollNotification>` wraps the results `ListView` and detects when the user has scrolled within 300px of the bottom.
- On reaching that threshold, a `SearchNextPageRequested` event fires, which appends the next page's results to the existing list via `SearchLoaded.copyWith(...)`.
- `hasReachedMax` is derived by checking if the returned page had fewer items than `perPage` - the natural signal that the last page has been reached, at which point the scroll listener stops firing further requests.
- **Page size:** 20 items per page.

### 4. Repository detail screen - **Reuses list data (no re-fetch)**

** Directly addresses the optional requirement:** *"You may reuse the data already in the list item, or fetch fresh detail... justify the choice."*

**Decision: reuse the `RepositoryModel` already fetched from the search results**, passed directly via constructor to `RepoDetailScreen`, rather than issuing a fresh `GET /repos/{owner}/{repo}` call.

**Justification:**
- The GitHub Search API response already includes every field the detail screen needs: stars, forks, open issues, watchers, language, description, and owner info.
- Avoiding a second network round-trip means the detail screen opens **instantly** with no loading state required, and reduces total API calls - meaningful given the Search API's stricter rate limit (~30 req/min authenticated) compared to the Core API (5000 req/hour).
- **Trade-off acknowledged:** data on the detail screen could be *slightly* stale if the repository's stats changed between the search request and the user tapping into it. For a search-and-browse use case (not a live dashboard), this staleness is negligible and an acceptable trade-off for the responsiveness gained.

### 5. Error handling - Typed exception hierarchy + dedicated UI states

** Directly addresses the mandatory requirement:** *"All four UI states rendered... no silent failures."*

All HTTP responses are mapped in `ApiClient` to one of five typed exceptions (`UnauthorizedException`, `RateLimitException`, `NetworkException`, `InvalidQueryException`, `UnknownApiException`), which `SearchBloc` catches and converts into distinct states:


401  `UnauthorizedException`  `SearchUnauthorized`  Dedicated view: *"Your token is invalid or has expired"* with **Retry** and **Re-enter Token** actions 
403 / 429  `RateLimitException`  `SearchError`  Rate-limit message + Retry 
Network/timeout  `NetworkException`  `SearchError`  Network error message + Retry 
422  `InvalidQueryException`  `SearchError`  Invalid query message 
200, empty `items`  `SearchEmpty`  "No results found" 
200, has `items` - `SearchLoaded`  Results list 

**Invalid token flow specifically:** rather than silently redirecting the user back to the token screen which could be confusing  "why did my search disappear?", an invalid token surfaces a clear, dedicated message explaining *why*, with two explicit user-driven actions: retry the same search, or go re-enter a corrected token. This keeps the user in control rather than acting on their behalf without explanation.

### 6. `envied` package - **Not used for the GitHub token**

The task's tech-constraint table lists Envied for "storing API tokens," but the Token Setup requirements explicitly state the token is **user-entered at runtime** and must be **"never hardcoded and never committed."** These two requirements are inherently in tension: Envied is designed for **build-time secrets** compiled into the binary from a `.env` file - the opposite of a token a user types in live and that differs per user/install.

**Decision:** `envied` was not added as a dependency, and no `.env` file exists in this project. The token is handled exclusively via the runtime flow: user input - `flutter_secure_storage`. This was judged to better satisfy the explicit "never hardcoded" instruction, which takes precedence over the tooling suggestion.


## Open/Optional Items - My Choices

Per §3 of the task, these were intentionally unspecified. Decisions and reasoning below.


Search history persistence** - Not implemented  Descoped to prioritize the mandatory feature set within the time budget. Would add via a lightweight local store (`shared_preferences` or `sqflite`) keyed by recent unique queries, capped at ~10 entries. 
Theming / dark mode - Implemented `ThemeCubit` (simple `Cubit<ThemeMode>`) toggles between `AppTheme.light` and `AppTheme.dark`, switchable via an app bar icon button. Chosen because it was a small, self-contained addition with clear UX value and low implementation risk. 
Token entry: first-run gate vs settings screen**  **First-run gate**  A `SplashScreen` checks `TokenCubit`'s state on launch and routes to either the token screen (no token saved) or the search screen (token present) via `BlocListener`. This was chosen over a settings-screen approach because the app is unusable without a token - gating access up front avoids a confusing "half-working" app state before a token is supplied. Users can still clear/replace their token later via a logout icon in the search screen's app bar, which returns them to this same entry screen.
**Page size for pagination**  **20 items per page**  A middle ground: large enough to minimize the number of paginated requests (respecting the Search API's ~30 req/min limit), small enough to keep each response fast and the list responsive on first load. 
**Result caching**  Not implemented  Descoped due to time. Would add an in-memory `Map<String query+page, List<RepositoryModel>>` cache with a short TTL, checked before hitting the network - meaningfully reduces repeat calls when a user scrolls back up and down or re-runs a recent search. 
**Debounce mechanism**  **Manual `Timer` + `Completer`** (see justification above)  Considered `bloc_concurrency`'s `restartable()` transformer as an alternative; manual approach chosen to keep the debounce logic self-contained and avoid an extra dependency for this scope.
**Error taxonomy** Implemented Distinct typed exceptions and distinct user-facing messages exist for 401 (invalid token), 403/429 (rate limit), network failure, and invalid query - detailed in the [Error Handling]


## Search History (SQLite)

### What is stored

Each time a search **successfully returns results** (first page only, not on pagination "load more"), the following is recorded locally:

`query` The search text, trimmed. Enforced **unique** at the database level. 
`searched_at` Unix timestamp (ms) of when the search was run. 

**Not stored:** the actual repository results, any account/user identity, or anything beyond the query text and a timestamp. This is a lightweight, device-local convenience feature - not a cache or account-linked history.

### Why SQLite (`sqflite`) instead of `SharedPreferences`

Search history is a **growing, orderable, queryable list** - it needs sorting by recency, capping at a maximum count, and per-item deletion. `SharedPreferences` is a simple key-value store, well suited to flags or single values, but awkward for list operations like "give me the 20 most recent, newest first" or "delete this one entry." SQLite (via `sqflite`) is purpose-built for exactly this kind of structured, queryable local data.

### Key decisions

- **Deduplication:** the `query` column has a `UNIQUE` constraint. Re-searching an existing query uses `ConflictAlgorithm.replace` on insert, which updates its `searched_at` timestamp rather than creating a duplicate row - so a re-searched query simply "bumps" to the top of the recency-ordered list instead of appearing twice.
- **Cap:** capped at the **20 most recent** entries. After every insert, the repository checks the total row count and deletes the oldest excess rows beyond the cap, keeping the table small and the history list focused on genuinely recent activity.
- **When a search gets recorded:** only on `SearchLoaded` states where `currentPage == 1` - i.e., a genuine fresh search that returned results. Pagination ("load more") does *not* re-trigger a history write for the same query, and failed/empty searches are not recorded at all.
- **Where it's recorded:** via a `BlocListener<SearchBloc, SearchState>` inside `SearchScreen`, which calls `SearchHistoryCubit.recordSearch()`. This keeps `SearchBloc` fully decoupled from history - it has no knowledge that history exists at all, which keeps its responsibility scoped purely to search behavior.

- **State management:** a `Cubit` (`SearchHistoryCubit`), not a full `Bloc` - consistent with the reasoning used for `TokenCubit`: the only operations are direct actions (record / load / delete / clear), with no competing event types that need Bloc's Event-State branching.
- **Persistence across logout:** search history is **not cleared** when a user logs out / clears their GitHub token, since history is tied to the device rather than to any notion of an "account" (GitHub PATs aren't personal accounts in this app's context). This is a deliberate choice, documented here rather than left as an unstated assumption.
- **UI placement:** shown as an in-place panel below the search bar whenever the search field is empty, rather than a separate screen - chosen since it's a small, frequently-glanced-at list, and a dedicated screen would add an unnecessary navigation hop for a lightweight feature.

### Known limitations

- No "recently used" grouping by date (e.g. "Today," "Earlier this week") - flat list ordered strictly by recency.
- No search/filter within the history list itself - acceptable given the small cap of 20 entries.

## How to Inspect the SQLite Database Directly

Useful for verifying persistence actually works (not just trusting the UI), or for debugging if history behaves unexpectedly.

### Option 1 - Android Studio's built-in Database Inspector (easiest)

1. Run the app on an emulator or a debug-enabled physical device (`flutter run`, debug mode - not release/profile)
2. In Android Studio: **View - Tool Windows - App Inspection**
3. Select the **Database Inspector** tab
4. Choose your running app process from the dropdown
5. You should see your database file (`github_search.db`) listed on the left, with the `search_history` table underneath
6. Click the table to see all rows live - you can even run custom SQL queries in the inspector's query box, e.g.:
   ```sql
   SELECT * FROM search_history ORDER BY searched_at DESC;
=7 This updates in near real-time as the app runs, so you can search something in the app and watch the row appear in the inspector without restarting anything

### Option 2 - Pull the `.db` file off the device manually (Android)

# Find your app's package name in android/app/build.gradle (applicationId)
adb shell run-as <your.package.name> ls /data/data/<your.package.name>/databases/

# Copy the db file to your computer
adb exec-out run-as <your.package.name> cat /data/data/<your.package.name>/databases/github_search.db > github_search.db


Then open `github_search.db` with any SQLite browser tool (e.g. **DB Browser for SQLite** - free, cross-platform: https://sqlitebrowser.org) to inspect tables and rows visually, or run SQL directly against it.

**Note:** `adb shell run-as` requires either a debug build or a rooted device - this won't work against a release build on a non-rooted device, which is expected/correct behavior (app-private storage shouldn't be trivially accessible in production).

### Option 3 - Print rows to console (quick, no extra tools)

Temporarily add this anywhere convenient (e.g. right after the app launches, or behind a debug button) to dump the table straight to your IDE's console:

dart
final db = await DatabaseHelper.instance.database;
final rows = await db.query('search_history', orderBy: 'searched_at DESC');
for (final row in rows) {
  print(row);
}


### Verifying persistence specifically

The real test that SQLite (not just in-memory Bloc state) is doing its job:

1 Search a few different queries
2 **Fully stop** the app (not hot reload/hot restart - actually stop and relaunch via `flutter run`)
3 Focus the empty search field again
4 Your history should still be there - this confirms the data survived a full process restart, which in-memory state alone never would.


## Known Limitations & Future Improvements

Honest account of what's incomplete or simplified, and what I'd prioritize with more time:

**Load-more (pagination) failures are currently silent** - if a next-page request fails mid-scroll, the loading spinner simply stops rather than surfacing an error. Existing results remain visible (a deliberate choice to avoid disrupting an otherwise-successful session), but a toast/snackbar with a retry option would be a clear next improvement.
**No automated tests** - given the time budget, manual testing was prioritized over test coverage. With more time, I would start with unit tests for `SearchBloc`'s state transitions (the most logic-dense piece), using `bloc_test` and a mocked repository.
**No result caching** - every search re-hits the network, even for a query run seconds earlier.
**Repository detail data can be marginally stale** since it reuses list data rather than re-fetching (see justification above) - acceptable for this use case but worth flagging.


## Git Workflow

Development followed a `main` - `develop` - `feature/*` branching model, with incremental, scoped commits per logical unit of work (e.g. `feat: token repository using flutter_secure_storage`, `feat: search bloc with debounce and pagination`, `fix: clear stale search results on token logout`) rather than a single squashed commit. Feature branches were merged into `develop` once complete, with `develop` merged into `main` for the final submission state.

### Summary of mandatory requirement compliance

| Requirement | Status |
|---|---|
| `flutter_bloc` (Bloc/Cubit) | ✅ |
| `http` only (no Dio/Chopper/Retrofit) | ✅ |
| `flutter_secure_storage` for token | ✅ |
| Feature-based structure | ✅ |
| Token setup screen + persistence + replace/clear | ✅ |
| Debounced search | ✅ (manual Timer, justified above) |
| Paginated infinite scroll | ✅ (20/page, scroll-position triggered) |
| Detail screen (stars/forks/issues/watchers/language/description/owner) | ✅ (reuses list data, justified above) |
| Four UI states (loading/data/empty/error) - no silent failures | ✅ (plus a fifth dedicated `SearchUnauthorized` state for 401) |
| Pull-to-refresh | ✅ |
| README with rationale | ✅ (this document) |
| Incremental git history | ✅ |