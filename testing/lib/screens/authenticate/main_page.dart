import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:testing/screens/home/pages/admin/admin_page.dart'; // Import your AdminPage
import 'package:testing/screens/home/pages/home_page.dart'; // Import your HomePage
import 'package:testing/screens/authenticate/auth_pages/auth_page.dart';

class MainPage extends StatelessWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (authSnapshot.hasData) {
          return _buildUserRolePage(context, authSnapshot.data!);
        } else {
          return AuthPage(); // Navigate to AuthPage (Login/Register)
        }
      },
    );
  }

  Widget _buildUserRolePage(BuildContext context, User user) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (userSnapshot.hasError) {
          return Center(child: Text('Error fetching user data: ${userSnapshot.error}'));
        }

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          bool isBanned = userSnapshot.data!.get('banned') ?? false;
          if (isBanned) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Your account is banned.'),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _logout(context),
                    child: Text('Go to Login Page'),
                  ),
                ],
              ),
            );
          }

          String? userRole = userSnapshot.data!.get('role');
          if (userRole == 'Admin') {
            return AdminPage(); // Navigate to AdminPage
          } else {
            return HomePage(); // Navigate to HomePage
          }
        } else {
          return Center(child: Text('User data not found'));
        }
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
  try {
    await FirebaseAuth.instance.signOut();
    // Navigate to AuthPage after the frame has been drawn
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => AuthPage()),
        (Route<dynamic> route) => false, // Remove all previous routes
      );
    });
  } catch (e) {
    print('Error signing out: $e');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to log out')));
  }
}

}
