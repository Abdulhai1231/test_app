import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingList {
  final String id;
  final String name;
  final String createdBy;
  final DateTime createdAt;
  final String? groupId;
  final List<ShoppingItem> items;
  final DateTime date;
  final String imagePath;
  final DateTime? dueDate;

  ShoppingList({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    this.groupId,
    required this.items,
    required this.date,
    required this.imagePath,
    this.dueDate,
  });

  factory ShoppingList.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return ShoppingList(
      id: doc.id,
      name: data['name'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      groupId: data['groupId'],
      items: (data['items'] as List? ?? []).map((item) => ShoppingItem.fromMap(item)).toList(),
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imagePath: data['imagePath'] ?? '',
      dueDate: data['dueDate'] != null ? (data['dueDate'] as Timestamp).toDate() : null,
    );
  }
}

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