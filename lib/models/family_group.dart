import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyGroup {
  final String id;                 // Firestore Dokument-ID der Familie
  final String name;               // Name der Familie / Familiengruppe
  final List<String> members;      // Liste der User-IDs, die Mitglieder sind
  final List<String> pendingInvites; // Liste der eingeladenen User-IDs (noch ausstehend)
  final String admin;              // User-ID des Familien-Admins

  FamilyGroup({
    required this.id,
    required this.name,
    required this.members,
    required this.pendingInvites,
    required this.admin,
  });

  // Factory Konstruktor: erstellt FamilyGroup aus Firestore-Dokument
  factory FamilyGroup.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return FamilyGroup(
      id: doc.id,
      name: data['name'] ?? '',                         // Default: leerer Name
      members: List<String>.from(data['members'] ?? []),        // Sicherstellen, dass Liste Strings enthält
      pendingInvites: List<String>.from(data['pendingInvites'] ?? []),
      admin: data['admin'] ?? '',                       // Admin-UserID, Default leer
    );
  }
}
