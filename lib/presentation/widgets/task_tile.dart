import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crud_app/data/models/task.dart';
import 'package:crud_app/logic/blocs/task_bloc.dart';
import 'package:crud_app/logic/events/task_event.dart';
import 'package:crud_app/presentation/screens/add_edit_task_screen.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

class TaskTile extends StatelessWidget {
  final Task task;

  const TaskTile({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final Logger _logger = Logger();
    _logger.i('Building TaskTile for task: ${task.title} (id: ${task.id})');
    if (task.id == null) {
      _logger.w('Task has null ID, this should not happen');
    }
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Dismissible(
        key: UniqueKey(),
        background: Container(
          color: Colors.redAccent,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Task'),
              content: const Text('Are you sure you want to delete this task?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
        },
        onDismissed: (direction) {
          if (task.id == null) {
            _logger.e('Cannot delete task with null ID');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error: Task ID is missing'),
                backgroundColor: Colors.redAccent,
              ),
            );
            return;
          }
          context.read<TaskBloc>().add(DeleteTask(task.id!));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Task "${task.title}" deleted'),
              backgroundColor: Colors.teal,
            ),
          );
        },
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          leading: task.priority == 3
              ? const Icon(Icons.warning, color: Colors.red, size: 28)
              : null,
          title: Text(
            task.title,
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              fontSize: 18,
              color: Colors.teal[900],
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${task.description}\nCreated: ${DateFormat.yMMMd().format(task.createdDate)}${task.dueDate != null ? '\nDue: ${DateFormat.yMMMd().add_jm().format(task.dueDate!)}' : ''}\nPriority: ${task.priority == 1 ? "Low" : task.priority == 2 ? "Medium" : "High"}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          trailing: Icon(
            task.status ? Icons.check_circle : Icons.circle_outlined,
            color: task.status ? Colors.green : Colors.grey,
            size: 28,
          ),
          onTap: () {
            if (task.id == null) {
              _logger.e('Cannot edit task with null ID');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error: Task ID is missing'),
                  backgroundColor: Colors.redAccent,
                ),
              );
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddEditTaskScreen(task: task),
                settings: const RouteSettings(name: 'AddEditTaskScreen'),
              ),
            );
          },
        ),
      ),
    );
  }
}