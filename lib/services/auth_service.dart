import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart'; // Make sure to import your UserModel

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Convert Firebase User to UserModel
  UserModel? _userFromFirebase(User? user) {
    return user != null 
        ? UserModel(
            user.uid,
            email: user.email ?? '',
            userId: user.uid,
            displayName: user.displayName ?? '',
          )
        : null;
  }

  // Get current user as UserModel
  UserModel? get currentUserModel => _userFromFirebase(_auth.currentUser);

  // Auth state changes stream (returns UserModel)
  Stream<UserModel?> get user {
    return _auth.authStateChanges().map(_userFromFirebase);
  }

  // Email/Password Sign In (returns UserModel)
  Future<UserModel?> signInWithEmailAndPassword(
    String email, 
    String password,
  ) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password,
      );
      return _userFromFirebase(result.user);
    } catch (e) {
      debugPrint('Email sign in error: $e');
      return null;
    }
  }
Future<UserModel?> signInAnonymously() async {
  try {
    UserCredential result = await _auth.signInAnonymously();
    return _userFromFirebase(result.user);
  } catch (e) {
    debugPrint('Anonymous sign in error: $e');
    return null;
  }
}
  // Email/Password Registration (returns UserModel)
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
      
      // Update user display name
      await result.user?.updateDisplayName(displayName);
      await result.user?.reload();
      
      return _userFromFirebase(_auth.currentUser);
    } catch (e) {
      debugPrint('Registration error: $e');
      return null;
    }
  }
  

  // Google Sign In (returns UserModel)
  Future<UserModel?> signInWithGoogle() async {
    try {
      debugPrint('Starting Google Sign-In...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        debugPrint('Google sign in cancelled');
        return null;
      }

      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result = await _auth.signInWithCredential(credential);
      return _userFromFirebase(result.user);
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
  Future<void> signInWithEmailAndPasswordRaw(String email, String password, dynamic _firebaseAuth) async {
  try {
    await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
  } catch (e, stack) {
    print("Email sign in error: $e");
    print(stack);
    rethrow;
  }
}

}