# Lumi

A cross-platform, offline-first task management app with a frosted glass UI, built with Flutter.

> **Platform notice:** This project is developed and tested on **macOS (Apple Silicon / M1)**. Other platforms (iOS, Android) are theoretically supported by Flutter but have not been verified. If you'd like to bring up support for another platform, feel free to fork the repo and open a PR — contributions are welcome!

---

## Features

- **List view** — tasks grouped by status (To Do / In Progress / Done) with swipe-to-delete
- **Kanban board** — drag-and-drop cards across Todo / Doing / Done columns
- **Task detail** — full-page editing with a Bear-style WYSIWYG Markdown editor for notes
- **Overview** — task statistics (total, completion rate, status breakdown) with date-range filtering (Today / Week / Month / Custom)
- **Priority levels** — High / Medium / Low with color-coded indicators
- **Deadline picker** — optional due date with a custom frosted-glass date-range picker
- **Responsive shell** — collapsible sidebar on wide screens, compact layout on mobile
- **Offline-first** — all data stored locally via SQLite; no network access required

---

## Screenshots

> _Add screenshots here_

---

## Task Model

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Auto-generated |
| `title` | String | Required task name |
| `notes` | String? | Markdown content; edited in the WYSIWYG editor |
| `status` | Enum | `todo` / `doing` / `done` |
| `priority` | Enum | `high` / `medium` / `low` |
| `deadline` | DateTime? | Optional due date |
| `createdAt` | DateTime | Auto-set on creation |
| `updatedAt` | DateTime | Auto-updated on save |

---

## Architecture

```
lib/
├── app.dart
├── main.dart
├── core/
│   ├── services/
│   │   ├── app_directory_service.dart   # Resolves & opens the local data directory
│   │   ├── app_update_service.dart      # Checks GitHub Releases and opens DMG downloads
│   │   └── clipboard_image_service.dart # Paste-image support in the editor
│   ├── theme/
│   │   └── app_theme.dart               # Design tokens, typography, ThemeData
│   ├── utils/
│   │   └── markdown_utils.dart
│   └── widgets/
│       ├── animated_blobs.dart          # Background ambient animation
│       ├── glass_container.dart         # Reusable frosted-glass surface
│       ├── glass_date_range_picker.dart # Custom date-range picker dialog
│       └── markdown_editor.dart         # Bear-style WYSIWYG Markdown editor
├── data/
│   ├── database/app_database.dart       # SQLite schema & migrations
│   ├── models/todo_model.dart           # TodoModel, Priority, TodoStatus enums
│   └── repositories/todo_repository.dart
└── features/todo/
    ├── data/task_view_cache.dart
    ├── providers/todo_provider.dart
    ├── screens/
    │   ├── home_screen.dart             # Root shell (sidebar + view switcher)
    │   ├── overview_screen.dart         # Stats & date-range filtering
    │   ├── task_detail_screen.dart      # Full-page task editor
    │   └── me_screen.dart              # Profile & local storage settings
    └── widgets/
        ├── kanban/                      # KanbanBoard, KanbanColumn, KanbanCard
        ├── list/                        # TodoListView, TodoListItem
        ├── shared/
        │   ├── todo_form_sheet.dart     # Create / quick-edit bottom sheet
        │   └── task_preview_sheet.dart  # Inline preview bottom sheet
        ├── sidebar.dart
        └── top_bar.dart
```

---

## Tech Stack

| Concern | Package |
|---------|---------|
| State management | `flutter_riverpod` |
| Local database | `sqflite` + `sqflite_common_ffi` |
| WYSIWYG Markdown editor | `appflowy_editor` |
| Animations | `flutter_animate` |
| Date formatting | `intl` |
| ID generation | `uuid` |
| Path utilities | `path` + `path_provider` |

---

## Fonts

All fonts are bundled in `fonts/` — no network access required at runtime.

| Family | Weights | Usage |
|--------|---------|-------|
| Inter | 400 / 500 / 600 / 700 | Body, labels, UI text |
| Plus Jakarta Sans | 700 | Display headings |
| JetBrains Mono | 400 | Dates and metadata |

---

## Getting Started

**Prerequisites:** Flutter SDK ≥ 3.5.0

```sh
flutter pub get
flutter run -d macos   # primary target (Apple Silicon / M1)
```

Other platforms have not been tested. If you run into issues on iOS or Android, you're welcome to fork and submit a PR with fixes.

---

## App Updates

The Profile page includes a manual `Check for updates` action for macOS builds.

- The app reads its current version from the bundled macOS app metadata.
- It checks `https://api.github.com/repos/ITfisher/lumi/releases/latest`.
- If the latest release contains a `.dmg` asset, Lumi opens that download directly.
- If no `.dmg` asset is attached, Lumi falls back to the GitHub release page.

For this flow to work cleanly, keep these release conventions:

- Use semantic version tags like `v1.2.0`.
- Attach exactly one macOS `.dmg` file to the release when possible.
- Bump `version:` in [pubspec.yaml](/Users/panda/Documents/github/lumi/pubspec.yaml) before tagging a stable release.

---

## Contributing

This project is primarily maintained for personal use on macOS (M1). Contributions that extend platform support or fix bugs on other targets are especially appreciated.

1. Fork the repository
2. Create a feature branch (`git checkout -b feat/your-feature`)
3. Commit your changes
4. Open a Pull Request
