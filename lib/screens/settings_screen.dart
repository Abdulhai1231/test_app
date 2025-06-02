import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:einkaufsliste/main.dart'; // Importiert navigatorKey und ggf. Routing
import 'package:url_launcher/url_launcher.dart'; // Zum Öffnen externer Apps (z. B. E-Mail)
import '../services/auth_service.dart'; // Authentifizierungsservice
import '../models/user_model.dart'; // Benutzer-Modell
import '../providers/theme_provider.dart'; // Für das Umschalten von Dark/Light Theme

/// Einstellungsbildschirm für den Benutzer
/// Zeigt Benutzerinformationen, Kontaktoptionen, Theme-Umschaltung und Logout
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// Öffnet die E-Mail-App mit einer vorbereiteten Support-Nachricht
  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto', // ACHTUNG: Ursprünglich stand hier fälschlich "Feedback"
      path: 'alboukai.abdulhai@gmail.com',
      queryParameters: {
        'subject': 'App Support Request',
        'body': 'Please describe your issue here...'
      },
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri); // Startet E-Mail-App
    } else {
      // Zeigt eine Fehlermeldung, wenn keine E-Mail-App verfügbar ist
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email app')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Zugriff auf globale Navigator-Kontext, falls nötig
    final rootContext = navigatorKey.currentContext!;
    
    // Zugriff auf den Authentifizierungsservice (für Logout)
    final authService = Provider.of<AuthService>(rootContext, listen: false);
    
    // Holt den aktuell angemeldeten Benutzer
    final user = Provider.of<UserModel?>(context);
    
    // Zugriff auf ThemeProvider, um Dark Mode zu togglen
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [

          // Wenn Benutzer eingeloggt ist, zeige Profilinformationen
          if (user != null) ...[
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: Text(user.displayName.isNotEmpty ? user.displayName : 'No Name'),
              subtitle: Text(user.email),
              onTap: () {
                // Hier könntest du optional zu einem Profilbearbeitungsbildschirm navigieren
              },
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Contact Support'),
              onTap: () => _launchEmail(context), // Öffnet E-Mail zum Support
            ),
          ] else ...[
            // Falls Benutzer nicht eingeloggt ist
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Not signed in'),
              subtitle: const Text('Please sign in to access settings'),
            ),
          ],

          const Divider(),

          // Umschalter für Dark Mode
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: themeProvider.isDarkMode, // aktueller Zustand
            onChanged: (value) {
              themeProvider.toggleTheme(); // wechselt Theme
            },
            secondary: const Icon(Icons.brightness_6),
          ),

          const Divider(),

          // Über die App (Name, Version usw.)
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Einkaufsliste',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2025 HT3A',
              );
            },
          ),

          // Datenschutzrichtlinie anzeigen
          ListTile(
            leading: const Icon(Icons.policy),
            title: const Text('Privacy Policy'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Privacy Policy'),
                  content: const Text(
                    'Your privacy policy details go here.\n\n'
                    'You can link to a website or display full policy text.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),

          const Divider(),

          // Abmelde-Funktion
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            onTap: () async {
              // Bestätigungsdialog vor dem Ausloggen
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false), // Abbrechen
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true), // Bestätigen
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
              
              // Wenn bestätigt, dann ausloggen
              if (confirmed == true) {
                await authService.signOut();
              }
            },
          ),
        ],
      ),
    );
  }
}
