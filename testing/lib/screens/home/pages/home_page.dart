import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:testing/screens/home/pages/account/profile_page.dart';
import 'package:testing/screens/home/pages/projects/project_screen.dart';
import 'package:testing/screens/home/pages/projects/search_project.dart';
import 'package:testing/screens/home/pages/projects/wishlist_page.dart';
import '../../authenticate/main_page.dart';
import 'projects/create_page.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CollectionReference fetchData = FirebaseFirestore.instance.collection("projects");
  final user = FirebaseAuth.instance.currentUser!;
  bool showAllProjects = false;
  final ScrollController _scrollController = ScrollController();
  int selectedCategoryIndex = 0;
  List<String> recommendations = [];
  int _selectedIndex = 0;

  Future<void> _refreshData() async {
    // Refresh projects and recommendations
    await fetchRecommendations(user.uid);
    setState(() {
      // Trigger any other state updates required for a complete refresh
    });
  }

  final List<Widget> _pages = [
    HomePage(),
    SearchProject(),
    WishlistPage(),
    ProfilePage(),
  ];


  @override
  void initState() {
    super.initState();
    fetchRecommendations(user.uid);
  }

  Future<void> fetchRecommendations(String userId) async {
    final response = await http.get(Uri.parse('http://192.168.0.159:5001/recommendations/$userId'));
    if (response.statusCode == 200) {
      setState(() {
        recommendations = List<String>.from(json.decode(response.body)['recommendations']);
      });
    } else {
      print('Failed to load recommendations');
    }
  }

  Future<String?> fetchImageUrl(String title) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('projects')
          .where('title', isEqualTo: title)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final imageUrl = doc['image']; // Assuming your Firestore document has an 'imageUrl' field
        return imageUrl;
      }
    } catch (e) {
      print('Error fetching image URL: $e');
    }
    return null;
  }

  void addToWishlistByTitle(String title) async {
    try {
      final projectQuery = await FirebaseFirestore.instance
          .collection('projects')
          .where('title', isEqualTo: title)
          .get();

      if (projectQuery.docs.isNotEmpty) {
        final project = projectQuery.docs.first;
        addToWishlist(project);
      } else {
        print('Project not found');
      }
    } catch (e) {
      print('Error adding to wishlist: $e');
    }
  }

  void removeFromWishlistByTitle(String title) async {
    try {
      final wishlistRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('wishlist');

      final wishlistQuery = await wishlistRef.where('title', isEqualTo: title).get();

      for (var doc in wishlistQuery.docs) {
        await doc.reference.delete();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Removed from Wishlist')));
      }
    } catch (e) {
      print('Error removing from wishlist: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to remove from Wishlist')));
    }
  }



  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }



  void addToWishlist(DocumentSnapshot project) {
    String projectId = project.id;
    String title = project['title'];
    CollectionReference wishlistRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('wishlist');
    wishlistRef.add({
      'projectId': projectId,
      'title': title,
    }).then((value) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added to Wishlist')));
    }).catchError((error) {
      print('Error adding to wishlist: $error');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add to Wishlist')));
    });
  }

  void removeFromWishlist(DocumentSnapshot project) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wishlist')
        .where('projectId', isEqualTo: project.id)
        .get()
        .then((querySnapshot) {
      for (var doc in querySnapshot.docs) {
        doc.reference.delete().then((_) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Removed from Wishlist')));
        });
      }
    }).catchError((error) {
      print('Error removing from wishlist: $error');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to remove from Wishlist')));
    });
  }

  bool isProjectInWishlist(DocumentSnapshot project, List<DocumentSnapshot> wishlist) {
    return wishlist.any((element) => element['projectId'] == project.id);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => _pages[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Home',
          style: TextStyle(
           fontFamily: 'Lexend Deca',
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.grey[900],
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut().then((_) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => MainPage()),
                  (route) => false,
                );
              });
            },
          ),
        ],
      ),
      body: LiquidPullToRefresh(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildCategorySelector(),
              Padding(
                padding: EdgeInsets.all(15),
                child: Column(
                  children: [
                    _buildProjectsSection(),
                    SizedBox(height: 20),
                    _buildRecommendationsSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: Padding(
  padding: const EdgeInsets.only(bottom: 10.0), // Adjust the bottom padding as needed
  child: FloatingActionButton(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CreatePage()),
      );
    },
    child: Icon(Icons.add),
  ),
),
      bottomNavigationBar: Padding(
  padding: EdgeInsets.symmetric(horizontal: 0.0),
  child: Container(
    width: MediaQuery.of(context).size.width,
    decoration: BoxDecoration(
      color: Colors.black,
      boxShadow: [
        BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(.1)),
      ],
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
          onPressed: () => _onItemTapped(0),
        ),
        GButton(
          icon: Icons.search,
          text: 'Search',
          onPressed: () => _onItemTapped(1),
        ),
        GButton(
          icon: Icons.favorite_border,
          text: 'Wishlist',
          onPressed: () => _onItemTapped(2),
        ),
        GButton(
          icon: Icons.person,
          text: 'Account',
          onPressed: () => _onItemTapped(3),
        ),
      ],
      selectedIndex: _selectedIndex,
      onTabChange: _onItemTapped,
    ),
  ),
),

    );
  }

  Widget _buildHeader() {
  return FutureBuilder<DocumentSnapshot>(
    future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
    builder: (context, snapshot) {
      String greeting = 'Hello';
      if (snapshot.connectionState == ConnectionState.done) {
        if (snapshot.hasData && snapshot.data!.exists) {
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          greeting = 'Welcome back ${userData['name']}!';
        } else {
          greeting = 'Hi there';
        }
      } else if (snapshot.connectionState == ConnectionState.waiting) {
        greeting = 'Loading...';
      }

      return Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  greeting,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    wordSpacing: 2,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.person),
                  color: Colors.white,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfilePage()),
                    );
                  },
                ),
              ],
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: 20),
              width: MediaQuery.of(context).size.width,
              height: 55,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextFormField(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SearchProject()),
                  );
                },
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "Search here...",
                  hintStyle: TextStyle(
                    color: Colors.black.withOpacity(0.5),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 25,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}



  Widget _buildCategorySelector() {
    return FutureBuilder<List<String>>(
      future: fetchCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error loading categories');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Text('No categories found');
        }

        List<String> catNames = snapshot.data!;
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          height: 100, // Adjust based on your design requirements
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: catNames.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChoiceChip(
                  label: Text(catNames[index]),
                  selected: selectedCategoryIndex == index,
                  onSelected: (selected) {
                    setState(() {
                      selectedCategoryIndex = index;
                    });
                  },
                  selectedColor: Colors.blue, // Customize as needed
                ),
              );
            },
          ),
        );
      },
    );
  }

   Future<List<String>> fetchCategories() async {
    try {
      QuerySnapshot querySnapshot = await fetchData.get();
      Set<String> categories = {};
      for (var doc in querySnapshot.docs) {
        categories.add(doc['category']);
      }
      return ['All']..addAll(categories.toList())..sort(); // Insert "All" and sort
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  Widget _buildProjectsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Projects",
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w600,
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  showAllProjects = !showAllProjects;
                });
              },
              child: Text(
                showAllProjects ? "Show Less" : "View All",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.purple,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        FutureBuilder<List<String>>(
          future: fetchCategories(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error loading categories');
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Text('No categories found');
            }

            List<String> catNames = snapshot.data!;
            String selectedCategory = catNames[selectedCategoryIndex];

            // Always include "All" in the category list
            catNames.insert(0, "All");

            return StreamBuilder<QuerySnapshot>(
              stream: fetchData.snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Something went wrong');
                }
                final projects = snapshot.data!.docs;

                // Filter projects based on the selected category
                List<DocumentSnapshot> filteredProjects;
                if (selectedCategory == "All") {
                  filteredProjects = projects; // Show all projects
                } else {
                  filteredProjects = projects.where((project) {
                    return project['category'] == selectedCategory;
                  }).toList();
                }

                if (filteredProjects.isEmpty) {
                  return Text('No projects found in this category');
                }

                // Determine the number of projects to display based on showAllProjects
                int displayCount = showAllProjects ? filteredProjects.length : (filteredProjects.length > 1 ? 2 : filteredProjects.length);

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('wishlist')
                      .snapshots(),
                  builder: (context, wishlistSnapshot) {
                    if (wishlistSnapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    }
                    final wishlist = wishlistSnapshot.data!.docs;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1,
                      ),
                      itemCount: displayCount,
                      itemBuilder: (context, index) {
                        final project = filteredProjects[index];
                        bool isAddedToWishlist = isProjectInWishlist(project, wishlist);
                        return ProjectItem(
                          project: project,
                          isAddedToWishlist: isAddedToWishlist,
                          onWishlistPressed: () {
                            if (isAddedToWishlist) {
                              removeFromWishlist(project);
                            } else {
                              addToWishlist(project);
                            }
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

Widget _buildRecommendationsSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "Recommendations",
        style: TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.w600,
        ),
      ),
      SizedBox(height: 10),
      recommendations.isEmpty
          ? Center(child: Text('No recommendations available'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('projects') // Adjust the collection path as necessary
                  .where('title', whereIn: recommendations)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Failed to load projects');
                }

                final projects = snapshot.data?.docs ?? [];

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    final data = project.data() as Map<String, dynamic>?; // Cast to Map
                    final isAddedToWishlist = data?['wishlist'] != null; // Check for 'wishlist'

                    return ListTile(
                      leading: project['image'] != null
                          ? Image.network(
                              project['image'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                          : Icon(Icons.image, size: 50),
                      title: Text(project['title']),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProjectScreen(project: project),
                          ),
                        );
                      },
                      trailing: IconButton(
                        icon: Icon(
                          isAddedToWishlist ? Icons.favorite : Icons.favorite_border,
                          color: isAddedToWishlist ? Colors.red : null,
                        ),
                        onPressed: () {
                          if (isAddedToWishlist) {
                            removeFromWishlistByTitle(project['title']);
                          } else {
                            addToWishlistByTitle(project['title']);
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
    ],
  );
}






}




class ProjectItem extends StatelessWidget {
  final DocumentSnapshot project;
  final bool isAddedToWishlist;
  final VoidCallback onWishlistPressed;

  const ProjectItem({
    Key? key,
    required this.project,
    required this.isAddedToWishlist,
    required this.onWishlistPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectScreen(project: project),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.all(8),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: project['image'] != null
                      ? Hero(
                          tag: 'projectImage-${project.id}',
                          child: Image.network(
                            project['image'],
                            width: 100,
                            height: 70,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          width: 100,
                          height: 70,
                          color: Colors.grey,
                          child: Center(child: Text('No image available')),
                        ),
                ),
                SizedBox(height: 10),
                Text(
                  project['title'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Icon(
                  isAddedToWishlist ? Icons.favorite : Icons.favorite_border,
                  color: isAddedToWishlist ? Colors.red : null,
                ),
                onPressed: onWishlistPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


