// Importiere notwendige Pakete
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:einkaufsliste/screens/invitationsscreen.dart';
import 'package:einkaufsliste/services/family_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:einkaufsliste/models/shopping_list.dart';
import 'package:einkaufsliste/models/user_model.dart';
import 'package:einkaufsliste/screens/list_items_screen.dart';
import 'package:einkaufsliste/services/database_service.dart';
import 'package:einkaufsliste/screens/add_list_screen.dart';
import 'package:einkaufsliste/screens/family_group_screen.dart';

// Hauptbildschirm für persönliche und familiäre Einkaufslisten
class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key});

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    final database = Provider.of<DatabaseService>(context);

    // Falls der Benutzer nicht angemeldet ist, zeige eine Nachricht
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Lists')),
        body: const Center(child: Text('Please sign in to view your lists')),
      );
    }

    // Debug-Ausgabe: aktueller Benutzer und dessen Family ID
    debugPrint('Logged in user: ${user.uid}');
    debugPrint('User familyId: ${user.familyId ?? 'None'}');

    return DefaultTabController(
      length: 2, // Zwei Tabs: Personal und Family
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Lists'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Personal'),
              Tab(text: 'Family'),
            ],
          ),
          actions: [
            // Button zum Verwalten der Familiengruppe
            IconButton(
              icon: const Icon(Icons.group),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FamilyGroupScreen(),
                ),
              ),
              tooltip: 'Manage Family Group',
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildPersonalLists(context, database, user), // Persönliche Listen
            _buildFamilyLists(context, user),             // Familiäre Listen
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showListTypeBottomSheet(context), // Neue Liste hinzufügen
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  // Zeigt persönliche Listen in einer ListView an
  Widget _buildPersonalLists(BuildContext context, DatabaseService database, UserModel user) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {}); // Aktualisiert die UI
      },
      child: StreamBuilder<QuerySnapshot>(
        stream: database.getUserShoppingLists(user.uid), // Stream für persönliche Listen
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No personal lists yet'));
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final list = ShoppingList(
                id: doc.id,
                name: data['name'] ?? 'Unnamed List',
                createdBy: data['createdBy'] ?? user.uid,
                createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                items: [],
                date: DateTime.now(),
                imagePath: data['imagePath'] ?? '',
                dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
              );

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: list.imagePath.isNotEmpty
                      ? Image.asset(list.imagePath, width: 40, height: 40)
                      : const Icon(Icons.shopping_cart),
                  title: Text(list.name),
                  subtitle: list.dueDate != null
                      ? Text('Due: ${DateFormat.yMd().format(list.dueDate!)}')
                      : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _navigateToListItems(context, list, database),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Zeigt familiäre Listen an, falls Benutzer Teil einer Family Group ist
  Widget _buildFamilyLists(BuildContext context, UserModel user) {
    return FutureBuilder<String?>(
      future: _verifyFamilyMembership(context, user.uid), // Prüft Family-Mitgliedschaft
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final familyId = snapshot.data;

        // Zeigt Optionen zum Erstellen oder Beitreten an, wenn kein Family Group vorhanden
        if (familyId == null || familyId.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No family group found'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _showCreateFamilyDialog(context),
                  child: const Text('Create Family Group'),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.mail_outline),
                  label: const Text('Check Invitations'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const InvitationsScreen()),
                    );
                  },
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {}); // UI aktualisieren
          },
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('shoppingLists')
                .where('familyId', isEqualTo: familyId)
                .where('type', isEqualTo: 'family')
                .snapshots(),
            builder: (context, listSnapshot) {
              if (listSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (listSnapshot.hasError) {
                return Center(child: Text('Error: ${listSnapshot.error}'));
              }

              if (!listSnapshot.hasData || listSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No family lists found.'));
              }

              // Debug-Ausgabe
              if (listSnapshot.hasData) {
                debugPrint('Family lists docs count: ${listSnapshot.data!.docs.length}');
                for (var doc in listSnapshot.data!.docs) {
                  debugPrint('Family list doc: ${doc.id} - ${doc.data()}');
                }
              }

              final docs = listSnapshot.data!.docs;

              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final list = ShoppingList(
                    id: doc.id,
                    name: data['name'] ?? 'Unnamed List',
                    createdBy: data['createdBy'] ?? '',
                    createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                    items: [],
                    date: DateTime.now(),
                    imagePath: data['imagePath'] ?? '',
                    dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
                  );

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      leading: list.imagePath.isNotEmpty
                          ? Image.asset(list.imagePath, width: 40, height: 40)
                          : const Icon(Icons.shopping_cart),
                      title: Text(list.name),
                      subtitle: list.dueDate != null
                          ? Text('Due: ${DateFormat.yMd().format(list.dueDate!)}')
                          : null,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _navigateToListItems(
                          context, list, Provider.of<DatabaseService>(context, listen: false)),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  // Dialog zum Erstellen einer neuen Familiengruppe
  void _showCreateFamilyDialog(BuildContext context) {
    final familyService = Provider.of<FamilyService>(context, listen: false);
    final currentUser = Provider.of<UserModel?>(context, listen: false);
    if (currentUser == null) return;

    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Family Group'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Family Name',
            hintText: 'e.g. Smith Family',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                try {
                  await familyService.createFamilyGroup(controller.text);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Family group created!')),
                    );
                    setState(() {}); // Seite neu laden
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  // Zeigt Auswahl zwischen persönlicher und geteilter Liste
  Future<void> _showListTypeBottomSheet(BuildContext context) async {
    final user = Provider.of<UserModel?>(context, listen: false);
    if (user == null) return;

    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Create Personal List'),
            onTap: () => Navigator.pop(context, 'personal'),
          ),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('Create Shared List'),
            onTap: () async {
              final hasFamily = await _verifyFamilyMembership(context, user.uid) != null;
              if (!hasFamily && context.mounted) {
                Navigator.pop(context);
                _showFamilyRequiredNotification(context);
              } else {
                Navigator.pop(context, 'shared');
              }
            },
          ),
        ],
      ),
    );

    if (result == 'personal') {
      await _navigateToCreateList(context, false);
    } else if (result == 'shared') {
      await _navigateToCreateList(context, true);
    }
  }

  // Zeigt SnackBar wenn keine Familiengruppe vorhanden ist
  void _showFamilyRequiredNotification(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('You need to join or create a family group first'),
        action: SnackBarAction(
          label: 'Go to Family',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FamilyGroupScreen()),
            );
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Leitet zur Bildschirm zum Erstellen einer neuen Liste weiter
  Future<void> _navigateToCreateList(BuildContext context, bool isShared) async {
    final user = Provider.of<UserModel?>(context, listen: false);
    final database = Provider.of<DatabaseService>(context, listen: false);

    if (user == null) return;

    String? groupId;
    if (isShared) {
      final currentFamilyId = user.familyId != null && user.familyId!.isNotEmpty
          ? user.familyId
          : await _verifyFamilyMembership(context, user.uid);
      if (currentFamilyId == null) {
        if (!context.mounted) return;
        _showFamilyRequiredNotification(context);
        return;
      }
      groupId = currentFamilyId;
    }

    if (!context.mounted) return;

    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddListScreen(
            onAddList: (id, name, date, imagePath) async {
              try {
                await database.createShoppingList(
                  name: name,
                  userId: user.uid,
                  dueDate: date ?? DateTime.now(),
                  imagePath: imagePath,
                  groupId: groupId,
                  type: isShared ? 'family' : 'personal',
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${isShared ? 'Family' : 'Personal'} list created!')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to create list: ${e.toString()}')),
                );
              }
            },
          ),
        ),
      );

      if (result == 'refresh') {
        setState(() {});
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  // Überprüft ob der Benutzer einer Family Group angehört
  Future<String?> _verifyFamilyMembership(BuildContext context, String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (!userDoc.exists) return null;

      final data = userDoc.data();
      final familyId = data?['familyId'];

      if (familyId == null || (familyId is String && familyId.isEmpty)) return null;

      return familyId as String;
    } catch (e) {
      debugPrint('Error verifying family membership: $e');
      return null;
    }
  }

  // Navigiert zum Detailbildschirm einer Liste
  Future<void> _navigateToListItems(
    BuildContext context,
    ShoppingList list,
    DatabaseService database,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ListItemsScreen(
          list: list,
          onAddItem: (listId, itemName) async {
            await database.addItemToList(listId, itemName, amount: '');
          },
          onUpdate: () => setState(() {}),
          onDeleteList: () async {
            await database.deleteList(list.id);
            if (!mounted) return;
            Navigator.pop(context, 'deleted');
          },
          onEditList: (id, name, date) async {
            await database.updateList(id, name, date ?? DateTime.now());
          },
        ),
      ),
    );

    if (result == 'deleted') {
      setState(() {}); // Liste neu laden nach Löschung
    }
  }
}
