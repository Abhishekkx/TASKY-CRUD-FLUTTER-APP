import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crud_app/data/models/task.dart';

class DatabaseHelper {
  static const _databaseName = 'crud_app.db';
  static const _databaseVersion = 2;  // Increased version for migration
  static const _tableTasks = 'tasks';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableTasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        status INTEGER NOT NULL,
        createdDate TEXT NOT NULL,
        priority INTEGER NOT NULL,
        dueDate TEXT  -- Added new column
      )
    ''');
    await db.execute('CREATE INDEX idx_createdDate ON $_tableTasks (createdDate)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE $_tableTasks ADD COLUMN dueDate TEXT');
    }
  }

  Future<int> insertTask(Task task) async {
    final db = await database;
    final map = <String, Object?>{
      'title': task.title,
      'description': task.description,
      'status': task.status ? 1 : 0,
      'createdDate': task.createdDate.toIso8601String(),
      'priority': task.priority,
      'dueDate': task.dueDate?.toIso8601String(),
    };
    if (task.id != null) {
      map['id'] = task.id as Object;
    }
    return await db.insert(
      _tableTasks,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Task>> getTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_tableTasks);
    return List.generate(maps.length, (i) {
      return Task(
        id: maps[i]['id'] as int,
        title: maps[i]['title'] as String,
        description: maps[i]['description'] as String,
        status: maps[i]['status'] == 1,
        createdDate: DateTime.parse(maps[i]['createdDate'] as String),
        priority: maps[i]['priority'] as int,
        dueDate: maps[i]['dueDate'] != null
            ? DateTime.parse(maps[i]['dueDate'] as String)
            : null,
      );
    });
  }

  Future<void> deleteTask(int id) async {
    final db = await database;
    await db.delete(_tableTasks, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearTasks() async {
    final db = await database;
    await db.delete(_tableTasks);
  }
}