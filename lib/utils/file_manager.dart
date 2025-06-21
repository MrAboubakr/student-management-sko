import 'package:flutter/material.dart';
import '../models/class_data.dart';
import 'database_helper.dart';

class FileManager extends ChangeNotifier {
  List<ClassData> _uploadedFiles = [];
  int _selectedIndex = -1;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  List<ClassData> get uploadedFiles => _uploadedFiles;
  int get selectedIndex => _selectedIndex;
  bool get hasSelected => _selectedIndex >= 0 && _selectedIndex < _uploadedFiles.length;
  ClassData? get selectedFile => hasSelected ? _uploadedFiles[_selectedIndex] : null;

  // Initialize - load data from SQLite database
  Future<void> init() async {
    try {
      _uploadedFiles = await _dbHelper.getAllClasses();
      _selectedIndex = _uploadedFiles.isEmpty ? -1 : 0;
      notifyListeners();
    } catch (e) {
      print('Error initializing FileManager: $e');
      _uploadedFiles = [];
      _selectedIndex = -1;
    }
  }

  Future<void> addFile(ClassData fileData) async {
    try {
      await _dbHelper.addClass(fileData);
      _uploadedFiles.add(fileData);
      _selectedIndex = _uploadedFiles.length - 1;
      notifyListeners();
    } catch (e) {
      print('Error adding file: $e');
      // You might want to show an error message to the user here
    }
  }

  Future<void> removeFile(int index) async {
    if (index >= 0 && index < _uploadedFiles.length) {
      try {
        final filePath = _uploadedFiles[index].filePath;
        await _dbHelper.deleteClass(filePath);
        _uploadedFiles.removeAt(index);
        
        if (_selectedIndex == index) {
          _selectedIndex = _uploadedFiles.isEmpty ? -1 : 0;
        } else if (_selectedIndex > index) {
          _selectedIndex--;
        }
        
        notifyListeners();
      } catch (e) {
        print('Error removing file: $e');
        // You might want to show an error message to the user here
      }
    }
  }

  Future<void> updateClassName(int index, String newClassName) async {
    if (index >= 0 && index < _uploadedFiles.length) {
      try {
        final updatedClass = ClassData(
          filePath: _uploadedFiles[index].filePath,
          className: newClassName,
        );
        await _dbHelper.updateClass(index + 1, updatedClass); // index + 1 because SQLite IDs start at 1
        _uploadedFiles[index] = updatedClass;
        notifyListeners();
      } catch (e) {
        print('Error updating class name: $e');
        // You might want to show an error message to the user here
      }
    }
  }

  void selectFile(int index) {
    if (index >= 0 && index < _uploadedFiles.length) {
      _selectedIndex = index;
      notifyListeners();
    }
  }

  // Clean up resources
  @override
  void dispose() {
    _dbHelper.close();
    super.dispose();
  }
} 