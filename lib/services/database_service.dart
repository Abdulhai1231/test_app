import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:einkaufsliste/models/category.dart' as my_models;  // keep this, use prefix
import 'package:einkaufsliste/models/grocery_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? familyId;

  DatabaseService({this.familyId});

  void _log(String message) {
    if (kDebugMode) {
      print(message);
    }
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
    await _db.collection('shoppingLists').doc(listId).delete();
  }

  Future<void> updateList(String listId, String name, DateTime? dueDate) async {
    await _db.collection('shoppingLists').doc(listId).update({
      'name': name,
      'dueDate': dueDate,
    });
  }

  // Shopping Lists
  Stream<QuerySnapshot> getUserShoppingLists(String userId) {
    return _db.collection('shoppingLists')
        .where('createdBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<DocumentSnapshot> getShoppingList(String listId) {
    return _db.collection('shoppingLists').doc(listId).snapshots();
  }

  Stream<QuerySnapshot> getFamilyShoppingLists(String groupId) {
    return _db.collection('shoppingLists')
        .where('groupId', isEqualTo: groupId)
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

  Future<String> createShoppingList({
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
      _log('Error creating shopping list: $e');
      rethrow;
    }
  }

  // Items
  Future<void> addItemToList(String listId, String itemName) async {
    await _db.collection('shoppingLists').doc(listId).update({
      'items': FieldValue.arrayUnion([{
        'name': itemName,
        'completed': false,
        'addedAt': DateTime.now().toIso8601String(),
      }])
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

  Future<String> createNewShoppingList({
    required String name,
    required String userId,
    DateTime? dueDate,
    required String imagePath,
  }) async {
    return await createShoppingList(
      name: name,
      userId: userId,
      dueDate: dueDate,
      imagePath: imagePath,
    );
  }
}
