import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:timeago/timeago.dart' as timeago;

class DescriptionSection extends StatefulWidget {
  final DocumentSnapshot project;

  const DescriptionSection({Key? key, required this.project}) : super(key: key);

  @override
  State<DescriptionSection> createState() => _DescriptionSectionState();
}

class _DescriptionSectionState extends State<DescriptionSection> {
  final TextEditingController _commentTextController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _rating = 0; // Initial rating
  String? _errorMessage; // Error message for validation

  void addComment(String commentText) async {
    try {
      String userId = _auth.currentUser?.uid ?? 'anonymous';

      // Save the comment and rating
      await FirebaseFirestore.instance
          .collection("projects")
          .doc(widget.project.id)
          .collection("comments")
          .add({
        "commentText": commentText,
        "rating": _rating,
        "commentedBy": userId,
        "commentTime": Timestamp.now(),
      });

      // Optionally update the average rating here
      _updateAverageRating();
    } catch (e) {
      print("Error adding comment: $e");
    }
  }

  Future<String> _fetchUserName(String userId) async {
    var userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc['name'] as String? ?? 'Unknown User';
  }

  Future<Map<String, dynamic>> _fetchUserData(String userId) async {
  var userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
  if (userDoc.exists) {
    return userDoc.data() as Map<String, dynamic>;
  } else {
    return {'name': 'Unknown User', 'imageUrl': null};
  }
}


  void _updateAverageRating() async {
    try {
      var commentsSnapshot = await FirebaseFirestore.instance
          .collection("projects")
          .doc(widget.project.id)
          .collection("comments")
          .get();

      double totalRating = 0;
      int count = 0;

      for (var comment in commentsSnapshot.docs) {
        totalRating += comment['rating'];
        count++;
      }

      double averageRating = count > 0 ? totalRating / count : 0.0;

      // Round averageRating to 1 decimal place
      averageRating = double.parse(averageRating.toStringAsFixed(1));

      await FirebaseFirestore.instance
          .collection("projects")
          .doc(widget.project.id)
          .update({'average_rating': averageRating});
    } catch (e) {
      print("Error updating average rating: $e");
    }
  }


  void deleteComment(String commentId) async {
    try {
      await FirebaseFirestore.instance
          .collection("projects")
          .doc(widget.project.id)
          .collection("comments")
          .doc(commentId)
          .delete();

      // Optionally update the average rating here
      _updateAverageRating();
    } catch (e) {
      print("Error deleting comment: $e");
    }
  }

