import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyGroup {
  final String id;
  final String name;
  final String admin;
  final List<String> members;
  final List<String> pendingInvitations;
  final DateTime createdAt;

  FamilyGroup({
    required this.id,
    required this.name,
    required this.admin,
    required this.members,
    required this.pendingInvitations,
    required this.createdAt,
  });

  factory FamilyGroup.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return FamilyGroup(
      id: doc.id,
      name: data['name'] ?? '',
      admin: data['admin'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      pendingInvitations: List<String>.from(data['pendingInvitations'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}