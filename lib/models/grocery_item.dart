class GroceryItem {
  final String name;
  final int amount;
  bool isBought;

  GroceryItem({
    required this.name,
    required this.amount,
    this.isBought = false,
  });

  // Add these methods for Firestore compatibility
  Map<String, dynamic> toMap() => {
    'name': name,
    'amount': amount,
    'isBought': isBought,
  };

  factory GroceryItem.fromMap(Map<String, dynamic> map) => GroceryItem(
    name: map['name'],
    amount: map['amount'],
    isBought: map['isBought'] ?? false,
  );
}