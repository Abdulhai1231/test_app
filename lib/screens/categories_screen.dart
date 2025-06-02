import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/category.dart';
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Hole die Instanz des DatabaseService über Provider
    final database = Provider.of<DatabaseService>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        centerTitle: true,
        elevation: 0,
      ),
      // Hintergrund mit Farbverlauf
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        // StreamBuilder zum Abonnieren der Kategorie-Daten aus der Datenbank
        child: StreamBuilder<List<Category>>(
          stream: database.categoriesStream(),
          builder: (context, snapshot) {
            // Fehlerzustand anzeigen, wenn Stream einen Fehler liefert
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              );
            }

            // Ladeanzeige anzeigen, wenn noch keine Daten vorliegen
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final categories = snapshot.data!;

            // Falls keine Kategorien vorhanden sind, freundliche Meldung anzeigen
            if (categories.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.category, size: 64, color: theme.hintColor),
                    const SizedBox(height: 16),
                    Text(
                      'No categories yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the + button to add one',
                      style: TextStyle(color: theme.hintColor),
                    ),
                  ],
                ),
              );
            }

            // Liste der Kategorien anzeigen
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.category, color: theme.colorScheme.primary),
                    ),
                    title: Text(
                      category.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    // Löschen-Button mit Bestätigung
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: theme.colorScheme.error),
                      onPressed: () => _confirmDeleteCategory(
                        context, database, category.id),
                    ),
                    onTap: () {
                      // Hier könnte man z.B. zu den Elementen der Kategorie navigieren
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
      // Button zum Hinzufügen einer neuen Kategorie
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddCategoryDialog(context, database),
      ),
    );
  }

  // Dialog zum Hinzufügen einer neuen Kategorie
  void _showAddCategoryDialog(BuildContext context, DatabaseService database) {
    final controller = TextEditingController();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Add Category', textAlign: TextAlign.center),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Category name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
          ),
          autofocus: true,
        ),
        actions: [
          // Abbrechen-Button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: theme.hintColor)),
          ),
          // Hinzufügen-Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              // Nur hinzufügen, wenn der Name nicht leer ist
              if (controller.text.trim().isNotEmpty) {
                await database.addCategory(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Dialog zur Bestätigung des Löschens einer Kategorie
  void _confirmDeleteCategory(
    BuildContext context, DatabaseService database, String categoryId) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Category', textAlign: TextAlign.center),
        content: const Text('Are you sure you want to delete this category?'),
        actions: [
          // Abbrechen-Button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: theme.hintColor)),
          ),
          // Löschen-Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              // Hier solltest du die Löschfunktion im DatabaseService aufrufen
              // await database.deleteCategory(categoryId);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
