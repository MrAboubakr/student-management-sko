import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/file_manager.dart';
import '../models/class_data.dart';

class ClassFileList extends StatelessWidget {
  const ClassFileList({super.key});

  @override
  Widget build(BuildContext context) {
    final fileManager = Provider.of<FileManager>(context);
    final files = fileManager.uploadedFiles;
    
    return Column(
      children: [
        Container(
          color: Theme.of(context).colorScheme.primaryContainer,
          padding: const EdgeInsets.all(8.0),
          child: const Row(
            children: [
              Icon(Icons.folder_open),
              SizedBox(width: 8),
              Text(
                'Uploaded Classes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: files.isEmpty
              ? const Center(
                  child: Text('No files uploaded yet'),
                )
              : ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    final isSelected = index == fileManager.selectedIndex;
                    
                    return Card(
                      elevation: isSelected ? 4 : 1,
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      child: ListTile(
                        leading: Icon(
                          Icons.description,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        title: Text(
                          file.className,
                          style: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          file.filePath.split('/').last,
                          style: const TextStyle(fontSize: 12),
                        ),
                        selected: isSelected,
                        onTap: () {
                          fileManager.selectFile(index);
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditDialog(context, index, file),
                              tooltip: 'Edit Class Name',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => fileManager.removeFile(index),
                              tooltip: 'Remove File',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context, int index, ClassData file) {
    final TextEditingController controller = TextEditingController(text: file.className);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Class Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Class Name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Provider.of<FileManager>(context, listen: false).updateClassName(
                  index,
                  controller.text,
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
} 