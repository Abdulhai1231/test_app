import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyGroup {
  final String id;
  final String name;
  final List<String> memberIds;
  
  FamilyGroup({
    required this.id,
    required this.name,
    required this.memberIds,
  });
}