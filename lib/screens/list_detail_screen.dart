import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/database_service.dart';

class ListDetailScreen extends StatefulWidget {
  final String listId; // ID der Einkaufsliste, die angezeigt wird

  const ListDetailScreen({super.key, required this.listId});

  @override
  _ListDetailScreenState createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  final TextEditingController _itemController = TextEditingController();
  // Controller für das Textfeld, in dem neue Items eingegeben werden

  @override
  Widget build(BuildContext context) {
    // Hole die Instanz von DatabaseService über Provider
    final dbService = Provider.of<DatabaseService>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Shopping List')),
      body: StreamBuilder<DocumentSnapshot>(
        // StreamBuilder hört auf Firestore-Dokument (Einkaufsliste)
        stream: dbService.getShoppingList(widget.listId),
        builder: (context, snapshot) {
          // Wenn noch keine Daten da sind, zeige Ladeanzeige
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          var list = snapshot.data!; // Das Firestore-Dokument der Einkaufsliste
          List items = list.get('items') ?? []; // Liste der Items aus dem Dokument holen

          return Column(
            children: [
              // Überschrift: Name der Einkaufsliste
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  list['name'], // Name aus Firestore-Dokument
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),

              // Liste der Items in der Einkaufsliste
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return CheckboxListTile(
                      title: Text(items[index]['name']), // Name des Items
                      value: items[index]['completed'], // Erledigt-Status
                      onChanged: (value) => dbService.toggleItemCompletion(
                        widget.listId, index, value!), // Status in DB aktualisieren
                    );
                  },
                ),
              ),

              // Eingabefeld mit Button zum Hinzufügen eines neuen Items
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    // Textfeld für den Namen des neuen Items
                    Expanded(
                      child: TextField(
                        controller: _itemController,
                        decoration: InputDecoration(labelText: 'Add item'),
                      ),
                    ),

                    // Button zum Hinzufügen des Items
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        // Nur hinzufügen, wenn Textfeld nicht leer ist
                        if (_itemController.text.isNotEmpty) {
                          // Item zur Liste hinzufügen (Menge leer lassen)
                          dbService.addItemToList(
                            widget.listId, _itemController.text, amount: '');
                          _itemController.clear(); // Eingabefeld leeren
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    // Den Controller aufräumen, wenn das Widget weg ist
    _itemController.dispose();
    super.dispose();
  }
}
