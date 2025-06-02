import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/family_service.dart';

class InviteMemberScreen extends StatefulWidget {
  final String groupId; // ID der Familiengruppe, in die eingeladen wird

  const InviteMemberScreen({super.key, required this.groupId});

  @override
  State<InviteMemberScreen> createState() => _InviteMemberScreenState();
}

class _InviteMemberScreenState extends State<InviteMemberScreen> {
  final _formKey = GlobalKey<FormState>(); // Key für das Formular (zur Validierung)
  final _emailController = TextEditingController(); // Controller für das Email-Eingabefeld

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invite Member')), // AppBar mit Titel
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Formular mit Validierungs-Key
          child: Column(
            children: [
              // Eingabefeld für die Email-Adresse
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  // Einfache Validierung: Email muss ein '@' enthalten
                  if (value == null || !value.contains('@')) {
                    return 'Enter valid email';
                  }
                  return null; // Validierung ok
                },
              ),

              const SizedBox(height: 20),

              // Button zum Absenden der Einladung
              ElevatedButton(
                child: const Text('Send Invitation'),
                onPressed: () async {
                  // Prüfe zuerst, ob das Formular valide ist
                  if (_formKey.currentState!.validate()) {
                    try {
                      // Rufe die Methode inviteMember aus FamilyService auf
                      await Provider.of<FamilyService>(context, listen: false)
                          .inviteMember(widget.groupId, _emailController.text);

                      // Zeige Erfolgsmeldung
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invitation sent')));

                      // Schließe den Screen und gehe zurück
                      Navigator.pop(context);
                    } catch (e) {
                      // Bei Fehler eine Fehlermeldung anzeigen
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString()}')));
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Den Controller aufräumen, wenn das Widget entfernt wird
    _emailController.dispose();
    super.dispose();
  }
}
