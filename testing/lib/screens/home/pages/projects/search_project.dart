import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:testing/screens/home/pages/home_page.dart';
import 'package:testing/screens/home/pages/account/profile_page.dart';
import 'package:testing/screens/home/pages/projects/wishlist_page.dart';
import 'create_page.dart';
import 'project_screen.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class SearchProject extends StatefulWidget {
  const SearchProject({Key? key}) : super(key: key);

  @override
  State<SearchProject> createState() => _SearchProjectState();
}

class _SearchProjectState extends State<SearchProject> {
  final CollectionReference fetchData = FirebaseFirestore.instance.collection("projects");
  final user = FirebaseAuth.instance.currentUser!;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";
  int _selectedIndex = 1;

  String? _selectedCategory;
  String? _selectedDifficulty;

  List<String> _categories = [];
  final List<String> _difficulties = ["Easy", "Medium", "Hard"];


  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchCategories();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchText = _searchController.text.toLowerCase();
    });
  }

  Future<void> _fetchCategories() async {
    QuerySnapshot snapshot = await fetchData.get();
    Set<String> categories = {};
    for (var doc in snapshot.docs) {
      categories.add(doc['category']);
    }
    setState(() {
      _categories = categories.toList();
    });
  }

  Future<void> _refreshProjects() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Colors.grey[400], size: 25),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          },
        ),
        title: Text(
          'Search',
          style: TextStyle(
            fontFamily: 'Lexend Deca',
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: SafeArea(
        top: true,
        child: LiquidPullToRefresh(
          onRefresh: _refreshProjects,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.black,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[800],
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: TextFormField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  labelText: 'Search projects...',
                                  labelStyle: TextStyle(color: Colors.grey[500]),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.transparent, width: 2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.transparent, width: 2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                                ),
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          hint: Text("Category", style: TextStyle(color: Colors.white)),
                          items: _categories.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _selectedCategory = newValue;
                            });
                          },
                          dropdownColor: Colors.grey[800],
                          style: TextStyle(color: Colors.white),
                          iconEnabledColor: Colors.white,
                        ),
                      ),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedDifficulty,
                          hint: Text("Difficulty", style: TextStyle(color: Colors.white)),
                          items: _difficulties.map((String value) {
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
                          dropdownColor: Colors.grey[800],
                          style: TextStyle(color: Colors.white),
                          iconEnabledColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _buildQuery().snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }
                      final projects = snapshot.data!.docs;
                      if (projects.isEmpty) {
                        return Center(
                          child: Text(
                            'No projects found',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: EdgeInsets.zero,
                        primary: false,
                        shrinkWrap: true,
                        scrollDirection: Axis.vertical,
                        itemCount: projects.length,
                        itemBuilder: (context, index) {
                          final project = projects[index];
                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[850],
                                boxShadow: [BoxShadow(blurRadius: 4, color: Color(0x32000000), offset: Offset(0, 2))],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProjectScreen(project: project),
                                    ),
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                                      child: Hero(
                                        tag: 'projectImage-${project.id}',
                                        child: Image.network(
                                          project['image'],
                                          width: double.infinity,
                                          height: 190,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      child: Text(
                                        project['title'],
                                        style: TextStyle(
                                          fontFamily: 'Readex Pro',
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        project['description'],
                                        style: TextStyle(color: Colors.grey[500]),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
                                      child: Row(
                                        children: [
                                          Icon(Icons.star, color: Colors.yellow, size: 24),
                                          SizedBox(width: 4),
                                          Text(
                                            project['average_rating'].toString(),
                                            style: TextStyle(color: Colors.grey[500]),
                                          ),
                                          SizedBox(width: 2),
                                          Text(
                                            'Rating',
                                            style: TextStyle(color: Colors.grey[500]),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreatePage()),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: Colors.black,
          boxShadow: [BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(.1))],
        ),
        child: GNav(
          backgroundColor: Colors.black,
          color: Colors.white,
          activeColor: Colors.black,
          tabBackgroundColor: Colors.white,
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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SearchProject()),
                );
              },
            ),
            GButton(
              icon: Icons.favorite,
              text: 'Wishlist',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WishlistPage()),
                );
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
      ),
    );
  }

  Query _buildQuery() {
    Query query = fetchData;

    if (_searchText.isNotEmpty) {
      query = query
          .orderBy('title')
          .startAt([_searchText])
          .endAt([_searchText + '\uf8ff']);
    }

    if (_selectedCategory != null) {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    if (_selectedDifficulty != null) {
      query = query.where('difficulty', isEqualTo: _selectedDifficulty);
    }

    return query;
  }
}
