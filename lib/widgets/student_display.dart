import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/class_data.dart';
import '../utils/excel_utils.dart';
import '../utils/file_manager.dart';
import 'package:path/path.dart' as path;

class StudentDisplay extends StatefulWidget {
  const StudentDisplay({
    Key? key,
  }) : super(key: key);

  @override
  State<StudentDisplay> createState() => _StudentDisplayState();
}

class _StudentDisplayState extends State<StudentDisplay> {
  Map<String, dynamic> excelData = {};
  bool isLoading = false;
  String? errorMessage;
  int currentStudentIndex = 0;
  List<Map<String, dynamic>> students = [];
  Map<String, dynamic> metadata = {};

  @override
  void initState() {
    super.initState();
    // Add listener to FileManager
    final fileManager = Provider.of<FileManager>(context, listen: false);
    fileManager.addListener(_onFileManagerChanged);

    // Initial load if a file is already selected
    if (fileManager.hasSelected) {
      _loadSelectedFile();
    }
  }

  void _onFileManagerChanged() {
    print("FileManager changed, triggering reload."); // Added Logging
    if (mounted) { // Check if the widget is still mounted
       _loadSelectedFile();
    } else {
      print("Widget not mounted, skipping reload.");
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadSelectedFile() async {
    if (!mounted) {
      print("_loadSelectedFile: Widget not mounted, skipping load.");
      return;
    }

    final fileManager = Provider.of<FileManager>(context, listen: false);
    if (!fileManager.hasSelected) {
      print("_loadSelectedFile: No file selected.");
      setState(() {
        isLoading = false;
        students = [];
        metadata = {};
        currentStudentIndex = 0;
        errorMessage = 'الرجاء تحديد قسم أولاً.';
      });
      return;
    }

    final selectedFile = fileManager.selectedFile;
    if (selectedFile == null) {
      print("_loadSelectedFile: Selected file is null.");
      setState(() {
        isLoading = false;
        students = [];
        metadata = {};
        currentStudentIndex = 0;
        errorMessage = 'ملف غير صالح أو غير محدد.';
      });
      return;
    }

    final filePath = selectedFile.filePath;
    print("_loadSelectedFile: Loading file: $filePath");

    // Prevent concurrent loading
    if (isLoading) {
      print("_loadSelectedFile: Already loading, skipping.");
      return;
    }

    setState(() {
      isLoading = true;
      students = [];
      metadata = {};
      currentStudentIndex = 0;
      errorMessage = ''; // Use empty string instead of null
    });

    try {
      // Check if file exists
      final file = File(filePath);
      if (!await file.exists()) {
        print("_loadSelectedFile: File doesn't exist: $filePath");
        throw Exception('الملف المحدد غير موجود.');
      }

      // Check file extension
      final ext = filePath.split('.').last.toLowerCase();
      if (!['xlsx', 'xls', 'ods'].contains(ext)) {
        print("_loadSelectedFile: Unsupported file format: $ext");
        throw Exception('تنسيق ملف غير مدعوم.');
      }

      // Read Excel file
      print("_loadSelectedFile: Reading Excel file");
      final excelResult = await ExcelUtils.readExcel(filePath);
      
      // If widget is unmounted during async operation, stop processing
      if (!mounted) return;

      // Process results - focus only on student names data
      List<Map<String, dynamic>> studentList = [];
      if (excelResult.containsKey('data') && excelResult['data'] is List) {
        for (final student in excelResult['data'] as List) {
          if (student is Map) {
            studentList.add(Map<String, dynamic>.from(student));
          }
        }
      }

      setState(() {
        students = studentList;
        isLoading = false;
        currentStudentIndex = 0;
      });

      print("_loadSelectedFile: Loaded ${students.length} students successfully");
      
      // If no students were found, show an error
      if (students.isEmpty) {
        setState(() {
          errorMessage = 'لم يتم العثور على بيانات طلاب في الملف المحدد.';
        });
      }
    } catch (e, stackTrace) {
      print("_loadSelectedFile: Error: $e");
      print("Stack trace: $stackTrace");
      
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'فشل تحميل الملف: ${e.toString()}';
          students = [];
          metadata = {};
          currentStudentIndex = 0;
        });
      }
    }
  }

  void nextStudent() {
    if (students.isEmpty) return;
    
    setState(() {
      currentStudentIndex = (currentStudentIndex + 1) % students.length;
    });
  }

  void previousStudent() {
    if (students.isEmpty) return;
    
    setState(() {
      if (currentStudentIndex > 0) {
        currentStudentIndex--;
      } else {
        // Loop to the last student
        currentStudentIndex = students.length - 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final fileManager = Provider.of<FileManager>(context);
    final size = MediaQuery.of(context).size;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    if (!fileManager.hasSelected) {
      return Center(
        child: Text(
          'الرجاء اختيار فصل لعرض الطلاب',
          textDirection: TextDirection.rtl,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: size.width * 0.04,
          ),
        ),
      );
    }
    
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'جاري تحميل بيانات الطلاب...',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: size.width * 0.04,
              ),
            ),
          ],
        ),
      );
    }
    
    if (errorMessage != null && errorMessage!.isNotEmpty) {
      return Center(
        child: Text(
          errorMessage!,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            color: Colors.red,
            fontSize: size.width * 0.04,
          ),
        ),
      );
    }
    
    if (students.isEmpty) {
      return Center(
        child: Text(
          'لا يوجد طلاب في هذا الفصل',
          textDirection: TextDirection.rtl,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: size.width * 0.04,
          ),
        ),
      );
    }

    final currentStudent = students[currentStudentIndex];
    
    // Use a more adaptive layout based on orientation
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2A2D3E),
            Color(0xFF1F1F2C),
          ],
        ),
      ),
      child: SafeArea(
        child: isLandscape 
          // Landscape layout - horizontal arrangement
          ? Row(
              children: [
                // Left side - class and student info
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // Use minimum space needed
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Class info
                        Container(
                          width: double.infinity,
                          margin: EdgeInsets.only(bottom: 10),
                          padding: EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF373B4D).withOpacity(0.9),
                                Color(0xFF373B4D).withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'القسم: ',
                                  style: TextStyle(
                                    color: Colors.yellow[300],
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: '${fileManager.selectedFile!.className}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Student name
                        Flexible(
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF2A2D3E).withOpacity(0.95),
                                  Color(0xFF2A2D3E).withOpacity(0.85),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.blue.withOpacity(0.3)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min, // Minimize height
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'إسم التلميذ',
                                  style: TextStyle(
                                    color: Colors.yellow[300],
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Flexible(
                                  child: SingleChildScrollView(
                                    child: Text(
                                      currentStudent['name'] ?? 'غير معروف',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Right side - student number and navigation
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // Use minimum space needed
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Student number
                        Flexible(
                          child: Container(
                            width: double.infinity,
                            margin: EdgeInsets.only(bottom: 10),
                            padding: EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.blue.withOpacity(0.3),
                                  Colors.blue.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'رقم: ${currentStudentIndex + 1}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Navigation
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.blue.withOpacity(0.2),
                                Colors.purple.withOpacity(0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton(
                                onPressed: previousStudent, // Always enabled
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.1),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  minimumSize: Size(50, 36), // Slightly larger buttons
                                ),
                                child: Text(
                                  'السابق',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${currentStudentIndex + 1} / ${students.length}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: nextStudent, // Always enabled
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.1),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  minimumSize: Size(50, 36), // Slightly larger buttons
                                ),
                                child: Text(
                                  'التالي',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          // Portrait layout - vertical arrangement (original)
          : Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: size.width * 0.05, vertical: size.height * 0.02),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Class number
                          Container(
                            width: double.infinity,
                            margin: EdgeInsets.symmetric(vertical: size.height * 0.01),
                            padding: EdgeInsets.symmetric(
                              vertical: size.height * 0.02,
                              horizontal: size.width * 0.05,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF373B4D).withOpacity(0.9),
                                  Color(0xFF373B4D).withOpacity(0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'القسم: ',
                                    style: TextStyle(
                                      color: Colors.yellow[300],
                                      fontSize: size.width * 0.055,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '${fileManager.selectedFile!.className}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: size.width * 0.055,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: size.height * 0.02),
                          // Student name card
                          Container(
                            width: double.infinity,
                            margin: EdgeInsets.symmetric(vertical: size.height * 0.01),
                            padding: EdgeInsets.all(size.width * 0.05),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF2A2D3E).withOpacity(0.95),
                                  Color(0xFF2A2D3E).withOpacity(0.85),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.blue.withOpacity(0.3)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'إسم التلميذ',
                                  style: TextStyle(
                                    color: Colors.yellow[300],
                                    fontSize: size.width * 0.045,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: size.height * 0.015),
                                Text(
                                  currentStudent['name'] ?? 'غير معروف',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: size.width * 0.06,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: size.height * 0.025),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: size.height * 0.015,
                                    horizontal: size.width * 0.08,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.blue.withOpacity(0.3),
                                        Colors.blue.withOpacity(0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'رقم: ${currentStudentIndex + 1}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: size.width * 0.07,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: size.height * 0.03),
                          // Navigation
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: size.width * 0.05,
                              vertical: size.height * 0.015,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.blue.withOpacity(0.2),
                                  Colors.purple.withOpacity(0.2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                TextButton(
                                  onPressed: previousStudent, // Always enabled
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.white.withOpacity(0.1),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: size.width * 0.05,
                                      vertical: size.height * 0.01,
                                    ),
                                  ),
                                  child: Text(
                                    'السابق',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: size.width * 0.04,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: size.width * 0.03,
                                    vertical: size.height * 0.01,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${currentStudentIndex + 1} / ${students.length}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: size.width * 0.04,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: nextStudent, // Always enabled
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.white.withOpacity(0.1),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: size.width * 0.05,
                                      vertical: size.height * 0.01,
                                    ),
                                  ),
                                  child: Text(
                                    'التالي',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: size.width * 0.04,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
      ),
    );
  }
} 