import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:testing/screens/home/pages/sections/description_section.dart';
import 'package:testing/screens/home/pages/sections/instruction_section.dart';

class ProjectScreen extends StatefulWidget {
  final DocumentSnapshot project;

  const ProjectScreen({Key? key, required this.project}) : super(key: key);

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  bool isVideoSection = true;
  bool isInWishlist = false;
  Stream<DocumentSnapshot>? wishlistStatusStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userId = user.uid;
      wishlistStatusStream = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .doc(widget.project.id)
          .snapshots();
    }
  }

  void toggleWishlistStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userId = user.uid;
      if (isInWishlist) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('wishlist')
            .doc(widget.project.id)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed from wishlist')),
        );
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('wishlist')
            .doc(widget.project.id)
            .set({
          'projectId': widget.project.id,
          'title': widget.project['title'],
          'image': widget.project['image'],
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added to wishlist')),
        );
      }

      setState(() {
        isInWishlist = !isInWishlist;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var projectData = widget.project.data() as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: Text(
          projectData['title'],
          style: TextStyle(
            fontFamily: 'Lexend Deca',
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: wishlistStatusStream,
            builder: (context, snapshot) {
              bool inWishlist = snapshot.data?.exists ?? false;
              return IconButton(
                icon: Icon(
                  inWishlist ? Icons.favorite : Icons.favorite_border,
                  color: Colors.red,
                ),
                onPressed: toggleWishlistStatus,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Column(
            children: [
              projectData['image'] != null
                  ? Hero(
                      tag: 'projectImage-${widget.project.id}',
                      child: Image.network(
                        projectData['image'],
                        width: MediaQuery.of(context).size.width,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      width: MediaQuery.of(context).size.width,
                      height: 200,
                      color: Colors.grey,
                    ),
              SizedBox(height: 15),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      projectData['description'] ?? 'Complete',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withOpacity(0.7),
                      ),
                       textAlign: TextAlign.justify,
                    ),
                  ),
                  SizedBox(width: 5),
                ],
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Material(
                      color: isVideoSection
                          ? Colors.purple
                          : Colors.purple.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            isVideoSection = true;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 15, horizontal: 35),
                          child: Text(
                            "Instruction",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Material(
                      color: isVideoSection
                          ? Colors.purple.withOpacity(0.6)
                          : Colors.purple,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            isVideoSection = false;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 15, horizontal: 35),
                          child: Text(
                            "Description",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              isVideoSection
                  ? InstructionSection(project: widget.project)
                  : DescriptionSection(project: widget.project),
            ],
          ),
        ),
      ),
    );
  }
}
