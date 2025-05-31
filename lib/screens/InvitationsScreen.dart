import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:einkaufsliste/models/user_model.dart';
import 'package:einkaufsliste/services/family_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InvitationsScreen extends StatelessWidget {
  const InvitationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserModel?>(context);
    final familyService = Provider.of<FamilyService>(context);

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in first.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Family Invitations')),
      body: StreamBuilder<QuerySnapshot>(
        stream: familyService.getPendingInvitesForUser(currentUser.email),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No invitations found.'));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final group = docs[index];
              final data = group.data() as Map<String, dynamic>;
              final groupName = data['name'] ?? 'Unnamed Group';

              return ListTile(
                title: Text(groupName),
                subtitle: Text('Invited to join this family group.'),
                trailing: ElevatedButton(
                  child: const Text('Join'),
                  onPressed: () async {
                    try {
                      await familyService.acceptInvitation(
                        group.id,
                        currentUser.uid,
                        currentUser.email,
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Joined family group!')),
                        );
                      }
                    } catch (e) {
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
