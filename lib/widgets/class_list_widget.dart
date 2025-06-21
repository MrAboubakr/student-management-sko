import 'package:flutter/material.dart';
import '../utils/file_manager.dart';
import '../models/class_data.dart';

class ClassListWidget extends StatelessWidget {
  final FileManager fileManager;
  final Function(int, dynamic)? showEditDialog;

  const ClassListWidget({
    Key? key, 
    required this.fileManager,
    this.showEditDialog,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2A2D3E),
            Color(0xFF1F1F2C),
          ],
        ),
        boxShadow: [
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
            decoration: const BoxDecoration(
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
                      ? const Color(0xFFDE6E00).withOpacity(0.7)
                      : Colors.black.withOpacity(0.2),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected 
                        ? const Color(0xFFDE6E00) 
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
                    onTap: () {
                      fileManager.selectFile(index);
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            color: isSelected ? Color.fromARGB(255, 24, 130, 0) : const Color.fromARGB(179, 255, 255, 255),
                          ),
                          tooltip: 'تعديل',
                          onPressed: () {
                            // We need to call the edit dialog from the HomeScreen
                            // This will be handled through a callback
                            showEditDialog?.call(index, file);
                          },
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
    );
  }
} 