# Lumi

A cross-platform Todo app with frosted glass UI, built with Flutter.

## Features

- **List view** — tasks grouped by status with swipe-to-delete
- **Kanban board** — drag-and-drop cards across Todo / Doing / Done columns
- **Task form** — create and edit tasks with a title, notes/content, and priority
- **Priority levels** — High / Medium / Low with color-coded indicators
- **Offline-first** — all data stored locally via SQLite (sqflite)

## Task Model

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Auto-generated |
| `title` | String | Required task name |
| `notes` | String? | Optional content/body |
| `status` | Enum | `todo` / `doing` / `done` |
| `priority` | Enum | `high` / `medium` / `low` |
| `deadline` | DateTime? | Optional due date |
| `createdAt` | DateTime | Auto-set on creation |
| `updatedAt` | DateTime | Auto-set on save |

## Architecture

```
lib/
├── core/
│   ├── theme/app_theme.dart       # Design tokens, typography, ThemeData
│   └── widgets/                   # Shared UI primitives (GlassContainer, TagChip, AnimatedBlobs)
├── data/
│   ├── database/app_database.dart # SQLite schema & migrations
│   ├── models/                    # TodoModel, Priority, TodoStatus enums
│   └── repositories/              # TodoRepository (CRUD)
└── features/todo/
    ├── providers/todo_provider.dart
    ├── screens/home_screen.dart
    └── widgets/
        ├── kanban/                # KanbanBoard, KanbanColumn, KanbanCard
        ├── list/                  # TodoListView, TodoListItem
        ├── shared/todo_form_sheet.dart
        ├── sidebar.dart
        └── top_bar.dart
```

## Tech Stack

| Concern | Package |
|---------|---------|
| State management | flutter_riverpod |
| Local database | sqflite + sqflite_common_ffi |
| Date formatting | intl |
| Animations | flutter_animate |
| ID generation | uuid |

## Fonts

Fonts are bundled locally in `fonts/` — no network access required.

| Family | Weights | Usage |
|--------|---------|-------|
| Inter | 400 / 500 / 600 / 700 | Body, labels, UI text |
| Plus Jakarta Sans | 700 | Display / headings |
| JetBrains Mono | 400 | Dates and metadata |

## Running

```sh
flutter pub get
flutter run
```
