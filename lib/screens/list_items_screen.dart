// Vollständige ListItemsScreen mit Erklärungen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:einkaufsliste/models/shopping_list.dart';
import 'package:einkaufsliste/services/database_service.dart';

class ListItemsScreen extends StatefulWidget {
  final ShoppingList list; // Einkaufsliste, deren Items angezeigt werden
  final VoidCallback onUpdate; // Callback, um Updates von außen mitzuteilen
  final VoidCallback onDeleteList; // Callback, wenn Liste gelöscht wird
  final Function(String id, String name, DateTime? date) onEditList; // Callback für Listenedits

  const ListItemsScreen({
    super.key,
    required this.list,
    required this.onUpdate,
    required this.onDeleteList,
    required this.onEditList,
    required Future<Null> Function(dynamic listId, dynamic itemName) onAddItem,
  });

  @override
  State<ListItemsScreen> createState() => _ListItemsScreenState();
}

class _ListItemsScreenState extends State<ListItemsScreen> {
  // Controller für die Texteingabe der Item-Namen, Menge und Listenname
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _listNameController = TextEditingController();
  
  DateTime? _selectedDate; // Ausgewähltes Datum für Fälligkeitsdatum

  @override
  void initState() {
    super.initState();
    // Initialisiere den Listenname und das Datum aus der übergebenen Liste
    _listNameController.text = widget.list.name;
    _selectedDate = widget.list.dueDate;
  }

  @override
  void dispose() {
    // Speicher freigeben, wenn das Widget zerstört wird
    _itemController.dispose();
    _amountController.dispose();
    _listNameController.dispose();
    super.dispose();
  }

