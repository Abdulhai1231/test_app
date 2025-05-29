import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart'; // Your UserModel
import 'package:cloud_firestore/cloud_firestore.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Convert Firebase User to basic UserModel (without Firestore data)
  UserModel? _userFromFirebase(User? user) {
    return user != null 
        ? UserModel(
            email: user.email ?? '',
            userId: user.uid,
            displayName: user.displayName ?? '',
            emailVerified: user.emailVerified,
          )
        : null;
  }

  // Load full user data from Firestore (including familyId)
  Stream<UserModel?> get user {
  return _auth.authStateChanges().map((User? user) {
    return user != null ? UserModel.fromFirebase(user) : null;
  });
}

  Future<UserModel?> loadFullUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!, uid);
    }
    return null;
  }

  // Email/Password Sign In (returns full UserModel from Firestore)
  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (result.user == null) return null;

      // Load full user data including familyId from Firestore
      return await loadFullUser(result.user!.uid);
    } on FirebaseAuthException catch (e) {
      debugPrint('FIREBASE ERROR CODE: ${e.code}');
      debugPrint('FULL ERROR: ${e.toString()}');
      return null;
    } catch (e) {
      debugPrint('Generic error: ${e.toString()}');
      return null;
    }
  }

  // Register new user (email/password)
  Future<UserModel?> registerWithEmailAndPassword(
    String email, 
    String password,
    String displayName,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password,
      );
      
      await result.user?.updateDisplayName(displayName);
      await result.user?.reload();

      // Create user in Firestore
      final newUser = UserModel(
        userId: result.user!.uid,
        email: email,
        displayName: displayName,
        emailVerified: result.user!.emailVerified,
      );
      await _firestore.collection('users').doc(newUser.userId).set(newUser.toMap());

      return newUser;
    } catch (e) {
      debugPrint('Registration error: $e');
      return null;
    }
  }

  // Google Sign In (returns full UserModel from Firestore)
  Future<UserModel?> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      if (result.user == null) return null;

      // Load full user data from Firestore after Google sign-in
      UserModel? userModel = await loadFullUser(result.user!.uid);

      if (userModel == null) {
        // User document may not exist yet, create it:
        userModel = UserModel(
          userId: result.user!.uid,
          email: result.user!.email ?? '',
          displayName: result.user!.displayName ?? '',
          emailVerified: result.user!.emailVerified,
        );
        // Save new user to Firestore
        await _firestore.collection('users').doc(userModel.userId).set(userModel.toMap());
      }

      // Navigate after login success
      Navigator.of(context).pushReplacementNamed('/home');

      return userModel;
    } catch (e) {
      debugPrint('Google sign in error: $e');
      return null;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Password reset error: $e');
      rethrow;
    }
  }

  // Optional: Anonymous sign in
  Future<UserModel?> signInAnonymously() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      return _userFromFirebase(result.user);
    } catch (e) {
      debugPrint('Anonymous sign in error: $e');
      return null;
    }
  }
  Future<String?> _getCurrentFamilyId() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('familyGroups')
      .where('members', arrayContains: FirebaseAuth.instance.currentUser!.uid)
      .limit(1)
      .get();
  return snapshot.docs.isEmpty ? null : snapshot.docs.first.id;
}
}
