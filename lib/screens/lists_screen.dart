
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


class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key});

  @override
  _ListsScreenState createState() => _ListsScreenState();
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
        body: const Center(child: Text('You must be logged in')),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Lists'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My Lists'),
              Tab(text: 'Shared Lists'),
            ],
            labelColor: Color.fromARGB(255, 0, 0, 0), // Set the color for the selected tab
            unselectedLabelColor: Color.fromARGB(255, 255, 254, 254), // Set the color for the unselected tabs
          ),
        ),
        body: TabBarView(
          children: [
            _buildPersonalLists(context, database, user),
            _buildFamilyLists(context, database, familyService, user),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _navigateToCreateList(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildPersonalLists(BuildContext context, DatabaseService database, UserModel user) {
    return StreamBuilder(
      stream: database.getUserShoppingLists(user.uid),
      builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      
      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }
      
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Center(child: Text('No lists yet'));
      }
      
        
        final lists = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return ShoppingList(
            id: doc.id,
            name: data['name'] ?? 'Unnamed List',
            items: [],
            date: DateTime.now(),
            imagePath: data['imageUrl'] ?? '',
            dueDate: data['dueDate']?.toDate(),
            createdBy: user.uid,
            createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
          );
        }).toList();
        
        return ListView.builder(
          itemCount: lists.length,
          itemBuilder: (context, index) {
            final list = lists[index];
            return ListTile(
              leading: list.imagePath.isNotEmpty
                  ? Image.asset(list.imagePath, width: 50, height: 50)
                  : const Icon(Icons.list),
              trailing: list.dueDate != null 
                  ? Text(DateFormat.yMd().format(list.dueDate!))
                  : null,
              title: Text(list.name),
              subtitle: list.dueDate != null 
                  ? Text('Due: ${DateFormat.yMd().format(list.dueDate!)}')
                  : null,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ListItemsScreen(
                      list: list,
                      onAddItem: (listId, itemName) async {
                        await database.addItemToList(listId, itemName);
                      },
                      onUpdate: () {},
                      onDeleteList: () async {
                        await database.deleteList(list.id);
                      },
                      onEditList: (id, name, date) async {
                        await database.updateList(id, name, date);
                      },
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

    Widget _buildFamilyLists(
    BuildContext context,
    DatabaseService database,
    FamilyService familyService,
    UserModel user,
  ) {
    return StreamBuilder(
      stream: familyService.getUserFamilyGroups(user.uid),
      builder: (context, groupSnapshot) {
        if (groupSnapshot.hasError) {
          return Center(child: Text('Error: ${groupSnapshot.error}'));
        }
        
        if (!groupSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (groupSnapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No family groups yet'));
        }
        
        final groupId = groupSnapshot.data!.docs.first.id;
        
        return StreamBuilder<QuerySnapshot>(
  stream: database.getFamilyShoppingLists(groupId),
  builder: (context, snapshot) {
    // Handle loading state
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Handle errors
    if (snapshot.hasError) {
      final error = snapshot.error;
      
      // Special handling for index errors
      if (error is FirebaseException && error.code == 'failed-precondition') {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Database Indexing in Progress',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'This may take 2-5 minutes. Please wait...',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() {}), // Refresh
              child: const Text('Check Again'),
            ),
          ],
        );
      }
      

      // Generic error handling
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading data',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }
    
            
            final lists = snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return ShoppingList(
                id: doc.id,
                name: data['name'] ?? 'Unnamed List',
                items: [],
                date: DateTime.now(),
                imagePath: data['imageUrl'] ?? '',
                dueDate: data['dueDate']?.toDate(),
                createdBy: data['createdBy'] ?? '',
                createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
              );
            }).toList();
            
            return ListView.builder(
              itemCount: lists.length,
              itemBuilder: (context, index) {
                final list = lists[index];
                return ListTile(
                  leading: list.imagePath.isNotEmpty
                      ? Image.asset(list.imagePath, width: 50, height: 50)
                      : const Icon(Icons.list),
                  trailing: list.dueDate != null  
                      ? Text(DateFormat.yMd().format(list.dueDate!))
                      : null,
                  title: Text(list.name),
                  subtitle: Text(
                    list.dueDate != null 
                        ? 'Family List - Due: ${DateFormat.yMd().format(list.dueDate!)}'
                        : 'Family List',
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ListItemsScreen(
                          list: list,
                          onAddItem: (listId, itemName) async {
                            await database.addItemToList(listId, itemName);
                          },
                          onUpdate: () {},
                          onDeleteList: () async {
                            await database.deleteList(list.id);
                          },
                          onEditList: (id, name, date) async {
                            await database.updateList(id, name, date);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _navigateToCreateList(BuildContext context) async {
  final user = Provider.of<UserModel?>(context, listen: false);
  final database = Provider.of<DatabaseService>(context, listen: false);
  final familyService = Provider.of<FamilyService>(context, listen: false);

  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please login first')),
    );
    return;
  }

  final result = await showModalBottomSheet(
  context: context,
  backgroundColor: Colors.white, // Background color
  shape: const RoundedRectangleBorder( // Rounded corners
    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  ),
  builder: (context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Icon(Icons.person, color: Colors.blue), // Add icon
          title: const Text(
            'Personal List',
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          onTap: () => Navigator.pop(context, 'personal'),
        ),
        const Divider(height: 1), // Separator line
        ListTile(
          leading: Icon(Icons.family_restroom, color: Colors.green),
          title: const Text(
            'Family List',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          onTap: () => Navigator.pop(context, 'family'),
        ),
      ],
    ),
  ),
);

  if (result == 'personal') {
    await _createPersonalList(context, user, database);
  } else if (result == 'family') {
    await _createFamilyList(context, user, database, familyService);
  }
}

  Future<void> _createPersonalList(
    BuildContext context,
    UserModel user,
    DatabaseService database,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddListScreen(
          onAddList: (id, name, date, imagePath) async {
            await database.createShoppingList(
              name: name,
              userId: user.uid,
              dueDate: date,
              imagePath: imagePath,
            );
          },
        ),
      ),
    );
  }

  Future<void> _createFamilyList(
    BuildContext context,
    UserModel user,
    DatabaseService database,
    FamilyService familyService,
  ) async {
    final groups = await familyService.getUserFamilyGroups(user.uid).first;
    if (groups.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to join a family group first')),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddListScreen(
          onAddList: (id, name, date, imagePath) async {
            await database.createShoppingList(
            name: name,
            userId: user.uid,
            dueDate: date,
            imagePath: imagePath,
          );
          },
        ),
      ),
    );
  }
}