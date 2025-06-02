import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:einkaufsliste/models/category.dart' as my_models;
import 'package:einkaufsliste/models/grocery_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Datenbank-Service für Einkaufslisten-Operationen
/// 
/// Verantwortlich für:
/// - Kategorienverwaltung
/// - Einkaufslisten-CRUD
/// - Artikelverwaltung
/// - Familiengruppen-Unterstützung
class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? familyId;
  final String userId;

  DatabaseService({this.familyId, required this.userId});

  /* ------------------------- HILFSMETHODEN ------------------------- */

  /// Debug-Ausgabe
  void _log(String message) {
    if (kDebugMode) print(message);
  }

  /// Ermittelt die Familien-ID des aktuellen Nutzers
  Future<String?> _getCurrentFamilyId() async {
    final snapshot = await _db.collection('familyGroups')
        .where('members', arrayContains: FirebaseAuth.instance.currentUser!.uid)
        .limit(1)
        .get();
    return snapshot.docs.isEmpty ? null : snapshot.docs.first.id;
  }

  /// Holt die Familien-ID für einen bestimmten Nutzer (zuerst aus "users", dann aus "familyGroups")
  Future<String?> getCurrentUserFamilyId(String userId) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      if (userDoc.exists && userDoc.data()?['familyId'] != null) {
        return userDoc.data()!['familyId'];
      }

      final familyQuery = await _db.collection('familyGroups')
          .where('members', arrayContains: userId)
          .limit(1)
          .get();

      return familyQuery.docs.isEmpty ? null : familyQuery.docs.first.id;
    } catch (e) {
      debugPrint('Fehler beim Ermitteln der Familien-ID: $e');
      return null;
    }
  }

  /* ------------------------- AUTHENTIFIZIERUNG ------------------------- */

  /// Stream für Authentifizierungsstatus des Nutzers
  Stream<User?> userStream() {
    return FirebaseAuth.instance.authStateChanges();
  }

  /// Statische Methode zum Abrufen der Familien-ID für den eingeloggten Nutzer
  static Future<String?> fetchFamilyId() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('familyGroups')
        .where('members', arrayContains: FirebaseAuth.instance.currentUser!.uid)
        .limit(1)
        .get();
    return snapshot.docs.isEmpty ? null : snapshot.docs.first.id;
  }

  /* ------------------------- KATEGORIEN ------------------------- */

  /// Stream für alle Kategorien
  Stream<List<my_models.Category>> categoriesStream() {
    return _db.collection('categories')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return my_models.Category(
                id: doc.id,
                name: data['name'] ?? 'Unbenannt',
                createdBy: data['createdBy'] ?? '',
                createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              );
            }).toList());
  }

  /// Neue Kategorie hinzufügen
  Future<void> addCategory(String name) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _db.collection('categories').add({
      'name': name,
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /* ------------------------- EINKAUFSLISTEN ------------------------- */

  /// Stream für persönliche Einkaufslisten
  Stream<QuerySnapshot> getUserShoppingLists(String userId) {
    return _db.collection('shoppingLists')
        .where('createdBy', isEqualTo: userId)
        .where('type', isEqualTo: 'personal')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Stream für Familien-Einkaufslisten
  Stream<QuerySnapshot> getFamilyShoppingLists(String familyId) {
    return _db.collection('shoppingLists')
        .where('familyId', isEqualTo: familyId)
        .where('type', isEqualTo: 'family')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Einzelne Einkaufsliste beobachten
  Stream<DocumentSnapshot> getShoppingList(String listId) {
    return _db.collection('shoppingLists').doc(listId).snapshots();
  }

  /// Neue persönliche Liste erstellen
  Future<String> createPersonalShoppingList({
    required String name,
    required String userId,
    DateTime? dueDate,
    required String imagePath,
  }) async {
    try {
      final docRef = await _db.collection('shoppingLists').add({
        'name': name,
        'createdBy': userId,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'dueDate': dueDate,
        'imageUrl': imagePath,
        'items': [],
        'type': 'personal',
      });
      return docRef.id;
    } catch (e) {
      _log('Fehler beim Erstellen der Liste: $e');
      rethrow;
    }
  }
  /// Erstellt eine neue Einkaufsliste (persönlich oder Familie)
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

    // Falls es eine Gruppen-ID gibt und die Liste vom Typ "family" ist,
    // füge zusätzlich die familyId und groupId hinzu.
    if (groupId != null && type == 'family') {
      listData['familyId'] = groupId;
      listData['groupId'] = groupId;
    }

    await _db.collection('shoppingLists').add(listData);
    _log('Erfolgreich $type-Liste erstellt: $name');
  } catch (e) {
    _log('Fehler beim Erstellen der Einkaufsliste: $e');
    rethrow;
  }
}


  /// Allgemeine Liste für Nutzer erstellen (Typ: "personal" oder "family")
  Future<void> createShoppingListForUser(String userId, String name, String type) async {
    final listData = {
      'name': name,
      'createdBy': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'dueDate': null,
      'imagePath': '',
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

  /// Erweiterte Liste mit optionaler Familien-ID erstellen
  Future<String?> createNewShoppingList({
    required String name,
    required String userId,
    String? groupId,
    DateTime? dueDate,
    required String imagePath,
  }) async {
    try {
      final listData = {
        'name': name,
        'createdBy': userId,
        'createdAt': Timestamp.fromDate(DateTime.now()),
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
      _log('Fehler beim Erstellen der Liste: $e');
      rethrow;
    }
  }

  /// Bestehende Liste aktualisieren
  Future<void> updateList(String listId, String name, DateTime? dueDate) async {
    await _db.collection('shoppingLists').doc(listId).update({
      'name': name,
      'dueDate': dueDate,
    });
  }

  /// Liste löschen
  Future<void> deleteList(String listId) async {
    try {
      await _db.collection('shoppingLists').doc(listId).delete();
      _log('Liste $listId gelöscht');
    } catch (e) {
      _log('Fehler beim Löschen: $e');
      rethrow;
    }
  }

  /* ------------------------- ARTIKEL ------------------------- */

  /// Artikel zur Liste hinzufügen (einfach)
  Future<void> addItemToList(String listId, String itemName, {String? amount}) async {
    await _db.collection('shoppingLists').doc(listId).update({
      'items': FieldValue.arrayUnion([{
        'name': itemName,
        'completed': false,
        'amount': amount,
      }]),
    });
  }

  /// Artikelstatus aktualisieren (abgehakt oder nicht)
  Future<void> toggleItemCompletion(String listId, int index, bool completed) async {
    final doc = _db.collection('shoppingLists').doc(listId);
    final items = List.from((await doc.get()).get('items'));
    items[index]['completed'] = completed;
    await doc.update({'items': items});
  }

  /// Artikel aus Liste entfernen
  Future<void> deleteItemFromList(String listId, int index) async {
    final doc = _db.collection('shoppingLists').doc(listId);
    final items = List.from((await doc.get()).get('items'));
    items.removeAt(index);
    await doc.update({'items': items});
  }

  /// Artikel zur Familienliste hinzufügen (strukturierte Speicherung)
  Future<void> addGroceryItem(String listId, GroceryItem item) async {
    try {
      if (familyId == null) throw Exception('Family ID erforderlich');

      await _db
          .collection('families/$familyId/groceries')
          .doc(listId)
          .update({
        'items': FieldValue.arrayUnion([item.toMap()]),
      });
    } catch (e) {
      _log("Fehler beim Hinzufügen des Artikels: $e");
      rethrow;
    }
  }

  /// Artikel in der Familienliste aktualisieren
  Future<void> updateGroceryItem(String listId, GroceryItem item) async {
    try {
      if (familyId == null) throw Exception('Family ID erforderlich');

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
      _log("Fehler beim Aktualisieren des Artikels: $e");
      rethrow;
    }
  }

  /* ------------------------- PLATZHALTER ------------------------- */

  /// Platzhalter für zukünftige Funktionalität
  Future<void> fetchShoppingList(String listId) async {
    // Noch nicht implementiert
  }
}