  // Funktion um ein neues Item hinzuzufügen
  Future<void> _addItem() async {
    if (_itemController.text.trim().isEmpty) return; // Wenn leer, nicht hinzufügen

    // Menge ist optional, wenn leer, dann null
    final amount = _amountController.text.trim().isEmpty
        ? null
        : _amountController.text.trim();

    try {
      // Hole die Datenbankinstanz aus dem Provider
      final database = Provider.of<DatabaseService>(context, listen: false);
      // Item zur Liste hinzufügen
      await database.addItemToList(
        widget.list.id,
        _itemController.text.trim(),
        amount: amount,
      );
      // Textfelder nach Hinzufügen leeren
      _itemController.clear();
      _amountController.clear();

      if (mounted) {
        setState(() {}); // UI neu bauen
        widget.onUpdate(); // Außen informieren, dass sich was geändert hat
      }
    } catch (e) {
      // Fehlerbehandlung, falls das Hinzufügen fehlschlägt
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add item: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // Öffnet den Datepicker für das Fälligkeitsdatum
  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      builder: (context, child) {
        // Styling des Datepickers anpassen
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      // Datum speichern und UI aktualisieren
      setState(() {
        _selectedDate = picked;
      });
      // Callback mit neuem Datum aufrufen
      widget.onEditList(widget.list.id, widget.list.name, _selectedDate);
    }
  }

  // Zeigt den Dialog zum Bearbeiten der Liste an (Name + Datum)
  void _showEditDialog() {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Edit List', textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Textfeld zum Bearbeiten des Listennamens
              TextField(
                controller: _listNameController,
                decoration: InputDecoration(
                  labelText: 'List Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Zeile mit Datum und Button zum Auswählen eines neuen Datums
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDate == null
                          ? 'No date selected'
                          : 'Due: ${DateFormat.yMMMd().format(_selectedDate!)}',
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: theme.primaryColor,
                    ),
                    onPressed: () => _pickDate(context),
                    child: const Text('Select Date'),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          // Abbrechen Button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: theme.hintColor)),
          ),
          // Speichern Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              // Änderungen zurückmelden und Dialog schließen
              widget.onEditList(
                widget.list.id,
                _listNameController.text.trim(),
                _selectedDate,
              );
              Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Zeigt den Bestätigungsdialog zum Löschen der Liste an
  void _confirmDeleteList() {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete List', textAlign: TextAlign.center),
        content: const Text('Are you sure you want to delete this list?'),
        actions: [
          // Abbrechen Button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: theme.hintColor)),
          ),
          // Löschen Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              // Callback zum Löschen ausführen und den Bildschirm schließen
              widget.onDeleteList();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Baut die Liste der Items mit Live-Daten aus Firestore
  Widget _buildItemsList() {
    final theme = Theme.of(context);
    final database = Provider.of<DatabaseService>(context);

    return StreamBuilder<DocumentSnapshot>(
      // Stream holt die aktuelle Einkaufsliste von Firestore
      stream: database.getShoppingList(widget.list.id),
      builder: (context, snapshot) {
        // Ladezustand anzeigen
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Expanded(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // Fehler anzeigen
        if (snapshot.hasError) {
          return Expanded(
            child: Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          );
        }

        // Wenn keine Daten vorhanden sind
        if (!snapshot.hasData) {
          return const Expanded(
            child: Center(child: Text('No data found')),
          );
        }

        // Daten aus dem Snapshot extrahieren
        final data = snapshot.data!.data() as Map<String, dynamic>;
        // Liste der Items (als Map) aus den Daten extrahieren
        final items = List<Map<String, dynamic>>.from(data['items'] ?? []);

        return Expanded(
          child: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_basket, size: 64, color: theme.hintColor),
                      const SizedBox(height: 16),
                      Text(
                        'No items yet',
                        style: TextStyle(fontSize: 18, color: theme.hintColor),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: items.length,
                  itemBuilder: (ctx, index) {
                    final item = items[index];
                    return Dismissible(
                      key: Key('$index-${item['name']}'), // Eindeutiger Key zum Löschen
                      background: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        child: Icon(Icons.delete, color: theme.colorScheme.error),
                      ),
                      secondaryBackground: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: Icon(Icons.delete, color: theme.colorScheme.error),
                      ),
                      // Bestätigungsdialog vor dem Löschen
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirm'),
                            content: const Text('Delete this item?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                      // Löschen aus der Datenbank
                      onDismissed: (direction) async {
                        await database.deleteItemFromList(widget.list.id, index);
                      },
                      child: Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CheckboxListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          title: Text(
                            item['name'],
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: theme.textTheme.bodyLarge?.color,
                              decoration: item['completed'] ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          subtitle: item['amount'] != null 
                              ? Text(
                                  'Amount: ${item['amount']}',
                                  style: TextStyle(
                                    color: theme.hintColor,
                                    decoration: item['completed'] == true
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                )
                              : null,
                          value: item['completed'],
                          // Checkbox-Status ändern und in DB speichern
                          onChanged: (value) async {
                            await database.toggleItemCompletion(widget.list.id, index, value ?? false);
                          },
                          secondary: Icon(
                            item['completed'] ? Icons.check_circle : Icons.circle,
                            color: item['completed'] ? theme.primaryColor : theme.hintColor,
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            // Falls ein Bild zur Liste existiert, zeige es an
            if (widget.list.imagePath.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Image.asset(
                  widget.list.imagePath,
                  width: 30,
                  height: 30,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.shopping_cart, color: theme.iconTheme.color),
                ),
              ),
            Expanded(
              child: Text(
                widget.list.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _showEditDialog),
          IconButton(icon: const Icon(Icons.delete), onPressed: _confirmDeleteList),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Textfeld für Itemname
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _itemController,
                    decoration: InputDecoration(
                      labelText: 'Item name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onSubmitted: (_) => _addItem(), // Enter fügt Item hinzu
                  ),
                ),
                const SizedBox(width: 8),
                // Textfeld für Menge (optional)
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'amount',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => _addItem(),
                  ),
                ),
                const SizedBox(width: 8),
                // Button zum Item hinzufügen
                IconButton(
                  icon: Icon(Icons.add_circle, color: theme.primaryColor, size: 40),
                  onPressed: _addItem,
                ),
              ],
            ),
          ),
          // Anzeige des ausgewählten Fälligkeitsdatums, falls gesetzt
          if (_selectedDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: theme.hintColor),
                  const SizedBox(width: 8),
                  Text(
                    'Due: ${DateFormat.yMMMd().format(_selectedDate!)}',
                    style: TextStyle(color: theme.hintColor),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          // Liste der Items aufbauen
          _buildItemsList(),
        ],
      ),
    );
  }
}
