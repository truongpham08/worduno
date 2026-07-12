# Lexia

Flutter client for learning Destination vocabulary — flashcards, exams, and AI coach.

> **Báo cáo tiến độ dự án:** xem [docs/report.md](docs/report.md) (kiến trúc, use case, ERD, tiến độ triển khai).

## Architecture

MVVM by feature, aligned with course conventions:

```
lib/
├── app/          # App shell, Navigator 2.0, DI
├── core/         # Shared infra (network, database, utils, widgets)
├── shared/       # Cross-feature modules (vocabulary API, word state local)
└── features/     # home, learning, exam, coach, dashboard
```

Each feature follows four layers:

| Layer | Responsibility | Example |
|-------|----------------|---------|
| **presentation** | Page + ViewModel | `LevelListPage`, `LevelListViewModel` |
| **application** | Use cases | `IHomeService`, `HomeServiceImpl` |
| **domain** | Entities + repository contracts | `User`, `IAuthRepository` |
| **data** | DTO, Mapper, DataSource, Repository impl | API / SQLite |

### Rules

- Page does **not** call API directly.
- ViewModel does **not** use DTO.
- Service / Repository always split **interface + impl**.
- Do **not** import another feature's `data/` folder.

## Stack

- **State (ViewModel):** `provider` + `ChangeNotifier`
- **DI:** `get_it`
- **HTTP:** `dio`
- **Local DB:** `sqflite`
- **Navigation:** Flutter **Navigator 2.0** (`RouterDelegate` + `RouteInformationParser`)
- **TTS:** `flutter_tts` via `ITtsService` (`core/tts/`) — term pronunciation on Term List, Learn, and Coach

## Backend

Vocabulary API: [destination-vocabulary-api.onrender.com/docs](https://destination-vocabulary-api.onrender.com/docs)

| Endpoint | Purpose |
|----------|---------|
| `GET /api` | Levels |
| `GET /api/{level}/units` | Units |
| `GET /api/{level}/units/{unit_name}` | Terms |

AI endpoints (Exam Cloze, Sentence Writing, Coach explain/evaluate) are integrated via `ExamAiDataSourceImpl` and `CoachAiDataSourceImpl` — see [report.md §7](docs/report.md#7-tích-hợp-api).

## Getting started

```bash
flutter pub get
flutter run
```

First run creates `lexia.db` with tables for word state, exam history, and coach history.

## Feature map

| Feature | Scope |
|---------|-------|
| `home` | Level → Unit → Term browsing |
| `learning` | Full-screen flashcard session |
| `exam` | Config, session, result, **history**, detail |
| `coach` | AI coach session, **history**, detail |
| `dashboard` | Progress & stats |
| `shared/word_state` | Star / Know / Learning (local, no UI screen) |
| `shared/vocabulary` | Level / Unit / Term from API |

## Navigation

Bottom tabs (spec §2): **Home · Dashboard · Exam History · Coach History**

Home tab uses a nested `Navigator` stack:

`Level List → Unit List → Term List → Learn / Exam / Coach`

Use `AppNavigationNotifier` (via `context.read`) to push home routes — do not call `Navigator.push` directly from Pages unless extending the router delegate.

## Documentation

| Document | Description |
|----------|-------------|
| [docs/report.md](docs/report.md) | Technical report for project review (architecture, use cases, ERD, progress) |
| [docs/specs.md](docs/specs.md) | Full functional requirements (SRS) |

## Tests

```bash
flutter test
```

Coverage focuses on Learn session rules, word-state persistence, exam grading, and network error handling — see [report.md §11](docs/report.md#11-kiểm-thử).
