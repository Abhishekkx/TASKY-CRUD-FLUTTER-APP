import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crud_app/data/models/task.dart';

class ApiService {
  static const String _baseUrl = 'https://jsonplaceholder.typicode.com';

  Future<List<Task>> fetchTasks() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/todos'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .asMap()
            .entries
            .map((entry) => Task(
          id: entry.value['id'],
          title: entry.value['title'],
          description: 'Sample description for ${entry.value['title']}',
          status: entry.value['completed'],
          createdDate: DateTime.now().subtract(Duration(days: entry.key)),
          priority: (entry.key % 3) + 1,
        ))
            .toList();
      } else {
        throw Exception('Failed to fetch tasks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Task> createTask(Task task) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/todos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(task.toJson()..remove('id')),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Task.fromJson({
          ...data,
          'createdDate': task.createdDate.toIso8601String(),
          'priority': task.priority,
        });
      } else {
        throw Exception('Failed to create task: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Task> updateTask(Task task) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/todos/${task.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(task.toJson()),
      );
      if (response.statusCode == 200) {
        return task; // JSONPlaceholder returns updated data
      } else {
        throw Exception('Failed to update task: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/todos/$id'));
      if (response.statusCode != 200) {
        throw Exception('Failed to delete task: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}