# Employee Management App - Tech Test

Flutter application for managing employee records with offline support and optimistic UI.

## Setup

```bash
flutter pub get
dart run build_runner build
flutter run
```

## Architecture

**Clean Architecture** with three layers:
- **Core**: API client (Dio), local database (Drift), routing (GoRouter)
- **Data**: Repository pattern with optimistic UI
- **Presentation**: Riverpod state management, Material 3 UI

## Key Features

### Core Requirements
- **List Screen**: Displays all employees with pull-to-refresh
- **Details Screen**: Shows employee information with edit/delete actions
- **CRUD Operations**: Create, update, and delete employees

### Bonus Features
- **Offline Support**: Drift database caches all data locally
- **Optimistic UI**: Instant feedback on all mutations with automatic rollback on failure
- **Error Handling**: Custom exception hierarchy with user-friendly messages

## Implementation Highlights

### Optimistic UI Pattern
All CRUD operations update the local database immediately, then sync with the API in the background:
- **Create**: Insert locally → Call API → Update with server ID or rollback
- **Update**: Update locally → Call API → Mark as synced or rollback
- **Delete**: Delete locally → Call API → Re-insert if failed

### Offline-First Strategy
- Data fetched from local database immediately (instant UI)
- API syncs in background and updates database
- App works fully offline with cached data

### State Management
- **Riverpod** for dependency injection and state
- **Streams** for reactive UI updates
- **AsyncNotifier** for mutation operations

## Project Structure

```
lib/
├── core/
│   ├── api/           # HTTP client with error handling
│   ├── database/      # Drift database setup
│   └── router.dart    # Navigation routes
├── features/
│   └── employees/
│       ├── data/      # Models & repository (business logic)
│       └── presentation/
│           ├── providers/  # Riverpod state management
│           ├── screens/    # List, details, form screens
│           └── widgets/    # Reusable employee card
└── main.dart          # App entry point with Material 3 theme
```

## API

Uses [Dummy REST API](https://dummy.restapiexample.com/api/v1) for employee data.

**Note**: API has inconsistent response formats (GET uses `employee_name`, POST/PUT use `name`). Custom parsing handles both formats.
