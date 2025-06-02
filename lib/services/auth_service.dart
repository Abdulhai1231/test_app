import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Zentrale Klasse für Authentifizierungsoperationen
/// 
/// Verantwortlich für:
/// - Email/Passwort Authentifizierung
/// - Google Sign-In
/// - Benutzerverwaltung
/// - Passwort-Reset
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /* ------------------------- KERNMETHODEN ------------------------- */

  /// Konvertiert Firebase User in unser UserModel
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

  /// Haupt-User-Stream mit Firestore-Daten
  /// 
  /// Kombiniert Auth-Status mit Firestore-Daten (inkl. familyId)
  Stream<UserModel?> get user {
    return _auth.authStateChanges().asyncMap((User? firebaseUser) async {
      if (firebaseUser == null) return null;
      return await loadFullUser(firebaseUser.uid);
    });
  }

  /// Lädt vollständige Benutzerdaten aus Firestore
  Future<UserModel?> loadFullUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists ? UserModel.fromMap(doc.data()!, uid) : null;
  }

  /* ------------------------- ANMELDEMETHODEN ------------------------- */

  /// Klassische Email/Passwort-Anmeldung
  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user != null ? await loadFullUser(result.user!.uid) : null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Fehler bei Anmeldung: ${e.code} - ${e.message}');
      return null;
    }
  }

  /// Google Sign-In mit Firestore-Synchronisation
  Future<UserModel?> signInWithGoogle(BuildContext context) async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      if (result.user == null) return null;

      // Prüft ob Benutzer in Firestore existiert
      UserModel? user = await loadFullUser(result.user!.uid);
      
      if (user == null) {
        // Neuen Benutzer in Firestore anlegen
        user = UserModel(
          userId: result.user!.uid,
          email: result.user!.email ?? '',
          displayName: result.user!.displayName ?? '',
          emailVerified: result.user!.emailVerified,
        );
        await _firestore.collection('users').doc(user.userId).set(user.toMap());
      }

      Navigator.of(context).pushReplacementNamed('/home');
      return user;
    } catch (e) {
      debugPrint('Google-Anmeldung fehlgeschlagen: $e');
      return null;
    }
  }

  /* ------------------------- REGISTRIERUNG ------------------------- */

  /// Neue Benutzerregistrierung
  Future<UserModel?> registerWithEmailAndPassword(
    String email, 
    String password,
    String displayName,
  ) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password,
      );
      
      await result.user?.updateDisplayName(displayName);
      await result.user?.reload();

      final newUser = UserModel(
        userId: result.user!.uid,
        email: email,
        displayName: displayName,
        emailVerified: result.user!.emailVerified,
      );
      
      await _firestore.collection('users').doc(newUser.userId).set(newUser.toMap());
      return newUser;
    } catch (e) {
      debugPrint('Registrierungsfehler: $e');
      return null;
    }
  }

  /* ------------------------- SONSTIGE METHODEN ------------------------- */

  /// Abmelden
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Passwort-Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Passwort-Reset fehlgeschlagen: $e');
      rethrow;
    }
  }

  /// Anonyme Anmeldung (für Testzwecke)
  Future<UserModel?> signInAnonymously() async {
    try {
      final result = await _auth.signInAnonymously();
      return _userFromFirebase(result.user);
    } catch (e) {
      debugPrint('Anonyme Anmeldung fehlgeschlagen: $e');
      return null;
    }
  }
}