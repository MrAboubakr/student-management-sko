import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/class_data.dart';
import '../utils/file_manager.dart';
import '../widgets/student_display.dart';
import '../main.dart'; // Import for AppColors
import 'package:path/path.dart' as path;

// Colors used in the app
class AppColors {
  static const Color background = Color.fromARGB(255, 22, 32, 65);
  static const Color primary = Color.fromARGB(255, 47, 50, 90);
  static const Color secondary = Color(0xFF6B533B);
  static const Color accent = Color(0xFF99C100);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool showFileList = false;
  
  @override
  void initState() {
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    final fileManager = Provider.of<FileManager>(context);
    final hasFiles = fileManager.uploadedFiles.isNotEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Smart Caller'),
          backgroundColor: Color(0xFF1E2038),
          elevation: 4,
          shadowColor: Colors.black45,
          centerTitle: false,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(15),
            ),
          ),
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: Color(0xFFDE6E00)),
          actions: [
            IconButton(
              icon: const Icon(Icons.upload_file),
              tooltip: 'إضافة فصل جديد',
              color: const Color(0xFFDE6E00),
              onPressed: _showUploadDialog,
            ),
            IconButton(
              icon: Icon(
                showFileList ? Icons.list_alt : Icons.list,
                color: showFileList ? Colors.green : const Color(0xFFDE6E00),
              ),
              tooltip: showFileList ? 'إخفاء قائمة الفصول' : 'إدارة الفصول',
              onPressed: () {
                setState(() {
                  showFileList = !showFileList;
                });
              },
            ),
          ],
        ),
        body: hasFiles ? _buildWithClasses(fileManager) : _buildEmptyState(),
      ),
    );
  }

  Widget _buildEmptyState() {
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Color(0xFFDE6E00).withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFDE6E00).withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.upload_file,
                size: 64,
                color: Color(0xFFDE6E00),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF373B4D).withOpacity(0.7),
                    Color(0xFF373B4D).withOpacity(0.5),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Text(
                'لم يتم إضافة أي فصل بعد',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text(
                'إضافة فصل جديد',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFDE6E00),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
                shadowColor: Color(0xFFDE6E00).withOpacity(0.5),
              ),
              onPressed: _showUploadDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWithClasses(FileManager fileManager) {
    return Column(
      children: [
        // Class selection UI (displayed when showFileList is true)
        if (showFileList)
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2A2D3E),
                  Color(0xFF1F1F2C),
                ],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFDE6E00),
                        Color(0xFFC95E00),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(8),
                  width: double.infinity,
                  child: const Text(
                    'الفصول المتاحة',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: fileManager.uploadedFiles.length,
                    itemBuilder: (context, index) {
                      final file = fileManager.uploadedFiles[index];
                      final isSelected = index == fileManager.selectedIndex;
                      
                      return Card(
                        color: isSelected 
                            ? Color(0xFFDE6E00).withOpacity(0.7)
                            : Colors.black.withOpacity(0.2),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected 
                              ? Color(0xFFDE6E00) 
                              : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        elevation: isSelected ? 4 : 1,
                        child: ListTile(
                          leading: Icon(
                            Icons.class_,
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                          title: Text(
                            file.className,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            file.filePath.split('/').last,
                            style: TextStyle(
                              color: isSelected ? Colors.black54 : Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          selected: isSelected,
                          onTap: () => fileManager.selectFile(index),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  color: isSelected ? Colors.green : const Color.fromARGB(179, 255, 255, 255),
                                ),
                                tooltip: 'تعديل',
                                onPressed: () => _showEditDialog(index, file),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  color: isSelected ? const Color.fromARGB(255, 255, 0, 0) : Colors.white70,
                                ),
                                tooltip: 'حذف',
                                onPressed: () => fileManager.removeFile(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        
        // Student Display takes the remaining space
        Expanded(
          child: StudentDisplay(),
        ),
      ],
    );
  }

  void _showUploadDialog() {
    String className = '';
    // Create a TextEditingController to handle pasted values
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2A2D3E),
                Color(0xFF1F1F2C),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Color(0xFFDE6E00).withOpacity(0.5),
              width: 2,
            ),
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'إضافة فصل جديد',
                style: TextStyle(
                  color: Color(0xFFDE6E00),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'اسم الفصل',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintText: 'مثال: 1أ، 2ب، الصف الثالث',
                  hintStyle: TextStyle(color: Colors.white30),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Color(0xFFDE6E00).withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Color(0xFFDE6E00)),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                ),
                style: TextStyle(color: Colors.white),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                onChanged: (value) {
                  className = value;
                },
                // Enable paste operation
                enableInteractiveSelection: true,
                keyboardType: TextInputType.text,
                // Auto-focus on the text field
                autofocus: true,
                // Allow multiline input for flexibility
                maxLines: null,
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                    ),
                    child: Text('إلغاء'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Get the final value from the controller
                      className = controller.text.trim();
                      
                      if (className.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('يرجى إدخال اسم الفصل'),
                            backgroundColor: Colors.red.shade800,
                          ),
                        );
                        return;
                      }
                      
                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['xlsx', 'xls', 'ods'],
                      );
                      
                      if (result != null) {
                        String filePath = result.files.single.path!;
                        final fileManager = Provider.of<FileManager>(context, listen: false);
                        fileManager.addFile(ClassData(
                          className: className,
                          filePath: filePath,
                        ));
                        
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          setState(() {
                            showFileList = false;
                          });
                          
                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('تم إضافة الفصل بنجاح'),
                              backgroundColor: Color(0xFF99C100),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFDE6E00),
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'اختيار ملف Excel',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(int index, ClassData file) {
    // Create a TextEditingController with the initial class name
    final TextEditingController controller = TextEditingController(text: file.className);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2A2D3E),
                Color(0xFF1F1F2C),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Color(0xFFDE6E00).withOpacity(0.5),
              width: 2,
            ),
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'تعديل اسم الفصل',
                style: TextStyle(
                  color: Color(0xFFDE6E00),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'اسم الفصل',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Color(0xFFDE6E00).withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Color(0xFFDE6E00)),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                ),
                style: TextStyle(color: Colors.white),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                // Enable paste operation
                enableInteractiveSelection: true,
                // Auto-focus and select all text
                autofocus: true,
                keyboardType: TextInputType.text,
                // Allow multiline input
                maxLines: null,
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                    ),
                    child: Text('إلغاء'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Get value directly from controller
                      final className = controller.text.trim();
                      
                      if (className.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('يرجى إدخال اسم الفصل'),
                            backgroundColor: Colors.red.shade800,
                          ),
                        );
                        return;
                      }
                      
                      final fileManager = Provider.of<FileManager>(context, listen: false);
                      fileManager.updateClassName(index, className);
                      Navigator.of(context).pop();
                      
                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم تحديث اسم الفصل بنجاح'),
                          backgroundColor: Color(0xFF99C100),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFDE6E00),
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'حفظ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 