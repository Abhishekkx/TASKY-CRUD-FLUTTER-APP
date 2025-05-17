CRUD App
A Flutter-based task management application implementing CRUD operations with local (SQLite) and remote (REST API) data storage. The app features a clean architecture, state management with BLoC, offline support, and responsive UI.
Features

CRUD Operations: Create, read, update, and delete tasks.
Local Storage: SQLite for offline task persistence.
Remote API: Syncs tasks with JSONPlaceholder (mock REST API).
State Management: BLoC pattern for reactive UI updates.
Offline Support: Saves tasks locally when offline, syncs when online.
User Feedback: Snackbars for actions, loading indicators, and error handling with retry.
Responsive UI: Adapts to different screen sizes.
Swipe-to-Delete: Delete tasks with confirmation dialog.

Architecture

Clean Architecture: Separates presentation, business logic, and data layers.
Layers:
Presentation: Flutter widgets (TaskListScreen, AddEditTaskScreen, TaskTile).
Logic: BLoC (TaskBloc) for state management.
Data: Repository (TaskRepository), services (ApiService, DatabaseHelper, ConnectivityService).


Dependency Injection: get_it for service registration.
State Management: flutter_bloc for event-driven updates.
Data Sources:
Local: sqflite for SQLite database.
Remote: http for JSONPlaceholder API.



Setup Instructions

Prerequisites:

Flutter SDK: >=3.0.0, <4.0.0
Dart SDK
Android/iOS emulator or physical device


Clone the Repository:
git clone <repository-url>
cd crud_app


Install Dependencies:
flutter pub get


Run the App:
flutter run


Build for Release:
flutter build apk  # For Android
flutter build ios  # For iOS



Usage

View Tasks: The main screen shows a list of tasks with titles, descriptions, priorities, and status (green tick for completed, grey circle for pending).
Add Task: Tap the "+" button, fill in the form (title, description, priority, status), and submit.
Edit Task: Tap a task to edit its details.
Delete Task: Swipe a task left, confirm deletion in the dialog.
Offline Mode: Add/edit/delete tasks offline; they sync when connectivity is restored.
Error Handling: Retry button appears for network errors.

Dependencies

flutter_bloc: State management
sqflite: Local database
http: API calls
equatable: Object comparison
path_provider, path: File system access
intl: Date formatting
get_it: Dependency injection
logger: Debugging logs
connectivity_plus: Network status

Project Structure
lib/
├── data/
│   ├── models/          # Task model
│   ├── repositories/    # TaskRepository
│   ├── services/        # ApiService, DatabaseHelper, ConnectivityService
├── logic/
│   ├── blocs/           # TaskBloc, TaskState
│   ├── events/          # TaskEvent
├── presentation/
│   ├── screens/         # TaskListScreen, AddEditTaskScreen
│   ├── widgets/         # TaskTile
├── main.dart            # App entry point

Known Limitations

JSONPlaceholder’s mock API returns arbitrary IDs, which may cause duplicates in SQLite (mitigated by local ID assignment).
No task filtering or search (can be added as a bonus feature).
Minimal UI styling (functional but basic).

Future Improvements

Add task search and filtering.
Enhance UI with custom themes and animations.
Implement background sync for offline tasks.
Add unit and widget tests.


