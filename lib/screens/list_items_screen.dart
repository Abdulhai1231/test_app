import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:einkaufsliste/models/shopping_list.dart';
import 'package:einkaufsliste/providers/theme_provider.dart';
import 'package:einkaufsliste/services/database_service.dart';

class ListItemsScreen extends StatefulWidget {
  final ShoppingList list;
  final Function(String listId, String itemName) onAddItem;
  final VoidCallback onUpdate;
  final VoidCallback onDeleteList;
  final Function(String id, String name, DateTime? date) onEditList;

  const ListItemsScreen({
    super.key,
    required this.list,
    required this.onAddItem,
    required this.onUpdate,
    required this.onDeleteList,
    required this.onEditList,
  });

  @override
  State<ListItemsScreen> createState() => _ListItemsScreenState();
}

class _ListItemsScreenState extends State<ListItemsScreen> {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _listNameController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _listNameController.text = widget.list.name;
    _selectedDate = widget.list.dueDate;
  }

  @override
  void dispose() {
    _itemController.dispose();
    _listNameController.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    if (_itemController.text.trim().isEmpty) return;
    
    try {
      final database = Provider.of<DatabaseService>(context, listen: false);
      await database.addItemToList(widget.list.id, _itemController.text.trim());
      _itemController.clear();
      if (mounted) {
        setState(() {});
      }
      widget.onUpdate();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add item: ${e.toString()}')),
        );
      }
    }
  }

  void _toggleItemDone(int index, bool? value) {
    setState(() {
      widget.list.items[index].done = value ?? false;
    });
    widget.onUpdate();
  }

  void _deleteItem(int index) {
    setState(() {
      widget.list.items.removeAt(index);
    });
    widget.onUpdate();
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      widget.onEditList(widget.list.id, widget.list.name, _selectedDate);
    }
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit List'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _listNameController,
                decoration: const InputDecoration(labelText: 'List Name'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDate == null
                          ? 'No date selected'
                          : 'Due: ${DateFormat.yMMMd().format(_selectedDate!)}',
                    ),
                  ),
                  TextButton(
                    onPressed: () => _pickDate(context),
                    child: const Text('Select Date'),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.onEditList(
                widget.list.id,
                _listNameController.text.trim(),
                _selectedDate,
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteList() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete List'),
        content: const Text('Are you sure you want to delete this list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.onDeleteList();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final database = Provider.of<DatabaseService>(context);

    return StreamBuilder<DocumentSnapshot>(
      stream: database.getShoppingList(widget.list.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Expanded(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasError) {
          return Expanded(
            child: Center(child: Text('Error: ${snapshot.error}')),
          );
        }
        
        if (!snapshot.hasData) {
          return const Expanded(
            child: Center(child: Text('No data found')),
          );
        }
        
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
        
        return Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    'No items yet.',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (ctx, index) {
                    final item = items[index];
                    return Card(
                      color: isDarkMode ? Colors.grey[800] : Colors.white,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8, 
                        vertical: 4
                      ),
                      child: CheckboxListTile(
                        title: Text(
                          item['name'],
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                            decoration: item['completed'] 
                                ? TextDecoration.lineThrough 
                                : null,
                          ),
                        ),
                        value: item['completed'],
                        onChanged: (value) async {
                          await database.toggleItemCompletion(
                            widget.list.id, 
                            index, 
                            value ?? false
                          );
                          if (mounted) {
                            setState(() {});
                          }
                        },
                        secondary: IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: isDarkMode 
                                ? Colors.white70 
                                : Colors.black54,
                          ),
                          onPressed: () async {
                            await database.deleteItemFromList(
                              widget.list.id, 
                              index
                            );
                            if (mounted) {
                              setState(() {});
                            }
                          },
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode 
          ? Colors.grey[850] 
          : const Color.fromARGB(255, 252, 252, 252),
      appBar: AppBar(
        backgroundColor: isDarkMode 
            ? Colors.grey[900] 
            : const Color.fromARGB(255, 60, 225, 247),
        title: Row(
          children: [
            if (widget.list.imagePath.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Image.asset(
                  widget.list.imagePath,
                  width: 30,
                  height: 30,
                  errorBuilder: (context, error, stackTrace) => 
                      const Icon(Icons.shopping_cart),
                ),
              ),
            Text(widget.list.name),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditDialog,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDeleteList,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _itemController,
                    decoration: InputDecoration(
                      labelText: 'Add new item',
                      labelStyle: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    onSubmitted: (_) => _addItem(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addItem,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ],
            ),
          ),
          _buildItemsList(),
        ],
      ),
    );
  }
}