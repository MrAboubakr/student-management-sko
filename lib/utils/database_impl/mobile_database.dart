import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/class_data.dart';

class DatabaseImplementation {
  static final DatabaseImplementation instance = DatabaseImplementation._init();
  static Database? _database;

  DatabaseImplementation._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('student_classes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE classes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        className TEXT NOT NULL,
        filePath TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<List<ClassData>> getAllClasses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'classes',
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return ClassData(
        className: maps[i]['className'],
        filePath: maps[i]['filePath'],
      );
    });
  }

  Future<int> addClass(ClassData classData) async {
    final db = await database;
    return await db.insert(
      'classes',
      {
        'className': classData.className,
        'filePath': classData.filePath,
        'createdAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateClass(int id, ClassData classData) async {
    final db = await database;
    return await db.update(
      'classes',
      {
        'className': classData.className,
        'filePath': classData.filePath,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteClass(String filePath) async {
    final db = await database;
    return await db.delete(
      'classes',
      where: 'filePath = ?',
      whereArgs: [filePath],
    );
  }

  Future<int> deleteAllClasses() async {
    final db = await database;
    return await db.delete('classes');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
} 