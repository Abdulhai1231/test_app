import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:einkaufsliste/main.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../providers/theme_provider.dart'; // import your ThemeProvider

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'myemail@example.com',
      queryParameters: {
        'subject': 'App Support Request',
        'body': 'Please describe your issue here...'
      },
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email app')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rootContext = navigatorKey.currentContext!;
    final authService = Provider.of<AuthService>(rootContext, listen: false);
    final user = Provider.of<UserModel?>(rootContext);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          if (user != null) ...[
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Contact Support'),
              onTap: () => _launchEmail(context),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: themeProvider.isDarkMode,
              onChanged: (value) {
                themeProvider.toggleTheme();
              },
              secondary: const Icon(Icons.brightness_6),
            ),
            const Divider(),
          ],
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Einkaufsliste',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2025 Your Company',
              );
            },
          ),
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
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            onTap: () => authService.signOut(),
          ),
        ],
      ),
    );
  }
}
