import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ShoppingItem {
  final String name;
  final String addedBy;
  bool completed;
  final DateTime addedAt;
  int priority;

  ShoppingItem({
    required this.name,
    required this.addedBy,
    required this.completed,
    required this.addedAt,
    this.priority = 2,
  });

  factory ShoppingItem.fromMap(Map map) {
    return ShoppingItem(
      name: map['name'] ?? '',
      addedBy: map['addedBy'] ?? '',
      completed: map['completed'] ?? false,
      addedAt: (map['addedAt'] as Timestamp).toDate(),
      priority: map['priority'] ?? 2,
    );
  }

  bool get done => completed;

  set done(bool value) {
    completed = value;
  }
}

class ShoppingList {
  final String id;
  final String name;
  final String createdBy;
  final DateTime createdAt;
  final String? familyId; // Changed from groupId to familyId to match rules
  final List<ShoppingItem> items;
  final DateTime date;
  final String imagePath;
  final DateTime? dueDate;

  ShoppingList({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    this.familyId,
    required this.items,
    required this.date,
    required this.imagePath,
    this.dueDate,
  });

  factory ShoppingList.fromFirestore(DocumentSnapshot doc) {
    try {
      Map data = doc.data() as Map;
      return ShoppingList(
        id: doc.id,
        name: data['name'] ?? 'Unnamed List',
        createdBy: data['createdBy'] ?? '', // This is critical for permissions
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        familyId: data['familyId'], // Can be null for personal lists
        items: (data['items'] as List? ?? []).map((item) {
          try {
            return ShoppingItem.fromMap(item as Map);
          } catch (e) {
            debugPrint('Error parsing shopping item: $e');
            return ShoppingItem(
              name: 'Error item',
              addedBy: 'system',
              completed: false,
              addedAt: DateTime.now(),
            );
          }
        }).toList(),
        date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        imagePath: data['imagePath'] ?? '',
        dueDate: data['dueDate'] != null ? (data['dueDate'] as Timestamp).toDate() : null,
      );
    } catch (e) {
      debugPrint('Error parsing shopping list: $e');
      return ShoppingList(
        id: doc.id,
        name: 'Error List',
        createdBy: '',
        createdAt: DateTime.now(),
        items: [],
        date: DateTime.now(),
        imagePath: '',
      );
    }
  }
}