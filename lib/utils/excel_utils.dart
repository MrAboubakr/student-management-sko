import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';

class ExcelUtils {
  static Future<String> convertExcelToCSV(String excelFilePath) async {
    try {
      var bytes = File(excelFilePath).readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);
      
      if (excel.tables.isEmpty) {
        throw Exception("Excel file has no sheets!");
      }

      var sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null) {
        throw Exception("First sheet is empty!");
      }

      List<List<dynamic>> csvData = [];
      for (var row in sheet.rows) {
        List<dynamic> csvRow = [];
        for (var cell in row) {
          csvRow.add(cell?.value?.toString() ?? '');
        }
        csvData.add(csvRow);
      }

      String csv = const ListToCsvConverter().convert(csvData);
      final directory = await getTemporaryDirectory();
      final csvFilePath = '${directory.path}/converted_data.csv';
      await File(csvFilePath).writeAsString(csv);
      return csvFilePath;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> readExcel(String filePath) async {
    print("ExcelUtils.readExcel: Starting to read file from: $filePath");
    
    // Check if file exists
    final file = File(filePath);
    if (!await file.exists()) {
      print("ExcelUtils.readExcel: File does not exist at path: $filePath");
      throw Exception("الملف غير موجود في المسار المحدد");
    }

    try {
      final List<Map<String, dynamic>> students = [];
      
      // Read file bytes
      print("ExcelUtils.readExcel: Reading file bytes");
      final bytes = await file.readAsBytes();
      
      // Parse Excel
      print("ExcelUtils.readExcel: Decoding Excel bytes");
      final excel = Excel.decodeBytes(bytes);
      
      if (excel.tables.isEmpty) {
        print("ExcelUtils.readExcel: Excel file has no sheets");
        throw Exception("ملف الإكسل لا يحتوي على أوراق");
      }
      
      // Log available sheets
      final sheetNames = excel.tables.keys.toList();
      print("ExcelUtils.readExcel: Available sheets: ${sheetNames.join(', ')}");
      
      // Variables to track what we find
      String selectedSheetName = "";
      int nameColumnIndex = -1;
      int idColumnIndex = -1;
      int headerRowIndex = -1;
      
      // Examine each sheet to find the student data
      for (final sheetName in sheetNames) {
        final sheet = excel.tables[sheetName];
        if (sheet == null || sheet.maxRows == 0) continue;
        
        print("ExcelUtils.readExcel: Analyzing sheet: $sheetName");
        
        // Search through rows for a header-like row
        for (int rowIndex = 0; rowIndex < min(30, sheet.maxRows); rowIndex++) {
          final row = sheet.rows[rowIndex];
          if (row.isEmpty) continue;
          
          // Print this row for debugging
          final rowContent = row.map((cell) => cell?.value?.toString() ?? '').toList();
          print("ExcelUtils.readExcel: Row $rowIndex content: $rowContent");
          
          // Look for student name and ID columns
          for (int colIndex = 0; colIndex < row.length; colIndex++) {
            final cell = row[colIndex];
            if (cell?.value == null) continue;
            
            String cellValue = '';
            // Handle different Excel cell value types
            if (cell!.value is String) {
              cellValue = cell.value.toString().trim();
            } else {
              cellValue = cell.value.toString().trim();
            }
            
            print("ExcelUtils.readExcel: Checking cell [$rowIndex,$colIndex] = '$cellValue'");
            
            // Check for name column header - right side of the table (RTL layout)
            if (cellValue == "إسم التلميذ" || 
                cellValue == "اسم التلميذ" || 
                cellValue == "إسم الطالب" || 
                cellValue == "اسم الطالب") {
              print("ExcelUtils.readExcel: FOUND NAME COLUMN HEADER: '$cellValue' at [$rowIndex,$colIndex]");
              nameColumnIndex = colIndex;
              headerRowIndex = rowIndex;
            }
            
            // Check for ID column header (likely leftmost column in RTL layout)
            if (cellValue == "رقم التلميذ" || 
                cellValue == "رقم الطالب" ||
                cellValue == "الرقم" ||
                cellValue == "رقم") {
              print("ExcelUtils.readExcel: FOUND ID COLUMN HEADER: '$cellValue' at [$rowIndex,$colIndex]");
              idColumnIndex = colIndex;
            }
          }
          
          // If we found both name and ID columns, we have our header row
          if (nameColumnIndex != -1) {
            selectedSheetName = sheetName;
            break;
          }
        }
        
        if (nameColumnIndex != -1) break;
      }
      
      // If we didn't find the name column, try looking specifically for the column with "إسم التلميذ"
      if (nameColumnIndex == -1) {
        print("ExcelUtils.readExcel: Could not find name column header, searching for content similar to 'إسم التلميذ'");
        
        for (final sheetName in sheetNames) {
          final sheet = excel.tables[sheetName];
          if (sheet == null || sheet.maxRows == 0) continue;
          
          // Try to find any cell that contains "التلميذ" or "الطالب" which would indicate the name column
          for (int rowIndex = 0; rowIndex < min(10, sheet.maxRows); rowIndex++) {
            final row = sheet.rows[rowIndex];
            
            for (int colIndex = 0; colIndex < row.length; colIndex++) {
              final cell = row[colIndex];
              if (cell?.value == null) continue;
              
              final cellValue = cell!.value.toString().trim();
              
              if (cellValue.contains("التلميذ") || 
                  cellValue.contains("الطالب") || 
                  cellValue.contains("إسم") || 
                  cellValue.contains("اسم")) {
                print("ExcelUtils.readExcel: Found potential name column with: '$cellValue' at [$rowIndex,$colIndex]");
                nameColumnIndex = colIndex;
                headerRowIndex = rowIndex;
                selectedSheetName = sheetName;
                break;
              }
              
              // Also check for ID column in case it helps
              if (cellValue.contains("رقم")) {
                print("ExcelUtils.readExcel: Found potential ID column with: '$cellValue' at [$rowIndex,$colIndex]");
                idColumnIndex = colIndex;
              }
            }
            
            if (nameColumnIndex != -1) break;
          }
          
          if (nameColumnIndex != -1) break;
        }
      }
      
      // Last resort - if we can't find a name column, check the rightmost column for Arabic text 
      // (since in RTL layouts, names are often on the right)
      if (nameColumnIndex == -1) {
        print("ExcelUtils.readExcel: Last resort - looking for Arabic text in rightmost columns");
        selectedSheetName = sheetNames.first;
        headerRowIndex = 0; // Assume first row is header
        
        final sheet = excel.tables[selectedSheetName]!;
        if (sheet.rows.isNotEmpty && sheet.rows[0].isNotEmpty) {
          // Try to find any row with Arabic text (likely student names)
          for (int rowIndex = 1; rowIndex < min(20, sheet.maxRows); rowIndex++) {
            final row = sheet.rows[rowIndex];
            if (row.isEmpty) continue;
            
            // Check rightmost cells first (RTL layout puts names on the right)
            for (int colIndex = row.length - 1; colIndex >= 0; colIndex--) {
              final cell = row[colIndex];
              if (cell?.value == null) continue;
              
              final cellValue = cell!.value.toString().trim();
              
              // If this cell has Arabic text and looks like a name
              if (cellValue.contains(RegExp(r'[\u0600-\u06FF]')) && cellValue.length > 3) {
                print("ExcelUtils.readExcel: Found Arabic text in rightmost columns: '$cellValue' at [$rowIndex,$colIndex]");
                nameColumnIndex = colIndex;
                
                // Look for potential ID column (could be the leftmost column with text)
                for (int idCol = 0; idCol < row.length; idCol++) {
                  if (row[idCol]?.value != null) {
                    final idValue = row[idCol]!.value.toString().trim();
                    if (idValue.isNotEmpty && idValue != cellValue) {
                      idColumnIndex = idCol;
                      print("ExcelUtils.readExcel: Potential ID column found at index $idCol with value '$idValue'");
                      break;
                    }
                  }
                }
                
                break;
              }
            }
            
            if (nameColumnIndex != -1) break;
          }
        }
      }
      
      if (selectedSheetName.isEmpty || nameColumnIndex == -1 || headerRowIndex == -1) {
        throw Exception("لم يتم العثور على أعمدة أسماء الطلاب في الملف");
      }
      
      print("ExcelUtils.readExcel: Using sheet '$selectedSheetName', name column $nameColumnIndex, ID column $idColumnIndex, header row $headerRowIndex");
      
      // Process the sheet with student data
      final sheet = excel.tables[selectedSheetName]!;
      
      // Extract student names and IDs
      for (int rowIndex = headerRowIndex + 1; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.rows[rowIndex];
        if (row.isEmpty || nameColumnIndex >= row.length) continue;
        
        // Skip rows that don't have a value in the name column
        if (row[nameColumnIndex]?.value == null) continue;
        
        // Extract name
        final name = row[nameColumnIndex]!.value.toString().trim();
        if (name.isEmpty) continue;
        
        // Extract ID if available (otherwise use row number)
        String id = (rowIndex - headerRowIndex).toString(); // Default to row number if no ID found
        if (idColumnIndex != -1 && idColumnIndex < row.length && row[idColumnIndex]?.value != null) {
          id = row[idColumnIndex]!.value.toString().trim();
        }
        
        print("ExcelUtils.readExcel: Found student - Name: '$name', ID: '$id'");
        
        students.add({
          'name': name,
          'id': id,
        });
      }
      
      print("ExcelUtils.readExcel: Extracted ${students.length} students");
      
      if (students.isEmpty) {
        throw Exception("لم يتم العثور على أسماء طلاب في الملف");
      }
      
      return {
        'data': students,
        'count': students.length,
        'success': true
      };
    } catch (e, stackTrace) {
      print("ExcelUtils.readExcel: Error while reading Excel file: $e");
      print("Stack trace: $stackTrace");
      throw Exception("حدث خطأ أثناء قراءة الملف: $e");
    }
  }

  static int min(int a, int b) {
    return a < b ? a : b;
  }
} 
