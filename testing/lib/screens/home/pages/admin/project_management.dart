import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:testing/screens/home/pages/projects/project_screen.dart';

class AllProjectsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Projects'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('projects').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No projects available'));
          }

          final projects = snapshot.data!.docs;

          return ListView.builder(
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      project['image'] ?? '',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProjectScreen(project: project),
                        ),
                      );
                    },
                    child: Text(
                      project['title'] ?? 'Untitled',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.green),
                        onPressed: () {
                          _editProjectDialog(context, project);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _deleteProject(project, context);  // Pass context to show the SnackBar
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _editProjectDialog(BuildContext context, DocumentSnapshot projectSnapshot) {
    TextEditingController titleController = TextEditingController(text: projectSnapshot['title'] ?? '');
    TextEditingController descriptionController = TextEditingController(text: projectSnapshot['description'] ?? '');
    TextEditingController durationController = TextEditingController(text: projectSnapshot['duration'] ?? '');
    TextEditingController materialController = TextEditingController(text: projectSnapshot['materials'] ?? '');
    TextEditingController categoryController = TextEditingController(text: projectSnapshot['category'] ?? '');
    List<String> steps = (projectSnapshot['instructions'] as String).split('\n');
    String selectedDifficulty = projectSnapshot['difficulty'] ?? 'Easy';
    File? imageFile;
    String? imageUrl = projectSnapshot['image'];

    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Project'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: InputDecoration(labelText: 'Title'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: descriptionController,
                        decoration: InputDecoration(labelText: 'Description'),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: durationController,
                        decoration: InputDecoration(labelText: 'Duration'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a duration';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: materialController,
                        decoration: InputDecoration(labelText: 'Materials'),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the materials';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: categoryController,
                        decoration: InputDecoration(labelText: 'Category'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a category';
                          }
                          return null;
                        },
                      ),
                      Column(
                        children: steps.asMap().entries.map((entry) {
                          int index = entry.key;
                          String step = entry.value;
                          return Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: step,
                                  decoration: InputDecoration(labelText: 'Step ${index + 1}'),
                                  onChanged: (value) {
                                    steps[index] = value;
                                  },
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  steps.removeAt(index);
                                  setState(() {}); // Update the UI to reflect the change
                                },
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          steps.add('');
                          setState(() {}); // Update the UI to reflect the change
                        },
                        child: Text('Add Step'),
                      ),
                      DropdownButtonFormField<String>(
                        value: selectedDifficulty,
                        items: ['Easy', 'Medium', 'Hard'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            selectedDifficulty = newValue!;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Select Difficulty',
                        ),
                      ),
                      SizedBox(height: 20),
                      imageUrl != null && imageFile == null
                          ? Column(
                              children: [
                                Image.network(
                                  imageUrl,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                                SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () async {
                                    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
                                    if (pickedImage != null) {
                                      imageFile = File(pickedImage.path);
                                      setState(() {}); // Update the UI to reflect the change
                                    }
                                  },
                                  child: Text('Replace Image'),
                                ),
                              ],
                            )
                          : imageFile != null
                              ? Column(
                                  children: [
                                    Image.file(
                                      imageFile!,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                    SizedBox(height: 10),
                                    ElevatedButton(
                                      onPressed: () async {
                                        final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
                                        if (pickedImage != null) {
                                          imageFile = File(pickedImage.path);
                                          setState(() {}); // Update the UI to reflect the change
                                        }
                                      },
                                      child: Text('Replace Image'),
                                    ),
                                  ],
                                )
                              : IconButton(
                                  onPressed: () async {
                                    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
                                    if (pickedImage != null) {
                                      imageFile = File(pickedImage.path);
                                      setState(() {}); // Update the UI to reflect the change
                                    }
                                  },
                                  icon: Icon(Icons.camera_alt),
                                  iconSize: 50,
                                  color: Colors.black,
                                ),
                    ],
                  ),
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      // Update Firestore
                      await FirebaseFirestore.instance
                          .collection('projects')
                          .doc(projectSnapshot.id)
                          .update({
                        'title': titleController.text,
                        'description': descriptionController.text,
                        'duration': durationController.text,
                        'materials': materialController.text,
                        'category': categoryController.text,
                        'instructions': steps.join('\n'),
                        'difficulty': selectedDifficulty,
                      });

                      // Handle image upload if needed
                      if (imageFile != null) {
                        final storageRef = FirebaseStorage.instance.ref().child('project_images/${projectSnapshot.id}');
                        await storageRef.putFile(imageFile!);
                        final newImageUrl = await storageRef.getDownloadURL();
                        await FirebaseFirestore.instance
                            .collection('projects')
                            .doc(projectSnapshot.id)
                            .update({'image': newImageUrl});
                      }
                    

                    // Show success SnackBar
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Project updated successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );


                      Navigator.of(context).pop();
                    }
                  },
                  child: Text('Save'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteProject(DocumentSnapshot projectSnapshot, BuildContext context) async {
  try {
    // Attempt to delete the project from Firestore
    await FirebaseFirestore.instance.collection('projects').doc(projectSnapshot.id).delete();

    // Optionally, delete the associated image from Firebase Storage if there's an image
    if (projectSnapshot['image'] != null) {
      final storageRef = FirebaseStorage.instance.refFromURL(projectSnapshot['image']);
      await storageRef.delete();
    }

    // Show success SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Project deleted successfully!'),
        backgroundColor: Colors.red,
      ),
    );
  } catch (error) {
    // Show error SnackBar if something goes wrong
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to delete project: $error'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

}
