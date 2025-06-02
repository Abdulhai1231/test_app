import 'package:einkaufsliste/screens/InvitationsScreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:einkaufsliste/services/family_service.dart';
import 'package:einkaufsliste/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FamilyGroupScreen extends StatelessWidget {
  const FamilyGroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // FamilyService und aktueller User aus Provider holen
    final familyService = Provider.of<FamilyService>(context);
    final currentUser = Provider.of<UserModel?>(context);

    // Wenn kein User eingeloggt, Hinweis anzeigen
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in first')),
      );
    }

    // Scaffold mit AppBar und Hauptinhalt
    return Scaffold(
      appBar: AppBar(title: const Text('Family Group')),
      body: StreamBuilder<QuerySnapshot>(
        // Stream aus FamilyService, der Family Groups des Users liefert
        stream: familyService.getUserFamilyGroups(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Ladeindikator anzeigen während Daten geladen werden
            return const Center(child: CircularProgressIndicator());
          }

          // Wenn keine Gruppen gefunden wurden
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No family group found'),
                  const SizedBox(height: 20),
                  // Button zum Erstellen einer neuen Familie
                  ElevatedButton(
                    onPressed: () => _showCreateDialog(context, familyService, currentUser),
                    child: const Text('Create Family Group'),
                  ),
                  const SizedBox(height: 12),
                  // Button um zu den Einladungen zu navigieren
                  ElevatedButton.icon(
                    icon: const Icon(Icons.mail_outline),
                    label: const Text('Check Invitations'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const InvitationsScreen()),
                      );
                    },
                  ),
                ],
              ),
            );
          }

          // Falls eine Gruppe existiert, nur die erste verwenden (eine User kann nur eine Family Group haben)
          final group = snapshot.data!.docs.first;
          final data = group.data() as Map<String, dynamic>;

          // Baue die UI der Family Group mit Daten und Service
          return _buildGroupUI(context, group.id, data, familyService, currentUser);
        },
      ),
    );
  }

  // Baut die Oberfläche für eine Family Group mit Mitgliedern, Einladungen und Aktionen
  Widget _buildGroupUI(
    BuildContext context,
    String groupId,
    Map<String, dynamic> groupData,
    FamilyService service,
    UserModel currentUser,
  ) {
    final members = List<String>.from(groupData['members'] ?? []);
    final pendingInvites = List<String>.from(groupData['pendingInvites'] ?? []);
    final isAdmin = groupData['admin'] == currentUser.uid;

    return Column(
      children: [
        ListTile(
          title: Text(
            groupData['name'] ?? 'Family Group',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          subtitle: Text('Admin: ${isAdmin ? 'You' : 'Family Admin'}'),
        ),
        const Divider(),
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('MEMBERS', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              // Für jedes Mitglied laden wir die User-Daten aus Firestore
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(members[index]).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(title: Text('Loading...'));
                  }

                  final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                  final email = userData?['email'] ?? 'Unknown member';

                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(email),
                    // Admin kann andere Mitglieder entfernen
                    trailing: isAdmin && members[index] != currentUser.uid
                        ? IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: () => service.removeMember(groupId, members[index]),
                          )
                        : null,
                  );
                },
              );
            },
          ),
        ),
        // Anzeige der ausstehenden Einladungen
        if (pendingInvites.isNotEmpty) ...[
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('PENDING INVITES', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...pendingInvites.map((email) => ListTile(
                leading: const CircleAvatar(child: Icon(Icons.mail_outline)),
                title: Text(email),
                trailing: isAdmin
                    ? IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.orange),
                        onPressed: () => service.cancelInvitation(groupId, email),
                      )
                    : null,
              )),
        ],
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Button zum Verlassen der Gruppe
              ElevatedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('Leave Family Group'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => _showLeaveFamilyDialog(context, service, groupId),
              ),
              // Button zum Einladen von Mitgliedern, nur für Admin sichtbar
              if (isAdmin)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.person_add),
                    label: const Text('Invite Member'),
                    onPressed: () => _showInviteDialog(context, service, groupId),
                  ),
                ),

              // Warnung wenn Admin die Gruppe verlässt (Gruppe wird gelöscht)
              if (isAdmin) ...[
                const SizedBox(height: 8),
                const Text(
                  'As the admin, leaving will delete the group for everyone.',
                  style: TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Dialog zum Bestätigen des Verlassens oder Löschens der Gruppe
  void _showLeaveFamilyDialog(BuildContext context, FamilyService service, String groupId) async {
    final user = FirebaseAuth.instance.currentUser;
    final groupSnap = await FirebaseFirestore.instance.collection('familyGroups').doc(groupId).get();
    final isAdmin = groupSnap['admin'] == user?.uid;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAdmin ? 'Delete Family Group' : 'Leave Family Group'),
        content: Text(isAdmin
            ? 'As the admin, leaving will delete the family group for everyone. Are you sure?'
            : 'Are you sure you want to leave this family group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await service.leaveFamilyGroup(groupId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isAdmin
                          ? 'Family group deleted.'
                          : 'You have left the family group.'),
                    ),
                  );
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const FamilyGroupScreen()),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            child: Text(isAdmin ? 'Delete' : 'Leave', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Dialog zum Erstellen einer neuen Familie
  void _showCreateDialog(BuildContext context, FamilyService service, UserModel user) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Family Group'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Family Name', hintText: 'e.g. Smith Family'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                try {
                  await service.createFamilyGroup(controller.text);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Family group created!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  // Dialog zum Einladen neuer Mitglieder per E-Mail
  void _showInviteDialog(BuildContext context, FamilyService service, String groupId) {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Member'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'Enter the user\'s email',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isNotEmpty) {
                Navigator.pop(context);
                try {
                  await service.sendInvitation(groupId, email);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Invitation sent to $email')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
