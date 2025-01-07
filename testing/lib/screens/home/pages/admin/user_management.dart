import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class AllUsersPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Users'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No users available'));
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final name = user['name'] ?? 'No Name';
              final email = user['email'] ?? 'No Email';
              final imageUrl = user['imageUrl'];
              final banned = user['banned'] ?? false;

              return Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                    child: imageUrl == null ? Icon(Icons.person) : null,
                  ),
                  title: Text(
                    name,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(banned ? Icons.lock : Icons.lock_open, color: Colors.orange),
                        onPressed: () {
                          _toggleBanStatus(context, user, !banned);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.green),
                        onPressed: () {
                          _editUserDialog(context, user);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                        _deleteUser(context, user);
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

  void _toggleBanStatus(BuildContext context, DocumentSnapshot userSnapshot, bool ban) {
    FirebaseFirestore.instance.collection('users').doc(userSnapshot.id).update({
      'banned': ban,
    }).then((value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ban ? 'User successfully banned' : 'User successfully unbanned'),
          backgroundColor: Colors.green,
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update ban status: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }



  void _editUserDialog(BuildContext context, DocumentSnapshot userSnapshot) {
    TextEditingController nameController = TextEditingController(text: userSnapshot['name'] ?? '');
    TextEditingController emailController = TextEditingController(text: userSnapshot['email'] ?? '');
    final ImagePicker _picker = ImagePicker();
    File? imageFile;
    String? imageUrl = userSnapshot['imageUrl'];

    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit User'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(labelText: 'Name'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(labelText: 'Email'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an email';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      imageUrl != null && imageFile == null
                          ? Column(
                              children: [
                                Image.network(
                                  imageUrl!,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                                SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () async {
                                    final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
                                    if (pickedImage != null) {
                                      imageFile = File(pickedImage.path);
                                      setState(() {});
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
                                        final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
                                        if (pickedImage != null) {
                                          imageFile = File(pickedImage.path);
                                          setState(() {});
                                        }
                                      },
                                      child: Text('Replace Image'),
                                    ),
                                  ],
                                )
                              : IconButton(
                                  onPressed: () async {
                                    final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
                                    if (pickedImage != null) {
                                      imageFile = File(pickedImage.path);
                                      setState(() {});
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
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                TextButton(
  onPressed: () async {
    if (_formKey.currentState!.validate()) {
      if (imageFile != null) {
        String uniqueFileName = DateTime.now().millisecondsSinceEpoch.toString();
        String path = 'profile_pictures/$uniqueFileName.jpg';

        final ref = FirebaseStorage.instance.ref().child(path);
        await ref.putFile(imageFile!);

        imageUrl = await ref.getDownloadURL();
      }

      _updateUser(context, userSnapshot, {
        'name': nameController.text,
        'email': emailController.text,
        'imageUrl': imageUrl,
      });

      Navigator.pop(context); // Close the dialog
    }
  },
  child: Text(
    'Save',
    style: TextStyle(color: Colors.green),
  ),
),

              ],
            );
          },
        );
      },
    );
  }

  Future<void> _selectAndReplaceImage(BuildContext context, DocumentSnapshot userSnapshot, File imageFile) async {
    String path = 'profile_pictures/${userSnapshot.id}.jpg'; // Updated path here

    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      await ref.putFile(imageFile);

      String imageUrl = await ref.getDownloadURL();

     _updateUser(context, userSnapshot, {'imageUrl': imageUrl});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User image updated successfully!')),
      );
    } catch (e) {
      print('Error replacing user image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update user image.')),
      );
    }
  }

void _updateUser(BuildContext context, DocumentSnapshot userSnapshot, Map<String, dynamic> updatedData) {
  FirebaseFirestore.instance.collection('users').doc(userSnapshot.id).update(updatedData)
    .then((value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User updated successfully!'),
          backgroundColor: Colors.red,
        ),
      );
    })
    .catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update user: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
}


  void _deleteUser(BuildContext context, DocumentSnapshot userSnapshot) {
  FirebaseFirestore.instance.collection('users').doc(userSnapshot.id).delete()
    .then((value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User deleted successfully'),
          backgroundColor: Colors.red,
        ),
      );
    })
    .catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete user: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
}

}
