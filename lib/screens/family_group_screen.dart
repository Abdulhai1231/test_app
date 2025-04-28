import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/family_service.dart';
import '../../models/user_model.dart'; // Changed from User to UserModel
import 'invite_member_screen.dart';

class FamilyGroupScreen extends StatelessWidget {
  const FamilyGroupScreen({super.key}); // Added key parameter

  @override
  Widget build(BuildContext context) {
    final familyService = Provider.of<FamilyService>(context);
    final currentUser = Provider.of<UserModel?>(context); // Changed from User to UserModel

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('User not authenticated')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Family Group')),
      body: StreamBuilder<QuerySnapshot>(
        stream: familyService.getUserFamilyGroups(currentUser.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('You are not in any family group yet'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    child: const Text('Create Family Group'),
                    onPressed: () => _showCreateGroupDialog(context, familyService, currentUser),
                  ),
                ],
              ),
            );
          }
          
          var group = snapshot.data!.docs.first;
          List members = group['members'];
          List pendingInvites = group['pendingInvitations'] ?? [];
          
          return Column(
            children: [
              ListTile(
                title: Text(group['name'], style: const TextStyle(fontSize: 20)),
                subtitle: const Text('Family Group'),
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Members', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(members[index]).get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) return const ListTile(title: Text('Loading...'));
                        
                        return ListTile(
                          title: Text(userSnapshot.data!['email']),
                          trailing: group['admin'] == currentUser.uid && 
                                   members[index] != currentUser.uid
                              ? IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () => familyService.removeMember(group.id, members[index]),
                                )
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
              if (pendingInvites.isNotEmpty) ...[
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Pending Invitations', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ...pendingInvites.map((email) => ListTile(
                  title: Text(email),
                  trailing: group['admin'] == currentUser.uid
                      ? IconButton(
                          icon: const Icon(Icons.cancel),
                          onPressed: () => familyService.cancelInvitation(group.id, email),
                        )
                      : null,
                )),
              ],
            ],
          );
        },
      ),
      floatingActionButton: Consumer<FamilyService>(
        builder: (context, familyService, _) {
          return StreamBuilder<QuerySnapshot>(
            stream: familyService.getUserFamilyGroups(currentUser.uid), // Added user ID parameter
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox();
              
              var group = snapshot.data!.docs.first;
              if (group['admin'] != currentUser.uid) return const SizedBox();
              
              return FloatingActionButton(
                child: const Icon(Icons.person_add),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => InviteMemberScreen(groupId: group.id)),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context, FamilyService familyService, UserModel currentUser) {
    final TextEditingController nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Family Group'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Group Name'),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Create'),
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await familyService.createFamilyGroup(
                  nameController.text, 
                  currentUser.uid
                );
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
}