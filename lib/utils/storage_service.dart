import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/class_data.dart';
import 'package:excel/excel.dart';

class StorageService {
  static const String _storageKey = 'uploaded_files';

  // Save the list of files to SharedPreferences
  static Future<bool> saveFiles(List<ClassData> files) async {
    final prefs = await SharedPreferences.getInstance();
    final fileDataList = files.map((file) => {
      'filePath': file.filePath,
      'className': file.className,
    }).toList();
    
    final jsonString = jsonEncode(fileDataList);
    return await prefs.setString(_storageKey, jsonString);
  }

  // Load the list of files from SharedPreferences
  static Future<List<ClassData>> loadFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    
    if (jsonString == null) {
      return [];
    }
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => ClassData(
        filePath: json['filePath'],
        className: json['className'],
      )).toList();
    } catch (e) {
      print('Error loading files: $e');
      return [];
    }
  }

  // Clear all saved files
  static Future<bool> clearFiles() async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.remove(_storageKey);
  }

  static Future<Map<String, dynamic>> readExcelBytes(Uint8List bytes) async {
    List<Map<String, dynamic>> students = [];
    int nameColumnIndex = -1;
    Map<String, dynamic> metadata = {};

    try {
      var excel = Excel.decodeBytes(bytes);
      
      if (excel.tables.isEmpty) {
        throw Exception("Excel file has no sheets!");
      }

      // Get all sheet names
      List<String> sheetNames = excel.tables.keys.toList();
      print("Available sheets: ${sheetNames.join(', ')}");

      // Try to find the main data sheet
      String? dataSheetName;
      for (var sheetName in sheetNames) {
        var table = excel.tables[sheetName];
        if (table != null && table.maxRows > 0) {
          // Check if this sheet contains student data
          for (var row in table.rows) {
            for (var cell in row) {
              if (cell?.value != null) {
                String value = cell!.value.toString();
                if (value == "اسم التلميذ" || value == "إسم التلميذ") {
                  dataSheetName = sheetName;
                  break;
                }
              }
            }
            if (dataSheetName != null) break;
          }
        }
        if (dataSheetName != null) break;
      }

      if (dataSheetName == null) {
        throw Exception("Could not find a sheet containing student data!");
      }

      var table = excel.tables[dataSheetName];
      if (table == null || table.maxRows == 0) {
        throw Exception("Selected sheet is empty!");
      }

      // Find the header row (might not be the first row)
      int headerRowIndex = -1;
      for (int rowIndex = 0; rowIndex < table.maxRows; rowIndex++) {
        var row = table.rows[rowIndex];
        for (var cell in row) {
          if (cell?.value != null) {
            String value = cell!.value.toString();
            if (value == "اسم التلميذ" || value == "إسم التلميذ") {
              headerRowIndex = rowIndex;
              break;
            }
          }
        }
        if (headerRowIndex != -1) break;
      }

      if (headerRowIndex == -1) {
        throw Exception("Could not find header row with student name column!");
      }

      // Extract metadata from rows before the header
      if (headerRowIndex > 0) {
        for (int rowIndex = 0; rowIndex < headerRowIndex; rowIndex++) {
          var row = table.rows[rowIndex];
          for (int colIndex = 0; colIndex < row.length; colIndex++) {
            var cell = row[colIndex];
            if (cell?.value != null) {
              String key = "Row${rowIndex + 1}_Col${colIndex + 1}";
              metadata[key] = cell!.value.toString();
            }
          }
        }
      }

      var headerRow = table.rows[headerRowIndex];
      
      // Find the column with either header spelling variation
      for (int colIndex = 0; colIndex < headerRow.length; colIndex++) {
        var cell = headerRow[colIndex];
        if (cell?.value != null) {
          String headerValue = cell!.value.toString();
          if (headerValue == "اسم التلميذ" || headerValue == "إسم التلميذ") {
            nameColumnIndex = colIndex;
            print("Found student name column at index $nameColumnIndex");
            break;
          }
        }
      }
      
      if (nameColumnIndex == -1) {
        throw Exception("Column for student name not found in Excel file!");
      }

      // Get all header names
      Map<int, String> headers = {};
      for (int colIndex = 0; colIndex < headerRow.length; colIndex++) {
        var cell = headerRow[colIndex];
        if (cell?.value != null) {
          headers[colIndex] = cell!.value.toString();
        }
      }

      // Process data rows (skip header row and any metadata rows)
      for (int rowIndex = headerRowIndex + 1; rowIndex < table.maxRows; rowIndex++) {
        var row = table.rows[rowIndex];
        String name = '';
        
        // Get the name from the found column
        if (nameColumnIndex < row.length && row[nameColumnIndex]?.value != null) {
          name = row[nameColumnIndex]!.value.toString().trim();
        }
        
        // Skip rows without a name
        if (name.isEmpty) {
          continue;
        }

        // Create a map for all columns
        Map<String, dynamic> studentData = {'name': name, 'id': rowIndex};

        // Add all other column data
        for (int colIndex = 0; colIndex < row.length; colIndex++) {
          if (colIndex != nameColumnIndex && headers.containsKey(colIndex) && row[colIndex]?.value != null) {
            String value = row[colIndex]!.value.toString().trim();
            if (value.isNotEmpty) {
              studentData[headers[colIndex]!] = value;
            }
          }
        }

        students.add(studentData);
      }

      print("Found ${students.length} students from bytes");
      print("Metadata found: ${metadata.length} items");
      
      return {
        'students': students,
        'nameColumnIndex': nameColumnIndex,
        'metadata': metadata,
        'sheetName': dataSheetName,
      };
    } catch (e) {
      print("Error reading Excel bytes: $e");
      rethrow;
    }
  }
} 