  void editComment(String commentId, String newCommentText, int newRating) async {
    try {
      await FirebaseFirestore.instance
          .collection("projects")
          .doc(widget.project.id)
          .collection("comments")
          .doc(commentId)
          .update({
        "commentText": newCommentText,
        "rating": newRating,
      });

      // Optionally update the average rating here
      _updateAverageRating();
    } catch (e) {
      print("Error editing comment: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    var projectData = widget.project.data() as Map<String, dynamic>;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("Project length:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              const Icon(Icons.timer, color: Colors.purple),
              const SizedBox(width: 5),
              Text(projectData['duration'] ?? 'N/A', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Materials:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const SizedBox(width: 5),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var material in projectData['materials'].split('\n'))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Text(
                              '• $material',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              softWrap: true, // Allows text to wrap if it exceeds the available space
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text("Difficulty:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              const SizedBox(width: 5),
              Text(projectData['difficulty'] ?? 'N/A', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          // Fetch and display average rating
          StreamBuilder<double>(
            stream: FirebaseFirestore.instance
                .collection("projects")
                .doc(widget.project.id)
                .snapshots()
                .map((doc) => doc['average_rating'] ?? 0.0),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text("Error loading average rating");
              } else {
                var averageRating = snapshot.data ?? 0.0;
                return Row(
                  children: [
                    Text(
                      "Average Rating: ",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Spacer(),
                    Text(
                      "${averageRating.toStringAsFixed(1)}/5.0",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: showCommentDialog,
            child: Text("Add Comment"),
          ),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("projects")
                .doc(widget.project.id)
                .collection("comments")
                .orderBy("commentTime", descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text("Error loading comments");
              } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Text("No comments yet.");
              } else {
                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    var commentData = doc.data() as Map<String, dynamic>;
                    return StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance
      .collection('users')
      .doc(commentData['commentedBy'])
      .snapshots(),
  builder: (context, userSnapshot) {
    if (userSnapshot.connectionState == ConnectionState.waiting) {
      return Text("Loading user data...");
    } else if (userSnapshot.hasError) {
      return Text("Error loading user data");
    } else if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
      return Text("User not found");
    } else {
      var userData = userSnapshot.data!.data() as Map<String, dynamic>;
      var timeAgo = timeago.format((commentData['commentTime'] as Timestamp).toDate());
      var currentUser = _auth.currentUser?.uid;

      return Comment(
        commentId: doc.id,
        user: userData['name'],
        time: timeAgo,
        text: commentData['commentText'],
        rating: commentData['rating'],
        imageUrl: userData['imageUrl'], // Pass the imageUrl to the Comment widget
        onDelete: currentUser == commentData['commentedBy']
            ? () {
                deleteComment(doc.id);
              }
            : null,
        onEdit: currentUser == commentData['commentedBy']
            ? () {
                showEditCommentDialog(doc.id, commentData['commentText'], commentData['rating']);
              }
            : null,
      );
    }
  },
);

                  }).toList(),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void showCommentDialog() {
    setState(() {
      _errorMessage = null;
      _commentTextController.clear();
      _rating = 0;
    });

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text("Add Comment"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _commentTextController,
                  decoration: InputDecoration(hintText: "Write a comment"),
                ),
                const SizedBox(height: 10),
                Text("Rate the project:"),
                RatingBar(
                  initialRating: _rating.toDouble(),
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemSize: 30.0,
                  ratingWidget: RatingWidget(
                    full: Icon(Icons.star, color: Colors.amber),
                    half: Icon(Icons.star_half, color: Colors.amber),
                    empty: Icon(Icons.star_border, color: Colors.amber),
                  ),
                  onRatingUpdate: (rating) {
                    setState(() {
                      _rating = rating.round();
                    });
                  },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_commentTextController.text.isEmpty) {
                      _errorMessage = "Comment cannot be empty.";
                    } else if (_rating == 0) {
                      _errorMessage = "Please provide a rating.";
                    } else {
                      addComment(_commentTextController.text);
                      _commentTextController.clear();
                      Navigator.pop(context);
                    }
                  });
                },
                child: Text("Submit"),
              ),
            ],
          );
        },
      ),
    );
  }

  void showEditCommentDialog(String commentId, String currentText, int currentRating) {
    setState(() {
      _errorMessage = null;
      _commentTextController.text = currentText;
      _rating = currentRating;
    });

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text("Edit Comment"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _commentTextController,
                  decoration: InputDecoration(hintText: "Edit your comment"),
                ),
                const SizedBox(height: 10),
                Text("Rate the project:"),
                RatingBar(
                  initialRating: _rating.toDouble(),
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemSize: 30.0,
                  ratingWidget: RatingWidget(
                    full: Icon(Icons.star, color: Colors.amber),
                    half: Icon(Icons.star_half, color: Colors.amber),
                    empty: Icon(Icons.star_border, color: Colors.amber),
                  ),
                  onRatingUpdate: (rating) {
                    setState(() {
                      _rating = rating.round();
                    });
                  },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_commentTextController.text.isEmpty) {
                      _errorMessage = "Comment cannot be empty.";
                    } else if (_rating == 0) {
                      _errorMessage = "Please provide a rating.";
                    } else {
                      editComment(commentId, _commentTextController.text, _rating);
                      _commentTextController.clear();
                      Navigator.pop(context);
                    }
                  });
                },
                child: Text("Update"),
              ),
            ],
          );
        },
      ),
    );
  }
}

class Comment extends StatelessWidget {
  final String commentId;
  final String user;
  final String time;
  final String text;
  final int rating;
  final String? imageUrl; // URL of the user's profile picture
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const Comment({
    Key? key,
    required this.commentId,
    required this.user,
    required this.time,
    required this.text,
    required this.rating,
    this.imageUrl,
    this.onDelete,
    this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
                child: imageUrl == null ? Text(user[0]) : null, // Show first letter if no image
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user, style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(time, style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              RatingBarIndicator(
                rating: rating.toDouble(),
                itemBuilder: (context, index) => Icon(Icons.star, color: Colors.amber),
                itemCount: 5,
                itemSize: 20.0,
                direction: Axis.horizontal,
              ),
              if (onEdit != null || onDelete != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onEdit != null)
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.green),
                        onPressed: onEdit,
                      ),
                    if (onDelete != null)
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: onDelete,
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(text),
        ],
      ),
    );
  }
}


