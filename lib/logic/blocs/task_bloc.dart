import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:crud_app/data/models/task.dart';
import 'package:crud_app/data/repositories/task_repository.dart';
import 'package:crud_app/logic/events/task_event.dart';
import 'package:crud_app/logic/blocs/task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository taskRepository;
  final Logger _logger = Logger();

  TaskBloc(this.taskRepository) : super(TaskInitial()) {
    _logger.i('TaskBloc initialized');
    on<LoadTasks>(_onLoadTasks);
    on<AddTask>(_onAddTask);
    on<UpdateTask>(_onUpdateTask);
    on<DeleteTask>(_onDeleteTask);
    on<RetryTasks>(_onRetryTasks);
    on<ClearTasks>(_onClearTasks);
  }

  Future<void> _onLoadTasks(LoadTasks event, Emitter<TaskState> emit) async {
    _logger.i('Handling LoadTasks event');
    emit(TaskLoading());
    try {
      final tasks = await taskRepository.getTasks();
      _logger.i('Loaded ${tasks.length} tasks');
      emit(TaskLoaded(tasks));
    } catch (e, stackTrace) {
      _logger.e('Error loading tasks: $e\nStackTrace: $stackTrace');
      emit(TaskError('Failed to load tasks: $e'));
    }
  }

  Future<void> _onAddTask(AddTask event, Emitter<TaskState> emit) async {
    _logger.i('Handling AddTask event for task: ${event.task.title}');
    emit(TaskLoading());
    try {
      final localId = await taskRepository.addTask(event.task);
      _logger.i('Task added to repository, localId: $localId');

      // Manually update the state instead of calling getTasks()
      final currentState = state;
      if (currentState is TaskLoaded) {
        final updatedTasks = List<Task>.from(currentState.tasks)
          ..add(event.task.copyWith(id: localId));
        _logger.i('Task added successfully, emitting TaskLoaded with ${updatedTasks.length} tasks');
        emit(TaskLoaded(updatedTasks));
      } else {
        // Fallback to getTasks if the state is not TaskLoaded
        final tasks = await taskRepository.getTasks();
        _logger.i('Task added successfully, emitting TaskLoaded with ${tasks.length} tasks');
        emit(TaskLoaded(tasks));
      }
    } catch (e, stackTrace) {
      _logger.e('Error adding task: $e\nStackTrace: $stackTrace');
      emit(TaskError('Failed to add task: $e'));
    }
  }

  Future<void> _onUpdateTask(UpdateTask event, Emitter<TaskState> emit) async {
    _logger.i('Handling UpdateTask event for task: ${event.task.title} (id: ${event.task.id})');
    if (event.task.id == null) {
      _logger.e('Task ID is null during update');
      emit(TaskError('Task ID cannot be null for update'));
      return;
    }
    emit(TaskLoading());
    try {
      await taskRepository.updateTask(event.task);
      _logger.i('Task updated in repository');
      final tasks = await taskRepository.getTasks();
      _logger.i('Task updated successfully, emitting TaskLoaded with ${tasks.length} tasks');
      emit(TaskLoaded(tasks));
    } catch (e, stackTrace) {
      _logger.e('Error updating task: $e\nStackTrace: $stackTrace');
      emit(TaskError('Failed to update task: $e'));
    }
  }

  Future<void> _onDeleteTask(DeleteTask event, Emitter<TaskState> emit) async {
    _logger.i('Handling DeleteTask event for id: ${event.id}');
    emit(TaskLoading());
    try {
      await taskRepository.deleteTask(event.id);
      _logger.i('Task deleted from repository');
      final tasks = await taskRepository.getTasks();
      _logger.i('Task deleted successfully, emitting TaskLoaded with ${tasks.length} tasks');
      emit(TaskLoaded(tasks));
    } catch (e, stackTrace) {
      _logger.e('Error deleting task: $e\nStackTrace: $stackTrace');
      emit(TaskError('Failed to delete task: $e'));
    }
  }

  Future<void> _onRetryTasks(RetryTasks event, Emitter<TaskState> emit) async {
    _logger.i('Handling RetryTasks event');
    emit(TaskLoading());
    try {
      final tasks = await taskRepository.getTasks();
      _logger.i('Retry successful, loaded ${tasks.length} tasks');
      emit(TaskLoaded(tasks));
    } catch (e, stackTrace) {
      _logger.e('Retry failed: $e\nStackTrace: $stackTrace');
      emit(TaskError('Failed to retry tasks: $e'));
    }
  }

  Future<void> _onClearTasks(ClearTasks event, Emitter<TaskState> emit) async {
    _logger.i('Handling ClearTasks event');
    emit(TaskLoading());
    try {
      await taskRepository.clearTasks();
      _logger.i('All tasks cleared successfully (local database and API)');
      emit(TaskLoaded([]));
    } catch (e, stackTrace) {
      _logger.e('Error clearing tasks: $e\nStackTrace: $stackTrace');
      emit(TaskError('Failed to clear tasks: $e'));
    }
  }
}