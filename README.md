# Ollie

Ollie is a local-first, single-user kanban board for planning work, running
sprints, tracking time and reviewing burndown. Boards live in a local SQLite
database (IndexedDB on the web); there are no accounts, no server, and no
network calls.

## Features

- Boards, columns and drag-and-drop cards with stable LexoRank ordering.
- Priorities, due dates, estimates, subtasks and completion state.
- Planning/active/completed sprints with derived card membership.
- Manual time logs, editable entries, and per-card logged-hour totals.
- Burndown charts, sprint analytics, JSON/CSV board export.
- Light/dark/system themes, persisted locally.
- Automatic v1 → v2 database migration (see below).

## Requirements

- Flutter 3.47.5+ (Dart 3.13+)
- For the web: Chrome/Edge/Firefox with WebAssembly support

## Development

```bash
flutter pub get
flutter run -d chrome      # web
flutter run -d linux       # desktop
flutter run                # connected mobile device
```

Quality gates used by CI:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test
flutter build web --release
```

### Web database assets

The web build uses `sqflite_common_ffi_web`, which needs two files in `web/`:

- `web/sqlite3.wasm`
- `web/sqflite_sw.js`

Both are committed so `flutter build web` works out of the box. If you upgrade
`sqflite_common_ffi_web`, regenerate them with:

```bash
dart run sqflite_common_ffi_web:setup
```

Do not remove them from a deployment: without them the app shows the startup
error screen instead of a blank page.

## Where data lives

| Platform | Location |
| --- | --- |
| Linux/macOS/Windows | `ollie.db` in the application documents directory |
| Android/iOS | app-private `ollie.db` |
| Web | IndexedDB database `sqflite_databases` |

Data is intentionally device-local. Copy the SQLite file or use **Board →
Export** to back up a board. Clearing site data/browser storage deletes web
boards.

## Architecture

```text
lib/
  algos/            LexoRank
  components/       cards, dialogs, board UI
  database/         schema, migrations, JSON helpers
  models/           Board, BoardColumn, Card, Sprint, TimeLog, ...
  providers/        Riverpod state (boards, board, sprints, burndown, theme)
  repositories/     BoardRepository/SprintRepository + local SQLite impls
  screens/          home and board screens
  services/         local change bus + board event filtering
  utils/            copyWith sentinel and responsive helpers
```

Persistence rules:

- `cards.sprint_id` is the single source of truth for sprint membership.
- `cards.total_logged_hours` is recomputed from `time_logs` after every log
  write, and the repository emits a card update so open views refresh.
- `copyWith(null)` clears a nullable field; omitting the argument keeps it.
- All multi-row writes (sprint delete, membership moves, time-log totals) use
  SQLite transactions.

## Database migration (v1 → v2)

v1 was the Appwrite-era schema. On first launch of v2:

- Boards, columns, cards, sprints, checklists, time logs and snapshots are
  preserved.
- Sprint membership stored in `sprints.card_ids` is backfilled into
  `cards.sprint_id`.
- Card totals are recomputed from `time_logs`.
- Ranks are normalized to fixed-length LexoRank values.
- Collaboration-only tables (`users`, `board_members`, `labels`, `comments`,
  `invitations`, `password_reset_tokens`) are dropped.

Back up `ollie.db` before upgrading if you need the collaboration metadata.

## Deployment

The Flutter web app deploys to Vercel from `main` via
`.github/workflows/deploy.yml`. The workflow formats/analyzes/tests, builds,
stamps `build/web/version.json` with the commit SHA, copies `vercel.json`, and
verifies the two SQLite web assets are present.

The landing page in `frontend/` is a SvelteKit site; CI builds it with
`npm ci && npm run build`.

## Android release signing

Release builds read `android/key.properties` (ignored by git):

```bash
cp android/key.properties.example android/key.properties
# fill in storePassword, keyPassword, keyAlias and storeFile
```

Without that file the release build falls back to debug signing, which is only
suitable for local testing.

## Scope

This repository is deliberately a local single-user application. Features that
require shared state (accounts, invitations, members, comments, live cursors,
multi-device sync) are out of scope and were removed with the local-only port.
