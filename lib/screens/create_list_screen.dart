import 'package:flutter/material.dart';

class CreateListScreen extends StatefulWidget {
  final Function(String name, bool isFamilyList) onCreateList;

  const CreateListScreen({
    super.key,
    required this.onCreateList,
  });

  @override
  State<CreateListScreen> createState() => _CreateListScreenState();
}

class _CreateListScreenState extends State<CreateListScreen> {
  final _nameController = TextEditingController();
  bool _isFamilyList = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New List')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'List Name'),
            ),
            CheckboxListTile(
              title: const Text('Family List'),
              value: _isFamilyList,
              onChanged: (value) => setState(() => _isFamilyList = value ?? false),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty) {
                  widget.onCreateList(_nameController.text, _isFamilyList);
                  Navigator.pop(context);
                }
              },
              child: const Text('Create List'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}