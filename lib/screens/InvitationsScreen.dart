import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:einkaufsliste/models/user_model.dart';
import 'package:einkaufsliste/services/family_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InvitationsScreen extends StatelessWidget {
  const InvitationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Aktueller User wird aus Provider geholt
    final currentUser = Provider.of<UserModel?>(context);
    // FamilyService für Einladungen und Gruppenmanagement
    final familyService = Provider.of<FamilyService>(context);

    // Falls kein Nutzer eingeloggt ist, Hinweis anzeigen
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in first.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Family Invitations')),
      body: StreamBuilder<QuerySnapshot>(
        // Stream liefert alle ausstehenden Einladungen für die Email des aktuellen Users
        stream: familyService.getPendingInvitesForUser(currentUser.email),
        builder: (context, snapshot) {
          // Ladeanzeige, solange Daten geladen werden
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Falls keine Einladungen gefunden wurden, entsprechende Meldung
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No invitations found.'));
          }

          // Alle Dokumente (Familiengruppen-Einladungen)
          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final group = docs[index];
              // Die Daten des jeweiligen Einladungs-Dokuments
              final data = group.data() as Map<String, dynamic>;
              final groupName = data['name'] ?? 'Unnamed Group';

              return ListTile(
                title: Text(groupName), // Name der Familiengruppe
                subtitle: const Text('Invited to join this family group.'),
                trailing: ElevatedButton(
                  child: const Text('Join'),
                  onPressed: () async {
                    try {
                      // Einladung annehmen: FamilyService aktualisiert Firestore
                      await familyService.acceptInvitation(
                        group.id,
                        currentUser.uid,
                        currentUser.email,
                      );

                      // Snackbar anzeigen, wenn der Kontext noch "mounted" ist
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Joined family group!')),
                        );
                      }
                    } catch (e) {
                      // Fehlerbehandlung: Fehlermeldung anzeigen
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
