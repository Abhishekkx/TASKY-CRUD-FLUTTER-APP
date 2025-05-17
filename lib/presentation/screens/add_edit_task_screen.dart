import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:crud_app/data/models/task.dart';
import 'package:crud_app/logic/blocs/task_bloc.dart';
import 'package:crud_app/logic/events/task_event.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class AddEditTaskScreen extends StatefulWidget {
  final Task? task;

  const AddEditTaskScreen({super.key, this.task});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late bool _status;
  late int _priority;
  DateTime? _dueDate;
  final Logger _logger = Logger();
  bool _isSubmitting = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.task?.description ?? '');
    _status = widget.task?.status ?? false;
    _priority = widget.task?.priority ?? 1;
    _dueDate = widget.task?.dueDate;
    _logger.i('Initialized AddEditTaskScreen for ${widget.task == null ? "adding" : "editing"} task with id: ${widget.task?.id}');

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
    _logger.i('AddEditTaskScreen disposed');
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dueDate ?? DateTime.now()),
      );
      if (pickedTime != null) {
        setState(() {
          _dueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _scheduleVibration(Task task) async {
    if (task.dueDate == null || task.id == null) return;

    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_channel',
      'Task Reminders',
      channelDescription: 'Notifications for task reminders',
      importance: Importance.max,
      priority: Priority.high,
      playSound: false,
      enableVibration: true,
    );
    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentSound: false,
      presentAlert: true,
      presentBadge: true,
    );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    // Convert DateTime to TZDateTime
    final scheduledDate = tz.TZDateTime.from(task.dueDate!, tz.local);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      task.id!,
      'Task Reminder: ${task.title}',
      'Your task "${task.title}" is due now!',
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    _logger.i('Scheduled vibration for task ${task.id} at ${task.dueDate}');
  }

  Future<void> _submit() async {
    _logger.i('Attempting to submit form');
    if (!_formKey.currentState!.validate()) {
      _logger.w('Form validation failed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all required fields'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    _logger.i('Form validated successfully');
    setState(() {
      _isSubmitting = true;
    });

    try {
      final task = Task(
        id: widget.task?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        status: _status,
        createdDate: widget.task?.createdDate ?? DateTime.now(),
        priority: _priority,
        dueDate: _dueDate,
      );
      _logger.i('Submitting task: ${task.title} (id: ${task.id}, createdDate: ${task.createdDate}, dueDate: ${task.dueDate})');

      if (widget.task == null) {
        _logger.i('Dispatching AddTask event');
        context.read<TaskBloc>().add(AddTask(task));
      } else {
        if (task.id == null) {
          _logger.e('Task ID is null during update');
          throw Exception('Task ID cannot be null for update');
        }
        _logger.i('Dispatching UpdateTask event');
        context.read<TaskBloc>().add(UpdateTask(task));
      }

      await _scheduleVibration(task);

      _logger.i('Showing success snackbar');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Task "${task.title}" ${widget.task == null ? "added" : "updated"}',
            ),
            backgroundColor: Colors.teal,
          ),
        );
      }

      _logger.i('Navigating back to TaskListScreen');
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        _logger.w('Cannot pop, widget not mounted or no route to pop');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const TaskListScreen(),
              settings: const RouteSettings(name: 'TaskListScreen'),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      _logger.e('Error submitting task: $e\nStackTrace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      _logger.i('Submission process completed');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _logger.i('Building AddEditTaskScreen');
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Add Task' : 'Edit Task'),
        elevation: 4,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.teal, Colors.white],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _titleController,
                                  decoration: const InputDecoration(
                                    labelText: 'Title',
                                    prefixIcon:
                                    Icon(Icons.title, color: Colors.teal),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter a title';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _descriptionController,
                                  decoration: const InputDecoration(
                                    labelText: 'Description',
                                    prefixIcon: Icon(Icons.description,
                                        color: Colors.teal),
                                  ),
                                  maxLines: 3,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter a description';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<int>(
                                  value: _priority,
                                  decoration: const InputDecoration(
                                    labelText: 'Priority',
                                    prefixIcon: Icon(Icons.priority_high,
                                        color: Colors.teal),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 1, child: Text('Low')),
                                    DropdownMenuItem(
                                        value: 2, child: Text('Medium')),
                                    DropdownMenuItem(
                                        value: 3, child: Text('High')),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _priority = value!;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                ListTile(
                                  title: Text(
                                    _dueDate == null
                                        ? 'Set Reminder'
                                        : 'Reminder: ${DateFormat('yyyy-MM-dd HH:mm').format(_dueDate!)}',
                                  ),
                                  trailing: const Icon(Icons.calendar_today, color: Colors.teal),
                                  onTap: () => _selectDueDate(context),
                                ),
                                const SizedBox(height: 16),
                                CheckboxListTile(
                                  title: const Text('Completed'),
                                  value: _status,
                                  onChanged: (value) {
                                    setState(() {
                                      _status = value!;
                                    });
                                  },
                                  activeColor: Colors.teal,
                                  checkColor: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _isSubmitting
                            ? const Center(child: CircularProgressIndicator())
                            : ScaleTransition(
                          scale: _scaleAnimation,
                          child: ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              minimumSize:
                              Size(constraints.maxWidth, 50),
                            ),
                            child: Text(widget.task == null
                                ? 'Add Task'
                                : 'Update Task'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}