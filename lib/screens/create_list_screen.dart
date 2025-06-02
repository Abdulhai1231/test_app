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
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New List'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const SizedBox(height: 16),
            Text(
              'New Shopping List',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Organize your groceries with a new list',
              style: theme.textTheme.bodyMedium?.copyWith(
                // ignore: deprecated_member_use
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            
            // Name Input
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'List Name',
                prefixIcon: const Icon(Icons.list_alt),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 24),
            
            // Family List Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: SwitchListTile(
                title: Text(
                  'Family List',
                  style: theme.textTheme.bodyLarge,
                ),
                subtitle: Text(
                  'Share this list with your family members',
                  style: theme.textTheme.bodySmall,
                ),
                value: _isFamilyList,
                onChanged: (value) => setState(() => _isFamilyList = value),
                secondary: const Icon(Icons.group),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 40),
            
            // Create Button
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty) {
                  widget.onCreateList(_nameController.text, _isFamilyList);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'CREATE LIST',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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