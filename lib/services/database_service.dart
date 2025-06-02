import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:einkaufsliste/models/category.dart' as my_models;  // keep this, use prefix
import 'package:einkaufsliste/models/grocery_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';


class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final String? familyId; // nullable now, can be null if not provided
  final String userId;

  DatabaseService({this.familyId, required this.userId});

  void _log(String message) {
    if (kDebugMode) {
      print(message);
    }
  }

  static Future<String?> fetchFamilyId() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('familyGroups')
        .where('members', arrayContains: FirebaseAuth.instance.currentUser!.uid)
        .limit(1)
        .get();
    return snapshot.docs.isEmpty ? null : snapshot.docs.first.id;
  }

  // Categories
  Stream<List<my_models.Category>> categoriesStream() {
    return _db.collection('categories')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          return my_models.Category(
            id: doc.id,
            name: data['name'] ?? 'Unnamed',
            createdBy: data['createdBy'] ?? '',
            createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
        }).toList());
  }

  Stream<User?> userStream() {
    return FirebaseAuth.instance.authStateChanges();
  }

  Future<void> addCategory(String name) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _db.collection('categories').add({
      'name': name,
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteList(String listId) async {
    try {
      await _db.collection('shoppingLists').doc(listId).delete();
      _log('Deleted list $listId');
    } catch (e) {
      _log('Error deleting list $listId: $e');
      rethrow;
    }
  }

  Future<void> updateList(String listId, String name, DateTime? dueDate) async {
    await _db.collection('shoppingLists').doc(listId).update({
      'name': name,
      'dueDate': dueDate,
    });
  }

  // Shopping Lists

  Stream<QuerySnapshot> getUserShoppingLists(String userId) {
    return _db
        .collection('shoppingLists')
        .where('createdBy', isEqualTo: userId)
        .where('type', isEqualTo: 'personal')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<DocumentSnapshot> getShoppingList(String listId) {
    return _db.collection('shoppingLists').doc(listId).snapshots();
  }

  Stream<QuerySnapshot> getFamilyShoppingLists(String familyId) {
    return _db
        .collection('shoppingLists')
        .where('familyId', isEqualTo: familyId)
        .where('type', isEqualTo: 'family')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<String> createPersonalShoppingList({
    required String name,
    required String userId,
    DateTime? dueDate,
    required String imagePath,
  }) async {
    try {
      final now = DateTime.now();
      final docRef = await _db.collection('shoppingLists').add({
        'name': name,
        'createdBy': userId,
        'createdAt': Timestamp.fromDate(now),
        'dueDate': dueDate,
        'imageUrl': imagePath,
        'items': [],
        'type': 'personal',
      });
      return docRef.id;
    } catch (e) {
      _log('Error creating personal shopping list: $e');
      rethrow;
    }
  }

  Future<void> createShoppingListForUser(String userId, String name, String type) async {
    final listData = {
      'name': name,
      'createdBy': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'dueDate': null,
      'imagePath': '', // or use a default image path if needed
      'type': type,
    };

    if (type == 'family') {
      final currentFamilyId = await _getCurrentFamilyId();
      if (currentFamilyId != null) {
        listData['familyId'] = currentFamilyId;
      }
    }

    await _db.collection('shoppingLists').add(listData);
  }

  Future<void> createShoppingList({
  required String name,
  required String userId,
  required DateTime dueDate,
  required String imagePath,
  String? groupId,
  required String type,
}) async {
  try {
    final listData = {
      'name': name,
      'createdBy': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'dueDate': Timestamp.fromDate(dueDate),
      'imagePath': imagePath,
      'type': type,
      'items': [],
    };

    if (groupId != null && type == 'family') {
      listData['familyId'] = groupId;
      listData['groupId'] = groupId;
    }

    await _db.collection('shoppingLists').add(listData);
    _log('Successfully created $type list: $name');
  } catch (e) {
    _log('Error creating shopping list: $e');
    rethrow;
  }
}

  Future<String?> _getCurrentFamilyId() async {
    final snapshot = await _db.collection('familyGroups')
        .where('members', arrayContains: FirebaseAuth.instance.currentUser!.uid)
        .limit(1)
        .get();

    return snapshot.docs.isEmpty ? null : snapshot.docs.first.id;
  }
  Future<String?> getCurrentUserFamilyId(String userId) async {
  try {
    // First check if we have a local familyId
    final userDoc = await _db.collection('users').doc(userId).get();
    if (userDoc.exists && userDoc.data()?['familyId'] != null) {
      return userDoc.data()!['familyId'];
    }

    // If not, check familyGroups collection
    final familyQuery = await _db.collection('familyGroups')
        .where('members', arrayContains: userId)
        .limit(1)
        .get();

    return familyQuery.docs.isEmpty ? null : familyQuery.docs.first.id;
  } catch (e) {
    debugPrint('Error getting family ID: $e');
    return null;
  }
}

  // Items

  Future<void> addItemToList(String listId, String itemName, {String? amount}) async {
  await _db.collection('shoppingLists').doc(listId).update({
    'items': FieldValue.arrayUnion([
      {
        'name': itemName,
        'completed': false,
        'amount': amount,
      }
    ]),
  });
}

  Future<void> toggleItemCompletion(String listId, int index, bool completed) async {
    final doc = _db.collection('shoppingLists').doc(listId);
    final snapshot = await doc.get();
    final items = List.from(snapshot.get('items'));
    items[index]['completed'] = completed;
    await doc.update({'items': items});
  }

  Future<void> deleteItemFromList(String listId, int index) async {
    final doc = _db.collection('shoppingLists').doc(listId);
    final snapshot = await doc.get();
    final items = List.from(snapshot.get('items'));
    items.removeAt(index);
    await doc.update({'items': items});
  }

  Future<void> addGroceryItem(String listId, GroceryItem item) async {
    try {
      if (familyId == null) throw Exception('Family ID is required');

      await _db
          .collection('families/$familyId/groceries')
          .doc(listId)
          .update({
        'items': FieldValue.arrayUnion([item.toMap()]),
      });
    } catch (e) {
      _log("Error adding item: $e");
      rethrow;
    }
  }

  // Placeholder implementations
  Future<void> fetchShoppingList(String listId) async {
    // Implement as needed
  }

  Future<String?> createNewShoppingList({
  required String name,
  required String userId,
  String? groupId,
  DateTime? dueDate,
  required String imagePath,
}) async {
  try {
    final now = DateTime.now();
    final listData = {
      'name': name,
      'createdBy': userId,
      'createdAt': Timestamp.fromDate(now),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate) : null,
      'imagePath': imagePath,
      'items': [],
      'type': groupId != null ? 'family' : 'personal',
    };

    if (groupId != null) {
      listData['familyId'] = groupId;
      listData['groupId'] = groupId;
    }

    final docRef = await _db.collection('shoppingLists').add(listData);
    return docRef.id;
  } catch (e) {
    _log('Error creating shopping list: $e');
    rethrow;
  }
}

  Future<void> updateGroceryItem(String listId, GroceryItem item) async {
    try {
      if (familyId == null) throw Exception('Family ID is required');

      await _db
          .collection('families/$familyId/groceries')
          .doc(listId)
          .update({
        'items': FieldValue.arrayRemove([item.toMap()]),
      });

      await _db
          .collection('families/$familyId/groceries')
          .doc(listId)
          .update({
        'items': FieldValue.arrayUnion([item.toMap()]),
      });
    } catch (e) {
      _log("Error updating item: $e");
      rethrow;
    }
  }
}
