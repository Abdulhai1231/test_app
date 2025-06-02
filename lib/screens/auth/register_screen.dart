import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart' show AuthService;
import '../services/auth_service.dart';

// StatefulWidget für die Registrierungsseite
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // GlobalKey für das Formular, um Validierung zu ermöglichen
  final _formKey = GlobalKey<FormState>();

  // Textcontroller für Eingabefelder
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  // Ladezustand während der Registrierung
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Zugriff auf AuthService via Provider
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey, // Form mit Validierung
          child: Column(
            children: [
              // Eingabefeld für vollständigen Namen
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) => value!.isEmpty ? 'Enter name' : null, // Validierung
              ),
              // Eingabefeld für Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => value!.isEmpty ? 'Enter email' : null, // Validierung
              ),
              // Eingabefeld für Passwort
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true, // Passwort verdeckt eingeben
                validator: (value) => value!.length < 6
                    ? 'Minimum 6 characters'
                    : null, // Passwort-Länge prüfen
              ),
              const SizedBox(height: 20),
              // Zeige Ladeanzeige oder Registrierungsbutton
              _isLoading
                  ? const CircularProgressIndicator() // Ladeindikator
                  : ElevatedButton(
                      onPressed: () async {
                        // Prüfe, ob Formular gültig ist
                        if (_formKey.currentState!.validate()) {
                          setState(() => _isLoading = true); // Ladezustand setzen
                          try {
                            // Registrierung aufrufen
                            await authService.registerWithEmailAndPassword(
                              _emailController.text,
                              _passwordController.text,
                              _nameController.text,
                            );
                            Navigator.pop(context); // Zurück zum Login navigieren
                          } catch (e) {
                            // Fehler anzeigen
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          } finally {
                            setState(() => _isLoading = false); // Ladezustand zurücksetzen
                          }
                        }
                      },
                      child: const Text('Register'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
