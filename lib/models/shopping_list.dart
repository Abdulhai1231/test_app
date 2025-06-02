import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ShoppingItem {
  final String name;         // Name des Einkaufsartikels
  final String addedBy;      // Wer den Artikel hinzugefügt hat (User-ID oder Name)
  bool completed;            // Status: Abgehakt oder nicht
  final DateTime addedAt;    // Zeitpunkt der Hinzufügung
  int priority;              // Priorität (z.B. 1=hoch, 2=mittel, 3=low)

  ShoppingItem({
    required this.name,
    required this.addedBy,
    required this.completed,
    required this.addedAt,
    this.priority = 2,
  });

  // Factory-Konstruktor zur Erstellung aus einer Map (z.B. Firestore-Daten)
  factory ShoppingItem.fromMap(Map map) {
    return ShoppingItem(
      name: map['name'] ?? '',
      addedBy: map['addedBy'] ?? '',
      completed: map['completed'] ?? false,
      addedAt: (map['addedAt'] as Timestamp).toDate(),
      priority: map['priority'] ?? 2,
    );
  }

  // Getter und Setter für das Erledigt-Flag (abgehakt)
  bool get done => completed;

  set done(bool value) {
    completed = value;
  }
}

class ShoppingList {
  final String id;              // Firestore-Dokument-ID
  final String name;            // Name der Einkaufsliste
  final String createdBy;       // Wer die Liste erstellt hat (User-ID)
  final DateTime createdAt;     // Wann die Liste erstellt wurde
  final String? familyId;       // Zugehörige Familien-ID (null = persönliche Liste)
  final List<ShoppingItem> items; // Liste der Einkaufsartikel
  final DateTime date;          // Datum (z.B. wann die Liste benutzt wird)
  final String imagePath;       // Pfad zum Bild (z.B. Icon oder Foto)
  final DateTime? dueDate;      // Optionales Fälligkeitsdatum

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

  // Factory-Konstruktor zum Erstellen aus Firestore-Dokument
  factory ShoppingList.fromFirestore(DocumentSnapshot doc) {
    try {
      Map data = doc.data() as Map;
      return ShoppingList(
        id: doc.id,
        name: data['name'] ?? 'Unnamed List',
        createdBy: data['createdBy'] ?? '', // Wichtig für Zugriffsrechte
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        familyId: data['familyId'], // null bedeutet persönliche Liste
        items: (data['items'] as List? ?? []).map((item) {
          try {
            return ShoppingItem.fromMap(item as Map);
          } catch (e) {
            debugPrint('Error parsing shopping item: $e');
            // Fallback-Item bei Fehler im Einzel-Item
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
      // Fallback-Liste bei Parsingfehler
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
