import 'package:einkaufsliste/screens/image_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddListScreen extends StatefulWidget {
  // Callback, das beim Erstellen der Liste aufgerufen wird mit id, name, datum und Bildpfad
  final Function(String id, String name, DateTime? date, String imagePath) onAddList;

  const AddListScreen({super.key, required this.onAddList});

  @override
  State<AddListScreen> createState() => _AddListScreenState();
}

class _AddListScreenState extends State<AddListScreen> {
  // Formular-Key zur Validierung
  final _formKey = GlobalKey<FormState>();
  // Controller für das Eingabefeld des Listen-Namens
  final _nameController = TextEditingController();
  // Ausgewähltes Datum (optional)
  DateTime? _selectedDate;
  // Ausgewählter Bildpfad (optional)
  String? _selectedImagePath;

  // Methode zum Absenden des Formulars
  void _submit() {
    // Nur absenden, wenn Formular gültig ist und ein Bild ausgewählt wurde
    if (_formKey.currentState!.validate() && _selectedImagePath != null) {
      widget.onAddList(
        DateTime.now().millisecondsSinceEpoch.toString(), // eindeutige ID
        _nameController.text,
        _selectedDate,
        _selectedImagePath!,
      );
      // Bildschirm schließen und "refresh" zurückgeben
      Navigator.pop(context, "refresh");
    } else if (_selectedImagePath == null) {
      // Zeige Hinweis, wenn kein Bild ausgewählt wurde
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select an image'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // Öffnet den Datumsauswahldialog
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      builder: (context, child) {
        // Thema für den DatePicker anpassen
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    // Wenn ein Datum gewählt wurde, speichern und UI aktualisieren
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // Öffnet die Bildauswahl-Screen und speichert das Ergebnis
  Future<void> _selectImage(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ImageSelectionScreen(),
      ),
    );
    
    // Wenn ein Bild ausgewählt wurde, in den State übernehmen
    if (result != null) {
      setState(() => _selectedImagePath = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Shopping List'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Überschrift des Formulars
              Text(
                'List Details',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Beschreibungstext unter der Überschrift
              Text(
                'Fill in the details for your new shopping list',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 32),
              
              // Eingabefeld für den Listennamen mit Validierung
              TextFormField(
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a list name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Bereich für Datumsauswahl (öffnet DatePicker)
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _selectedDate == null
                              ? 'Select due date'
                              : 'Due: ${DateFormat.yMMMd().format(_selectedDate!)}',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Bereich für Bildauswahl (öffnet ImageSelectionScreen)
              InkWell(
                onTap: () => _selectImage(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.store,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Store Logo',
                            style: theme.textTheme.bodyLarge,
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ],
                      ),
                      // Wenn ein Bild ausgewählt ist, zeige Vorschaubild
                      if (_selectedImagePath != null) ...[
                        const SizedBox(height: 12),
                        Center(
                          child: Image.asset(
                            _selectedImagePath!,
                            height: 60,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              // Button zum Erstellen der Liste
              ElevatedButton(
                onPressed: _submit,
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
      ),
    );
  }

  // Ressourcen aufräumen
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
