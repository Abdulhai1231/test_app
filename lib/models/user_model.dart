import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String userId;       // Firebase User ID
  final String email;        // E-Mail des Users
  final String displayName;  // Anzeigename des Users
  final String? familyId;    // Optional: Zugehörige Familien-ID (kann null sein)
  final bool emailVerified;  // Ob die E-Mail verifiziert wurde

  UserModel({
    required this.userId,
    required this.email,
    required this.displayName,
    this.familyId,
    required this.emailVerified,
  });

  // Erstellt ein UserModel aus einer Map (z.B. aus Firestore-Daten)
  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      userId: uid,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      familyId: data['familyId'],
      emailVerified: data['emailVerified'] ?? false,
    );
  }

  // Erstellt ein UserModel direkt aus einem Firestore-Dokument
  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data, doc.id);
  }

  // Erstellt ein UserModel aus einem FirebaseAuth User (nur Auth-Daten)
  // familyId muss separat geladen werden (z.B. aus Firestore)
  static UserModel fromFirebase(User user) {
    return UserModel(
      userId: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      emailVerified: user.emailVerified,
      familyId: null, // Falls FamilyId separat in Firestore gespeichert ist
    );
  }

  // Wandelt das UserModel in eine Map um, um es in Firestore zu speichern
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'familyId': familyId,
      'emailVerified': emailVerified,
    };
  }

  // Optional: Einfacherer Zugriff auf userId als 'uid'
  String get uid => userId;
}
