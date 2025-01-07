import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:testing/screens/authenticate/main_page.dart';
import 'package:testing/screens/home/pages/home_page.dart';
import 'package:testing/screens/home/pages/projects/search_project.dart';
import 'package:testing/screens/home/pages/projects/wishlist_page.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser!;
  late DocumentReference userRef;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  File? pickedImageFile;
  int _selectedIndex = 3;

  Future<void> _handleRefresh() async {
    // You can add any refresh logic here
    await Future.delayed(Duration(seconds: 2)); // Simulating a delay for the refresh action
  }

  @override
  void initState() {
    super.initState();
    userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    _nameController = TextEditingController();
    _emailController = TextEditingController();
  }

  Future<void> selectImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        pickedImageFile = File(pickedImage.path);
      });
      _showPreviewDialog();
    }
  }

  Future<void> uploadFile() async {
    if (pickedImageFile == null) return;

    final path = 'profile_pictures/${user.uid}.jpg';
    final file = pickedImageFile!;

    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      await ref.putFile(file);

      final String imageUrl = await ref.getDownloadURL();
      await userRef.update({'imageUrl': imageUrl});

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile picture uploaded successfully!')));
    } catch (e) {
      print('Error uploading profile picture: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload profile picture.')));
    }
  }

  Future<void> _logout() async {
  try {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainPage()), // Navigate to AuthPage or login page
    );
  } catch (e) {
    print('Error signing out: $e');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to log out')));
  }
}


  void _showPreviewDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Preview Profile Picture'),
          content: CircleAvatar(
            radius: 50,
            backgroundImage: FileImage(pickedImageFile!),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                uploadFile();
              },
              child: Text('Upload'),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog() {
  TextEditingController _passwordController = TextEditingController();
  bool _passwordVisible = false;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Change Password'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return TextField(
              controller: _passwordController,
              obscureText: !_passwordVisible,
              decoration: InputDecoration(
                hintText: 'Enter new password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _passwordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _passwordVisible = !_passwordVisible;
                    });
                  },
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _changePassword(_passwordController.text);
              Navigator.of(context).pop();
            },
            child: Text('Change'),
          ),
        ],
      );
    },
  );
}


void _changePassword(String newPassword) async {
  try {
    await user.updatePassword(newPassword);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password changed successfully')));
  } catch (e) {
    print('Error changing password: $e');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to change password')));
  }
}


  void _updateUserData() {
    userRef.update({
      'name': _nameController.text,
      'email': _emailController.text,
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Name updated')));
    }).catchError((error) {
      print('Error updating profile: $error');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update profile')));
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  return WillPopScope(
    onWillPop: () async {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
      return true;
    },
    child: Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text(
          'Profile Page',
          style: TextStyle(
            fontFamily: 'Lexend Deca',
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          },
          color: Colors.white,
        ),
        actions: [
            MaterialButton(
              onPressed: _logout,
              child: Icon(Icons.logout),
            ),
          ],
      ),
      body: LiquidPullToRefresh(
        onRefresh: _handleRefresh,
        child: StreamBuilder<DocumentSnapshot>(
          stream: userRef.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error fetching user data', style: TextStyle(color: Colors.white)));
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(child: Text('User data not found', style: TextStyle(color: Colors.white)));
            }

            var userData = snapshot.data!;
            Map<String, dynamic>? userMap = userData.data() as Map<String, dynamic>?;
            _nameController.text = userMap?['name'] ?? '';
            _emailController.text = userMap?['email'] ?? '';
            String? imageUrl = userMap != null && userMap.containsKey('imageUrl') ? userMap['imageUrl'] : null;

            return SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 40),
                  GestureDetector(
                    onTap: selectImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: pickedImageFile != null
                          ? FileImage(pickedImageFile!)
                          : imageUrl != null
                              ? NetworkImage(imageUrl) as ImageProvider
                              : null,
                      child: pickedImageFile == null && imageUrl == null
                          ? Icon(Icons.camera_alt, size: 50, color: Colors.white)
                          : null,
                      backgroundColor: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 20),
                  MyTextBox(
                      text: _nameController.text,
                      sectionName: 'Name',
                      onPressed: () => _showEditDialog('Name', _nameController)),
                  MyTextBox(
                      text: _emailController.text,
                      sectionName: 'Email',
                      onPressed: () => _showEditDialog('Email', _emailController)),
                  MyTextBox(
                      text: '******', // Display masked password
                      sectionName: 'Password',
                      onPressed: () => _showChangePasswordDialog(),
                  ),
                  SizedBox(height: 20),
                  MaterialButton(
                      onPressed: _logout,
                      color: Colors.red,
                      child: Text('Logout', style: TextStyle(color: Colors.white)),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: Colors.black,
          boxShadow: [BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(.1))],
        ),
        child: GNav(
          backgroundColor: Colors.black,
          color: Colors.white,
          activeColor: Colors.white,
          tabBackgroundColor: Colors.grey.shade800,
          gap: 8,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          tabs: [
            GButton(
                icon: Icons.home,
                text: 'Home',
                onPressed: () =>
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()))),
            GButton(
                icon: Icons.search,
                text: 'Search',
                onPressed: () =>
                    Navigator.push(context, MaterialPageRoute(builder: (context) => SearchProject()))),
            GButton(
                icon: Icons.favorite,
                text: 'Wishlist',
                onPressed: () =>
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => WishlistPage()))),
            GButton(icon: Icons.person, text: 'Account', onPressed: () {}),
          ],
          selectedIndex: _selectedIndex,
          onTabChange: (index) => setState(() => _selectedIndex = index),
        ),
      ),
    ),
  );
}


  void _showEditDialog(String sectionName, TextEditingController controller) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit $sectionName'),
          content: TextField(controller: controller, decoration: InputDecoration(hintText: 'Enter $sectionName')),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancel')),
            TextButton(onPressed: () { Navigator.of(context).pop(); _updateUserData(); }, child: Text('Save')),
          ],
        );
      },
    );
  }
}

class MyTextBox extends StatelessWidget {
  final String text;
  final String sectionName;
  final void Function()? onPressed;

  const MyTextBox({Key? key, required this.text, required this.sectionName, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
      padding: EdgeInsets.all(15),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(sectionName, style: TextStyle(color: Colors.grey[600])),
            SizedBox(height: 5),
            Text(text, style: TextStyle(color: Colors.black)),
          ]),
          IconButton(onPressed: onPressed, icon: Icon(Icons.edit, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
