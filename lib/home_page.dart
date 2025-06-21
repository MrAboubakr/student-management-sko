import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'utils/excel_utils.dart';
import 'package:path/path.dart' as path;

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, dynamic>> students = [];
  int currentIndex = 0;
  String className = '';
  bool isLoading = false;
  String? error;
  bool debugMode = true; // Set to true to enable debugging info

  Future<void> uploadExcel() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Open file picker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null) {
        String? filePath = result.files.single.path;
        if (filePath != null) {
          // Process the Excel file
          Map<String, dynamic> data = await ExcelUtils.readExcel(filePath);
          List<Map<String, dynamic>> students = data['students'];
          
          if (students.isEmpty) {
            setState(() {
              isLoading = false;
              error = "لم يتم العثور على طلاب في الملف!";
            });
            return;
          }

          setState(() {
            this.students = students;
            className = path.basename(filePath).replaceAll(RegExp(r'\.\w+$'), '');
            currentIndex = 0;
            isLoading = false;
          });
        }
      } else {
        // User canceled file picking
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
        error = "خطأ: ${e.toString()}";
        
        // More user-friendly error message for the missing column
        if (e.toString().contains("Column 'اسم التلميذ' not found")) {
          error = "لم يتم العثور على عمود 'اسم التلميذ' في الملف. الرجاء التأكد من صيغة الملف!";
        }
      });
    }
  }

  void nextStudent() {
    if (currentIndex < students.length - 1) {
      setState(() {
        currentIndex++;
      });
    }
  }

  void previousStudent() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الصف: $className'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          if (debugMode)
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: () {
                if (students.isNotEmpty) {
                  print("Current student: ${students[currentIndex]}");
                }
              },
              tooltip: 'Debug Info',
            ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: uploadExcel,
            tooltip: 'Upload Excel File',
          ),
        ],
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        const Text('Error loading Excel file', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(error!, textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Try Again'),
                          onPressed: uploadExcel,
                        ),
                      ],
                    ),
                  ),
                )
              : students.isEmpty 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_file, size: 64, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: 16),
                          const Text('No students available'),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Upload Excel File'),
                            onPressed: uploadExcel,
                          ),
                        ],
                      ),
                    )
                  : _buildStudentView(),
    );
  }
  
  Widget _buildStudentView() {
    if (currentIndex >= students.length) {
      return const Center(child: Text('Invalid student index'));
    }
    
    final student = students[currentIndex];
    final name = student['name']?.toString() ?? 'Unknown';
    final id = student['id']?.toString() ?? 'N/A';
    
    // Get additional data (all keys except name and id)
    final additionalData = <MapEntry<String, dynamic>>[];
    student.forEach((key, value) {
      if (key != 'name' && key != 'id' && value != null && value.toString().trim().isNotEmpty) {
        additionalData.add(MapEntry(key, value));
      }
    });
    
    return Column(
      children: [
        Container(
          color: Colors.orange,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.orange,
                child: Text(
                  className,
                  style: const TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.bold,
                    color: Colors.white
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.brown,
                child: const Text(
                  'القسم',
                  style: TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.bold,
                    color: Colors.white
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Name section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 300,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      color: Colors.orange,
                      alignment: Alignment.center,
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 28, 
                          fontWeight: FontWeight.bold,
                          color: Colors.white
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Colors.brown,
                      child: const Text(
                        'الاسم',
                        style: TextStyle(
                          fontSize: 24, 
                          fontWeight: FontWeight.bold,
                          color: Colors.white
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // ID section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.lightGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.orange, width: 3),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        id,
                        style: const TextStyle(
                          fontSize: 32, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Colors.brown,
                      child: const Text(
                        'الرقم',
                        style: TextStyle(
                          fontSize: 24, 
                          fontWeight: FontWeight.bold,
                          color: Colors.white
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Additional info
                if (additionalData.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    padding: const EdgeInsets.all(8),
                    color: Colors.orange,
                    child: const Text(
                      'معلومات إضافية',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  // Display other fields
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: additionalData.length,
                      itemBuilder: (context, index) {
                        if (index < additionalData.length) {
                          final entry = additionalData[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.brown.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${entry.value}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }
                        return Container();
                      }
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        
        // Navigation bar
        Container(
          color: Colors.orange,
          padding: const EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: currentIndex > 0 ? previousStudent : null,
                child: const Text('السابق', style: TextStyle(fontSize: 18)),
              ),
              Text(
                '${currentIndex + 1} / ${students.length}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: currentIndex < students.length - 1 ? nextStudent : null,
                child: const Text('التالي', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 