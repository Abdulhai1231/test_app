import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:einkaufsliste/main.dart';
import '../services/auth_service.dart' as auth_service;
import '../models/user_model.dart';
import 'package:einkaufsliste/services/auth_service.dart';


class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Access providers using the root context
    final rootContext = navigatorKey.currentContext!;
    final authService = Provider.of<AuthService>(navigatorKey.currentContext!, listen: false);
    final user = Provider.of<UserModel?>(rootContext);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          if (user != null) ...[
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(user.email),
            ),
            const Divider(),
          ],
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