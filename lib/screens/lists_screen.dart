import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:einkaufsliste/models/shopping_list.dart';
import 'package:einkaufsliste/models/user_model.dart';
import 'package:einkaufsliste/screens/list_items_screen.dart';
import 'package:einkaufsliste/services/database_service.dart';
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

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Lists')),
        body: const Center(child: Text('Please sign in to view your lists')),
      );
    }

    // Debug current user and familyId (optional)
    debugPrint('Logged in user: ${user.uid}');
    debugPrint('User familyId: ${user.familyId ?? 'None'}');

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
  return RefreshIndicator(
    onRefresh: () async {
      setState(() {}); // rebuild widget to refresh data
      // You can also add additional refresh logic here if needed
    },
    child: StreamBuilder<QuerySnapshot>(
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
          physics: const AlwaysScrollableScrollPhysics(), // ensures list is scrollable even if not full
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

Widget _buildFamilyLists(BuildContext context, UserModel user) {
  return FutureBuilder<String?>(
    future: _verifyFamilyMembership(context, user.uid),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      final familyId = snapshot.data;
      if (familyId == null || familyId.isEmpty) {
        return const Center(child: Text('No family lists available.'));
      }

      return RefreshIndicator(
        onRefresh: () async {
          setState(() {}); // rebuild widget to refresh data
          // additional refresh logic can go here if necessary
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
                    onTap: () => _navigateToListItems(context, list, Provider.of<DatabaseService>(context, listen: false)),
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
    final user = Provider.of<UserModel?>(context, listen: false);
    final database = Provider.of<DatabaseService>(context, listen: false);

    if (user == null) {
      debugPrint('User is null - cannot create list');
      return;
    }

    debugPrint('Creating ${isShared ? 'family' : 'personal'} list for user: ${user.uid}');
    debugPrint('Current user familyId: ${user.familyId ?? 'None'}');

    String? groupId;
    if (isShared) {
      final currentFamilyId = user.familyId != null && user.familyId!.isNotEmpty
          ? user.familyId
          : await _verifyFamilyMembership(context, user.uid);
      if (currentFamilyId == null) {
        if (!context.mounted) return;
        _showFamilyGroupRequiredDialog(context);
        return;
      }
      groupId = currentFamilyId;
      debugPrint('Verified family membership for user ${user.uid}: $groupId');
    }

    if (!context.mounted) return;

    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddListScreen(
            onAddList: (id, name, date, imagePath) async {
              try {
                debugPrint('Creating ${isShared ? 'family' : 'personal'} list: $name');
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
                debugPrint('Error creating list: $e');
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
      debugPrint('Navigation error: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<String?> _verifyFamilyMembership(BuildContext context, String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        debugPrint('User document does not exist for userId: $userId');
        return null;
      }

      final data = userDoc.data();
      final familyId = data?['familyId'];

      if (familyId == null || (familyId is String && familyId.isEmpty)) {
        debugPrint('No valid familyId found for userId: $userId');
        return null;
      }

      debugPrint('✅ Found familyId: $familyId for userId: $userId');
      return familyId as String;
    } catch (e) {
      debugPrint('Error verifying family membership: $e');
      return null;
    }
  }

  void _showFamilyGroupRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Family Group Required'),
        content: const Text(
            'You need to be part of a family group to create a shared list. Please create or join a family group first.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FamilyGroupScreen()),
              );
            },
            child: const Text('Go to Family Group'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  Stream<QuerySnapshot> getPendingInvites(String userEmail) {
  return FirebaseFirestore.instance
      .collection('familyGroups')
      .where('pendingInvites', arrayContains: userEmail.toLowerCase())
      .snapshots();
}


  Future<void> _navigateToListItems(
      BuildContext context, ShoppingList list, DatabaseService database) async {
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
