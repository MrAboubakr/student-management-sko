import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/class_data.dart';

class DatabaseImplementation {
  static final DatabaseImplementation instance = DatabaseImplementation._init();
  static File? _databaseFile;

  DatabaseImplementation._init();

  Future<File> get databaseFile async {
    if (_databaseFile != null) return _databaseFile!;
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'student_classes.json');
    _databaseFile = File(path);
    if (!await _databaseFile!.exists()) {
      await _databaseFile!.writeAsString('[]');
    }
    return _databaseFile!;
  }

  Future<List<ClassData>> getAllClasses() async {
    try {
      final file = await databaseFile;
      final jsonString = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonString);
      
      return jsonList.map((json) => ClassData(
        className: json['className'],
        filePath: json['filePath'],
      )).toList();
    } catch (e) {
      print('Error reading database: $e');
      return [];
    }
  }

  Future<int> addClass(ClassData classData) async {
    try {
      final file = await databaseFile;
      final jsonString = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonString);
      
      jsonList.add({
        'className': classData.className,
        'filePath': classData.filePath,
        'createdAt': DateTime.now().toIso8601String(),
      });
      
      await file.writeAsString(jsonEncode(jsonList));
      return jsonList.length;
    } catch (e) {
      print('Error adding class: $e');
      return -1;
    }
  }

  Future<int> updateClass(int id, ClassData classData) async {
    try {
      final file = await databaseFile;
      final jsonString = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonString);
      
      if (id > 0 && id <= jsonList.length) {
        jsonList[id - 1] = {
          'className': classData.className,
          'filePath': classData.filePath,
          'createdAt': DateTime.now().toIso8601String(),
        };
        
        await file.writeAsString(jsonEncode(jsonList));
        return 1;
      }
      return 0;
    } catch (e) {
      print('Error updating class: $e');
      return -1;
    }
  }

  Future<int> deleteClass(String filePath) async {
    try {
      final file = await databaseFile;
      final jsonString = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonString);
      
      final initialLength = jsonList.length;
      jsonList.removeWhere((item) => item['filePath'] == filePath);
      
      if (jsonList.length < initialLength) {
        await file.writeAsString(jsonEncode(jsonList));
        return 1;
      }
      return 0;
    } catch (e) {
      print('Error deleting class: $e');
      return -1;
    }
  }

  Future<int> deleteAllClasses() async {
    try {
      final file = await databaseFile;
      await file.writeAsString('[]');
      return 1;
    } catch (e) {
      print('Error deleting all classes: $e');
      return -1;
    }
  }

  Future<void> close() async {
    // No need to close file in this implementation
  }
} 