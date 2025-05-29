import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyGroup {
  final String id;
  final String name;
  final List<String> members;
  final List<String> pendingInvites;
  final String admin;
  
  FamilyGroup({
    required this.id,
    required this.name,
    required this.members,
    required this.pendingInvites,
    required this.admin,
  });

  factory FamilyGroup.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return FamilyGroup(
      id: doc.id,
      name: data['name'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      pendingInvites: List<String>.from(data['pendingInvites'] ?? []),
      admin: data['admin'] ?? '',
    );
  }
}