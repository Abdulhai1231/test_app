import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddListScreen extends StatefulWidget {
  final Function(String id, String name, DateTime? date, String imagePath) onAddList;

  const AddListScreen({super.key, required this.onAddList});

  @override
  State<AddListScreen> createState() => _AddListScreenState();
}

class _AddListScreenState extends State<AddListScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedImagePath;

  void _submit() {
    if (_formKey.currentState!.validate() && _selectedImagePath != null) {
      widget.onAddList(
        DateTime.now().millisecondsSinceEpoch.toString(),
        _nameController.text,
        _selectedDate,
        _selectedImagePath!,
      );
      Navigator.pop(context, "refresh");
    } else if (_selectedImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
    }
  }

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _selectImage(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageSelectionScreen(
          onImageSelected: (path) {
            Navigator.pop(context, path);
          },
        ),
      ),
    );
    
    if (result != null) {
      setState(() => _selectedImagePath = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New List'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'List Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a list name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDate == null
                          ? 'No date chosen'
                          : 'Due: ${DateFormat.yMMMd().format(_selectedDate!)}',
                    ),
                  ),
                  TextButton(
                    onPressed: _pickDate,
                    child: const Text('Choose Date'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _selectedImagePath == null
                        ? const Text('No image selected')
                        : Image.asset(_selectedImagePath!, height: 80),
                  ),
                  TextButton(
                    onPressed: () => _selectImage(context),
                    child: const Text('Select Image'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                ),
                child: const Text('Create List'),
              ),
            ],
          ),
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

class ImageSelectionScreen extends StatelessWidget {
  final Function(String path) onImageSelected;

  const ImageSelectionScreen({super.key, required this.onImageSelected});

  @override
  Widget build(BuildContext context) {
    final storeImages = [
      'images/Aldi.png',
      'images/Netto.png',
      'images/Penny.png',
      'images/Rewe.png',
      'images/Lidl.png',
      'images/Kaufland.png',
      // Add more if you have other store images
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Store'),
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1,
        ),
        itemCount: storeImages.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => onImageSelected(storeImages[index]),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(storeImages[index]),
            ),
          );
        },
      ),
    );
  }
}