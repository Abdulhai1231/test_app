class GroceryItem {
  final String name;     // Name des Artikels, z.B. "Milch"
  final int amount;      // Menge, z.B. 2 (Liter, Stück, etc.)
  bool isBought;         // Status: gekauft oder nicht

  GroceryItem({
    required this.name,
    required this.amount,
    this.isBought = false, // Standard: noch nicht gekauft
  });

  // Methode, um das Objekt in ein Map für Firestore zu konvertieren
  Map<String, dynamic> toMap() => {
    'name': name,
    'amount': amount,
    'isBought': isBought,
  };

  // Factory-Konstruktor zum Erstellen eines GroceryItems aus Map (z.B. Firestore-Daten)
  factory GroceryItem.fromMap(Map<String, dynamic> map) => GroceryItem(
    name: map['name'],
    amount: map['amount'],
    isBought: map['isBought'] ?? false,  // Falls isBought nicht gesetzt, Standard false
  );
}
