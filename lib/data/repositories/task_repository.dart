import 'package:logger/logger.dart';
import 'package:crud_app/data/models/task.dart';
import 'package:crud_app/data/services/api_service.dart';
import 'package:crud_app/data/services/connectivity_service.dart';
import 'package:crud_app/data/services/database_helper.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskRepository {
  final DatabaseHelper dbHelper;
  final ApiService apiService;
  final ConnectivityService connectivityService = GetIt.I<ConnectivityService>();
  final Logger _logger = Logger();
  bool _isCleared = false; // In-memory flag, will be synced with SharedPreferences

  TaskRepository({required this.dbHelper, required this.apiService}) {
    _loadClearedFlag(); // Load the flag on initialization
  }

  // Load the _isCleared flag from SharedPreferences
  Future<void> _loadClearedFlag() async {
    final prefs = await SharedPreferences.getInstance();
    _isCleared = prefs.getBool('isCleared') ?? false;
    _logger.i('Loaded _isCleared flag: $_isCleared');
  }

  // Save the _isCleared flag to SharedPreferences
  Future<void> _saveClearedFlag(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isCleared', value);
    _isCleared = value;
    _logger.i('Saved _isCleared flag: $_isCleared');
  }

  Future<List<Task>> getTasks() async {
    _logger.i('Fetching tasks');
    try {
      if (await connectivityService.isConnected() && !_isCleared) {
        _logger.i('Fetching tasks from API');
        final apiTasks = await apiService.fetchTasks();
        _logger.i('Syncing ${apiTasks.length} API tasks to local database');
        for (final task in apiTasks) {
          await dbHelper.insertTask(task);
        }
      } else {
        if (_isCleared) {
          _logger.i('Skipping API fetch due to recent clear operation');
        } else {
          _logger.w('Offline, skipping API fetch');
        }
      }
      final localTasks = await dbHelper.getTasks();
      _logger.i('Returning ${localTasks.length} tasks from local database');
      return localTasks;
    } catch (e, stackTrace) {
      _logger.e('Error fetching tasks, falling back to local: $e\nStackTrace: $stackTrace');
      final localTasks = await dbHelper.getTasks();
      _logger.i('Returning ${localTasks.length} local tasks');
      return localTasks;
    }
  }

  Future<int> addTask(Task task) async {
    _logger.i('Adding task to repository: ${task.title}');
    if (task.title.isEmpty || task.description.isEmpty) {
      _logger.e('Task title or description is empty');
      throw Exception('Task title and description cannot be empty');
    }
    try {
      final localId = await dbHelper.insertTask(task.copyWith(id: null));
      _logger.i('Task saved locally with id: $localId');
      if (await connectivityService.isConnected()) {
        try {
          final createdTask = await apiService.createTask(task);
          _logger.i('Task created in API with id: ${createdTask.id}');
          await dbHelper.insertTask(createdTask.copyWith(id: localId));
          _logger.i('Updated local task with API data, id: $localId');
        } catch (e, stackTrace) {
          _logger.e('API add failed: $e\nStackTrace: $stackTrace');
        }
      } else {
        _logger.w('Offline, task queued locally');
      }
      return localId;
    } catch (e, stackTrace) {
      _logger.e('Error adding task to local database: $e\nStackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<void> updateTask(Task task) async {
    _logger.i('Updating task in repository: ${task.title} (id: ${task.id})');
    if (task.id == null) {
      _logger.e('Cannot update task with null ID');
      throw Exception('Task ID cannot be null for update');
    }
    if (task.title.isEmpty || task.description.isEmpty) {
      _logger.e('Task title or description is empty');
      throw Exception('Task title and description cannot be empty');
    }
    try {
      await dbHelper.insertTask(task);
      _logger.i('Task updated locally');
      if (await connectivityService.isConnected()) {
        try {
          await apiService.updateTask(task);
          _logger.i('Task updated in API');
        } catch (e, stackTrace) {
          _logger.e('API update failed: $e\nStackTrace: $stackTrace');
        }
      } else {
        _logger.w('Offline, task updated locally');
      }
    } catch (e, stackTrace) {
      _logger.e('Error updating task in local database: $e\nStackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<void> deleteTask(int id) async {
    _logger.i('Deleting task with id: $id');
    try {
      final db = await dbHelper.database;
      await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
      _logger.i('Task deleted locally');
      if (await connectivityService.isConnected()) {
        try {
          await apiService.deleteTask(id);
          _logger.i('Task deleted from API');
        } catch (e, stackTrace) {
          _logger.e('API delete failed: $e\nStackTrace: $stackTrace');
        }
      } else {
        _logger.w('Offline, task deleted locally');
      }
    } catch (e, stackTrace) {
      _logger.e('Error deleting task: $e\nStackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<void> clearTasks() async {
    _logger.i('Clearing all tasks');
    try {
      // Fetch all task IDs from the local database
      final tasks = await dbHelper.getTasks();
      final taskIds = tasks.map((task) => task.id!).toList();
      _logger.i('Found ${taskIds.length} tasks to clear');

      // Clear all tasks from the local database
      await dbHelper.clearTasks();
      _logger.i('All tasks cleared from local database');

      // If online, delete tasks from the API in batches
      if (await connectivityService.isConnected()) {
        const batchSize = 30; // Delete 10 tasks per batch
        for (var i = 0; i < taskIds.length; i += batchSize) {
          final batch = taskIds.sublist(
              i, (i + batchSize) > taskIds.length ? taskIds.length : i + batchSize);
          _logger.i('Deleting batch of ${batch.length} tasks: $batch');
          try {
            await Future.wait(batch.map((id) => apiService.deleteTask(id)));
            _logger.i('Deleted batch of tasks: $batch');
          } catch (e, stackTrace) {
            _logger.e('Failed to delete batch of tasks: $e\nStackTrace: $stackTrace');
            rethrow;
          }
        }
        _logger.i('All tasks cleared from API');
        // Only set _isCleared to true if API deletion succeeds
        await _saveClearedFlag(true);
      } else {
        _logger.w('Offline, tasks cleared locally only');
        // If offline, set _isCleared to true since local tasks are cleared
        await _saveClearedFlag(true);
      }
    } catch (e, stackTrace) {
      _logger.e('Error clearing tasks: $e\nStackTrace: $stackTrace');
      rethrow;
    }
  }

  // Optional: Method to reset the _isCleared flag if needed
  Future<void> resetClearedFlag() async {
    await _saveClearedFlag(false);
    _logger.i('Reset _isCleared flag to false');
  }
}