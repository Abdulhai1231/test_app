import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/family_service.dart';

class InviteMemberScreen extends StatefulWidget {
  final String groupId;

  const InviteMemberScreen({
    super.key, 
    required this.groupId,
  });

  @override
  State<InviteMemberScreen> createState() => _InviteMemberScreenState();
}

class _InviteMemberScreenState extends State<InviteMemberScreen> {
  final TextEditingController emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final familyService = Provider.of<FamilyService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Invite Member')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Enter family member email',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Send Invitation'),
              onPressed: () {
                if (emailController.text.isNotEmpty) {
                  familyService.inviteMember(
                    widget.groupId, 
                    emailController.text,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Invitation sent to ${emailController.text}'),
                    ),
                  );
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}