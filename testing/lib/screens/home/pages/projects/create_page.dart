import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class CreatePage extends StatefulWidget {
  const CreatePage({Key? key}) : super(key: key);

  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _materialController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _categoryController = TextEditingController();

  List<String> _steps = [];
  String? _selectedDifficulty;
  File? _imageFile;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _materialController.dispose();
    _instructionsController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? file = await imagePicker.pickImage(source: ImageSource.gallery);

    if (file == null) return;

    String uniqueFileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference referenceRoot = FirebaseStorage.instance.ref();
    Reference referenceDirImages = referenceRoot.child('images');
    Reference referenceImageToUpload = referenceDirImages.child(uniqueFileName);

    try {
      await referenceImageToUpload.putFile(File(file.path));
      setState(() {
        _imageFile = File(file.path);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image uploaded successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (error) {
      print("Error uploading image: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image. Please try again.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _addStep(String step) {
    setState(() {
      _steps.add(step);
      _instructionsController.clear(); // Clear the text input field after adding
    });
  }

  String _formatInstructions() {
    List<String> numberedSteps = [];
    for (int i = 0; i < _steps.length; i++) {
      numberedSteps.add('${i + 1}. ${_steps[i]}');
    }
    return numberedSteps.join('\n'); // Join all steps into a single string
  }

  Future<String> _uploadImage(File imageFile) async {
    String uniqueFileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference referenceRoot = FirebaseStorage.instance.ref();
    Reference referenceDirImages = referenceRoot.child('images');
    Reference referenceImageToUpload = referenceDirImages.child(uniqueFileName);

    try {
      await referenceImageToUpload.putFile(imageFile);
      return await referenceImageToUpload.getDownloadURL();
    } catch (error) {
      print("Error uploading image: $error");
      throw Exception('Failed to upload image');
    }
  }

  Future<void> _replaceImage() async {
    await _pickAndUploadImage(); // Call image picker to select a new image
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Change background to light grey
      appBar: AppBar(
        title: Text('Create Page'),
        backgroundColor: Colors.blue[700], // Darker shade for the app bar
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create your project',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    SizedBox(height: 20),

                    // Title TextField
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // Description TextField
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: null, // Allow multiple lines
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // Duration TextField
                    TextFormField(
                      controller: _durationController,
                      decoration: InputDecoration(
                        labelText: 'Duration',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter the duration';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // Materials TextField
                    TextFormField(
                      controller: _materialController,
                      maxLines: null, // Allow multiple lines
                      decoration: InputDecoration(
                        labelText: 'Materials',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter materials';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // Category TextField
                    TextFormField(
                      controller: _categoryController,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a category';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // Instructions TextField with step handling
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Instructions:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        TextFormField(
                          controller: _instructionsController,
                          decoration: InputDecoration(
                            labelText: 'Enter step here',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onFieldSubmitted: (value) {
                            _addStep(value);
                          },
                        ),
                        SizedBox(height: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _steps.asMap().entries.map((entry) {
                            int index = entry.key;
                            String step = entry.value;
                            return Row(
                              children: [
                                Expanded(
                                  child: Text('${index + 1}. $step'),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _steps.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Difficulty Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedDifficulty,
                      items: ['Easy', 'Medium', 'Hard'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedDifficulty = newValue;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Difficulty',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please select a difficulty level';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // Image Picker with preview
                    GestureDetector(
                      onTap: _replaceImage,
                      child: _imageFile == null
                          ? Container(
                              height: 150,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.grey,
                                  width: 2,
                                ),
                                color: Colors.white,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.camera_alt,
                                        size: 50, color: Colors.grey),
                                    SizedBox(height: 10),
                                    Text(
                                      'Tap to add an image',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.file(
                                _imageFile!,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                    SizedBox(height: 20),

                    // Submit Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 30.0),
                        backgroundColor: Colors.blue[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();

                          try {
                            // If there's an image, upload it
                            String? image;
                            if (_imageFile != null) {
                              image = await _uploadImage(_imageFile!);
                            }

                            // Create a map to hold the project data
                            Map<String, dynamic> projectData = {
                              'title': _titleController.text,
                              'description': _descriptionController.text,
                              'duration': _durationController.text,
                              'materials': _materialController.text,
                              'category': _categoryController.text,
                              'instructions': _formatInstructions(),
                              'difficulty': _selectedDifficulty,
                              'image': image, // Add image if image was uploaded
                              'createdAt': FieldValue.serverTimestamp(), // To store the creation time
                              'average_rating': 0.0,
                            };

                            // Save the project to Firestore
                            await FirebaseFirestore.instance.collection('projects').add(projectData);

                            // Show success SnackBar
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Project created successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );

                            // Clear form after successful submission
                            _titleController.clear();
                            _descriptionController.clear();
                            _durationController.clear();
                            _materialController.clear();
                            _instructionsController.clear();
                            _categoryController.clear();
                            setState(() {
                              _steps.clear();
                              _selectedDifficulty = null;
                              _imageFile = null;
                            });

                          } catch (error) {
                            // Show failure SnackBar
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to create project. Please try again.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            print('Error creating project: $error');
                          }
                        }
                      },
                      child: Center(
                        child: Text(
                          'Create Project',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
