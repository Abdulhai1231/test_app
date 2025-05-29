import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:einkaufsliste/models/shopping_list.dart';
import 'package:einkaufsliste/models/user_model.dart';
import 'package:einkaufsliste/screens/list_items_screen.dart';
import 'package:einkaufsliste/services/database_service.dart';
import 'package:einkaufsliste/services/family_service.dart';
import 'package:einkaufsliste/screens/add_list_screen.dart';
import 'package:einkaufsliste/screens/family_group_screen.dart';

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
    final familyService = Provider.of<FamilyService>(context);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Lists')),
        body: const Center(child: Text('Please sign in to view your lists')),
      );
    }

    return DefaultTabController(
      length: 2,
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
            _buildPersonalLists(context, database, user),
            _buildFamilyLists(context, user),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showListTypeBottomSheet(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildPersonalLists(BuildContext context, DatabaseService database, UserModel user) {
    return StreamBuilder<QuerySnapshot>(
      stream: database.getUserShoppingLists(user.uid),
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
    );
  }

  Widget _buildFamilyLists(BuildContext context, UserModel user) {
    if (user.familyId == null || user.familyId!.isEmpty) {
      return const Center(child: Text('No family lists available.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('shoppingLists')
          .where('groupId', isEqualTo: user.familyId)
          .where('type', isEqualTo: 'family')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No family lists found.'));
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
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
                onTap: () => _navigateToListItems(context, list, Provider.of<DatabaseService>(context, listen: false)),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showListTypeBottomSheet(BuildContext context) async {
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
            onTap: () => Navigator.pop(context, 'shared'),
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

  Future<void> _navigateToCreateList(BuildContext context, bool isShared) async {
    final user = Provider.of<UserModel?>(context);
    final database = Provider.of<DatabaseService>(context, listen: false);
    final familyService = Provider.of<FamilyService>(context, listen: false);

    if (user == null) return;

    String groupId = '';

    if (isShared) {
      if (user.familyId == null || user.familyId!.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please create or join a family group first'),
            action: SnackBarAction(
              label: 'Create',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FamilyGroupScreen(),
                  ),
                );
              },
            ),
          ),
        );
        return;
      }
      groupId = user.familyId!;
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddListScreen(
          onAddList: (id, name, date, imagePath) async {
            await database.createShoppingList(
              name: name,
              userId: user.uid,
              dueDate: date ?? DateTime.now(),
              imagePath: imagePath,
              groupId: isShared ? groupId : '',
              type: isShared ? 'family' : 'personal',
            );
          },
        ),
      ),
    );
  }

  Future<void> _navigateToListItems(BuildContext context, ShoppingList list, DatabaseService database) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ListItemsScreen(
          list: list,
          onAddItem: (listId, itemName) async {
            await database.addItemToList(listId, itemName);
          },
          onUpdate: () => setState(() {}),
          onDeleteList: () async {
            await database.deleteList(list.id);
            if (!mounted) return;
            Navigator.pop(context);
          },
          onEditList: (id, name, date) async {
            await database.updateList(id, name, date ?? DateTime.now());
          },
        ),
      ),
    );
  }
}
