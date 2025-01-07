import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential> signInWithGoogle() async {
  try {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(code: 'sign_in_canceled', message: 'Sign in aborted by user');
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

    User? user = userCredential.user;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        bool isBanned = userDoc.get('banned') ?? false;
        if (isBanned) {
          await FirebaseAuth.instance.signOut();
          throw FirebaseAuthException(code: 'user_banned', message: 'Your account is banned.');
        }
      } else {
        String email = user.email!;
        String name = email.split('@')[0];
        String role = "User";
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
          'role': role,
          'banned': false,
        });
      }
    }

    return userCredential;
  } catch (e) {
    print('Error during Google sign-in: $e');
    throw e;
  }
}
}