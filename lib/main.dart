import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import '../../data/services/service_locator.dart';
import 'package:crud_app/logic/blocs/task_bloc.dart';
import 'package:crud_app/logic/blocs/task_state.dart';
import 'package:crud_app/logic/events/task_event.dart';
import 'package:crud_app/presentation/screens/add_edit_task_screen.dart';
import 'package:crud_app/presentation/widgets/task_tile.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

  // Initialize notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  final DarwinInitializationSettings initializationSettingsIOS =
  DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // Handle notification taps
      _logger.i('Notification tapped: ${response.payload}');
    },
  );

  // Request notification permission on Android 13+
  if (Platform.isAndroid) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  setupServiceLocator();
  runApp(const MyApp());
}

final Logger _logger = Logger();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetIt.I<TaskBloc>()..add(LoadTasks()),
      child: MaterialApp(
        title: 'CRUD App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal,
            primary: Colors.teal,
            secondary: Colors.amber,
            surface: Colors.white,
            background: Colors.grey[100]!,
          ),
          scaffoldBackgroundColor: Colors.grey[100],
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            elevation: 2,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
            bodyMedium: TextStyle(fontSize: 14, color: Colors.black54),
            titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: Colors.teal, width: 2),
            ),
          ),
        ),
        home: const TaskListScreen(),
      ),
    );
  }
}

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final Logger _logger = Logger();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _searchQuery = '';
  List<dynamic> _filteredTasks = [];

  @override
  void initState() {
    super.initState();
    _logger.i('Initializing TaskListScreen');
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
    _logger.i('TaskListScreen disposed');
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
        _logger.i('Search query updated: $_searchQuery');
      });
    });
  }

  List<dynamic> _filterTasks(List<dynamic> tasks) {
    if (_searchQuery.isEmpty) {
      return tasks;
    }
    return tasks.where((task) {
      final title = task.title?.toLowerCase() ?? '';
      final description = task.description?.toLowerCase() ?? '';
      return title.contains(_searchQuery) || description.contains(_searchQuery);
    }).toList();
  }

  Future<bool?> _confirmClearTasks() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Tasks'),
        content: const Text('Are you sure you want to delete all tasks? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _logger.i('Building TaskListScreen');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task List'),
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () async {
              final confirm = await _confirmClearTasks();
              if (confirm == true) {
                _logger.i('Clearing all tasks');
                context.read<TaskBloc>().add(ClearTasks());
              }
            },
            tooltip: 'Clear All Tasks',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.teal, Colors.white],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  prefixIcon: const Icon(Icons.search, color: Colors.teal),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
            Expanded(
              child: BlocConsumer<TaskBloc, TaskState>(
                listener: (context, state) {
                  _logger.i('Bloc state changed: ${state.runtimeType}');
                  if (state is TaskLoaded && state.tasks.isNotEmpty) {
                    _logger.i('Tasks loaded, showing snackbar');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tasks loaded successfully'),
                        backgroundColor: Colors.teal,
                      ),
                    );
                  } else if (state is TaskError) {
                    _logger.e('TaskError state: ${state.message}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${state.message}'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  } else if (state is TaskLoaded && state.tasks.isEmpty) {
                    _logger.i('All tasks cleared');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All tasks cleared'),
                        backgroundColor: Colors.teal,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  _logger.i('Building UI for state: ${state.runtimeType}');
                  if (state is TaskInitial) {
                    _logger.i('State is TaskInitial');
                    return const Center(child: Text('Initializing...'));
                  } else if (state is TaskLoading) {
                    _logger.i('State is TaskLoading');
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is TaskError) {
                    _logger.i('State is TaskError: ${state.message}');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Error: ${state.message}',
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              _logger.i('Retry button pressed');
                              context.read<TaskBloc>().add(RetryTasks());
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  } else if (state is TaskLoaded) {
                    _logger.i('State is TaskLoaded with ${state.tasks.length} tasks');
                    _filteredTasks = _filterTasks(state.tasks);
                    if (_filteredTasks.isEmpty) {
                      _logger.i('No tasks found after filtering');
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.task_alt,
                              size: 48,
                              color: Colors.white70,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No tasks found. Add a new task!'
                                  : 'No tasks match your search.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      );
                    }
                    return AnimationLimiter(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _filteredTasks.length,
                        itemBuilder: (context, index) {
                          final task = _filteredTasks[index];
                          if (task.id == null) {
                            _logger.w('Task at index $index has null ID');
                          }
                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 375),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: TaskTile(task: task),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }
                  _logger.w('Unexpected state, falling back to initializing');
                  return const Center(child: Text('Unexpected state, please wait...'));
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _logger.i('FloatingActionButton pressed, navigating to AddEditTaskScreen');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditTaskScreen(),
              settings: const RouteSettings(name: 'AddEditTaskScreen'),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}