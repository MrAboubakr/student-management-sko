import '../models/class_data.dart';

// Import the appropriate implementation based on platform
import 'database_impl/mobile_database.dart' if (dart.library.io) 'database_impl/desktop_database.dart' as impl;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  
  DatabaseHelper._init();

  Future<List<ClassData>> getAllClasses() async {
    return impl.DatabaseImplementation.instance.getAllClasses();
  }

  Future<int> addClass(ClassData classData) async {
    return impl.DatabaseImplementation.instance.addClass(classData);
  }

  Future<int> updateClass(int id, ClassData classData) async {
    return impl.DatabaseImplementation.instance.updateClass(id, classData);
  }

  Future<int> deleteClass(String filePath) async {
    return impl.DatabaseImplementation.instance.deleteClass(filePath);
  }

  Future<int> deleteAllClasses() async {
    return impl.DatabaseImplementation.instance.deleteAllClasses();
  }

  Future<void> close() async {
    return impl.DatabaseImplementation.instance.close();
  }
}