import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:testing/screens/home/pages/projects/project_screen.dart';
import 'package:testing/screens/home/pages/projects/search_project.dart';
import '../home_page.dart';
import '../account/profile_page.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({Key? key}) : super(key: key);

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final user = FirebaseAuth.instance.currentUser!;
  final CollectionReference usersRef = FirebaseFirestore.instance.collection('users');
  final CollectionReference projectsRef = FirebaseFirestore.instance.collection('projects');
  int _selectedIndex = 2;

  Future<void> _handleRefresh() async {
    await Future.delayed(Duration(seconds: 2));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text(
          "Wishlist",
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
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: LiquidPullToRefresh(
            onRefresh: _handleRefresh,
            child: StreamBuilder<QuerySnapshot>(
              stream: usersRef.doc(user.uid).collection('wishlist').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Something went wrong', style: TextStyle(color: Colors.white)));
                }
                final wishlistItems = snapshot.data!.docs;
                if (wishlistItems.isEmpty) {
                  return Center(child: Text('Your wishlist is empty', style: TextStyle(color: Colors.white)));
                }
                return ListView.builder(
                  itemCount: wishlistItems.length,
                  itemBuilder: (context, index) {
                    final item = wishlistItems[index];
                    return _buildWishlistItemTile(item);
                  },
                );
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildWishlistItemTile(DocumentSnapshot item) {
    return FutureBuilder<DocumentSnapshot>(
      future: projectsRef.doc(item['projectId']).get(),
      builder: (context, projectSnapshot) {
        if (projectSnapshot.connectionState == ConnectionState.waiting) {
          return ListTile(
            title: Text(item['title'], style: TextStyle(color: Colors.white)),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _removeFromWishlist(item.id);
              },
            ),
          );
        }
        if (projectSnapshot.hasError) {
          return ListTile(
            title: Text(item['title'], style: TextStyle(color: Colors.white)),
            subtitle: Text('Failed to load project details', style: TextStyle(color: Colors.red)),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _removeFromWishlist(item.id);
              },
            ),
          );
        }
        var projectData = projectSnapshot.data;
        return ListTile(
          leading: projectData != null && projectData['image'] != null
              ? Hero(
                  tag: 'projectImage-${item['projectId']}',
                  child: Image.network(
                    projectData['image'],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                )
              : Hero(
                  tag: 'projectImage-${item['projectId']}',
                  child: Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey,
                    child: Icon(Icons.image, color: Colors.white),
                  ),
                ),
          title: Text(item['title'], style: TextStyle(color: Colors.white)),
          onTap: () {
            if (projectSnapshot.hasData && projectSnapshot.data != null) {
              var projectData = projectSnapshot.data!;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProjectScreen(project: projectData),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to load project details.'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          trailing: IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              _removeFromWishlist(item.id);
            },
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
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
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            },
          ),
          GButton(
            icon: Icons.search,
            text: 'Search',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchProject()),
              );
            },
          ),
          GButton(
            icon: Icons.favorite,
            text: 'Wishlist',
            onPressed: () {
              // No action needed since already on the Wishlist screen
            },
          ),
          GButton(
            icon: Icons.person,
            text: 'Account',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
        ],
        selectedIndex: _selectedIndex,
        onTabChange: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  void _removeFromWishlist(String projectId) {
    usersRef
        .doc(user.uid)
        .collection('wishlist')
        .doc(projectId)
        .delete()
        .then((value) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Removed from Wishlist'),
        duration: Duration(seconds: 2),
      ));
    }).catchError((error) {
      print('Error removing from wishlist: $error');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to remove from Wishlist'),
        duration: Duration(seconds: 2),
      ));
    });
  }
}

