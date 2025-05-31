import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FamilyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> createFamilyGroup(String name) async {
  final user = _auth.currentUser;
  if (user == null) throw Exception('User not authenticated');

  // Create user doc if needed
  await _db.collection('users').doc(user.uid).set({
    'email': user.email,
    'displayName': user.displayName ?? 'User',
    'createdAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  // Create family group
  final groupRef = _db.collection('familyGroups').doc();
  await groupRef.set({
    'name': name,
    'admin': user.uid,
    'members': [user.uid],
    'pendingInvites': [],
    'createdAt': FieldValue.serverTimestamp(),
  });

  // **Important:** update user's familyId
  await updateUserFamilyId(user.uid, groupRef.id);

  return groupRef.id;
}

  Stream<User?> userStream() {
  return FirebaseAuth.instance.authStateChanges();
}

  Future<void> inviteMember(String groupId, String email) async {
    final emailLower = email.trim().toLowerCase();

    // Consider replacing print with debugPrint or logging framework
    debugPrint('Looking for user with email: $emailLower');

    final userQuery = await _db.collection('users')
        .where('email', isEqualTo: emailLower)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) {
      debugPrint('No user found with this email');
      throw Exception('No user found with this email');
    }

    final userId = userQuery.docs.first.id;

    final groupSnap = await _db.collection('familyGroups').doc(groupId).get();
    final members = List<String>.from(groupSnap['members'] ?? []);
    final pendingInvites = List<String>.from(groupSnap['pendingInvites'] ?? []);

    if (members.contains(userId)) {
      debugPrint('User already a member');
      throw Exception('User is already a member');
    }

    if (pendingInvites.contains(emailLower)) {
      debugPrint('User already invited');
      throw Exception('User already invited');
    }

    debugPrint('Adding $emailLower to pendingInvites...');
    await _db.collection('familyGroups').doc(groupId).update({
      'pendingInvites': FieldValue.arrayUnion([emailLower])
    });
  }

  Future<void> joinFamilyGroup(String groupId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _db.collection('familyGroups').doc(groupId).update({
      'members': FieldValue.arrayUnion([user.uid]),
      'pendingInvites': FieldValue.arrayRemove([user.email?.toLowerCase()]),
    });
  }

  Stream<QuerySnapshot> getUserFamilyGroups(String userId) {
    return _db.collection('familyGroups')
        .where('members', arrayContains: userId)
        .snapshots();
  }

  Future<void> leaveFamilyGroup(String groupId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final groupRef = _db.collection('familyGroups').doc(groupId);
    final groupSnap = await groupRef.get();

    if (!groupSnap.exists) throw Exception('Family group not found');

    final data = groupSnap.data()!;
    final admin = data['admin'];

    if (admin == user.uid) {
      // Admin leaving -> delete the whole group
      await groupRef.delete();
    } else {
      // Regular member leaving
     await _db.collection('users').doc(user.uid).update({
  'familyId': FieldValue.delete()
});

    }

    // Clean up user document
    await _db.collection('users').doc(user.uid).update({
      'familyId': FieldValue.delete()
    });
  }

  Future<void> transferAdminAndLeave(String groupId, String newAdminId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final batch = _db.batch();
    final groupRef = _db.collection('familyGroups').doc(groupId);

    batch.update(groupRef, {
      'admin': newAdminId,
      'members': FieldValue.arrayRemove([user.uid]),
    });

    batch.update(_db.collection('users').doc(user.uid), {
      'familyId': FieldValue.delete()
    });

    await batch.commit();
  }

  Future<void> acceptFamilyInvite(String userId, String userEmail, String groupId) async {
    final groupRef = _db.collection('familyGroups').doc(groupId);

    // Add user to members
    await groupRef.update({
  'members': FieldValue.arrayUnion([userId]),
  'pendingInvites': FieldValue.arrayRemove([userEmail.toLowerCase()]),
});

    // Update user's familyId field
    final userDoc = _db.collection('users').doc(userId);
    await userDoc.update({'familyId': groupId});
  }

  Future<void> removeMember(String groupId, String memberId) async {
    await _db.collection('familyGroups').doc(groupId).update({
      'members': FieldValue.arrayRemove([memberId])
    });
  }

  Future<void> cancelInvitation(String groupId, String email) async {
    await _db.collection('familyGroups').doc(groupId).update({
      'pendingInvites': FieldValue.arrayRemove([email.toLowerCase()])
    });
  }
  // In FamilyService class
Future<void> updateUserFamilyId(String userId, String familyId) async {
  await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .update({'familyId': familyId});
}

Future<void> clearUserFamilyId(String userId) async {
  await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .update({'familyId': FieldValue.delete()});
}
Future<String?> _getCurrentFamilyId() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('familyGroups')
      .where('members', arrayContains: FirebaseAuth.instance.currentUser!.uid)
      .limit(1)
      .get();
  return snapshot.docs.isEmpty ? null : snapshot.docs.first.id;
}
Future<void> sendInvitation(String groupId, String email) async {
  final groupRef = FirebaseFirestore.instance.collection('familyGroups').doc(groupId);

  // Optional: Prevent duplicates
  final doc = await groupRef.get();
  final data = doc.data()!;
  final currentInvites = List<String>.from(data['pendingInvites'] ?? []);
  final members = List<String>.from(data['members'] ?? []);

  if (members.contains(email) || currentInvites.contains(email)) {
    throw Exception('User already a member or already invited');
  }

  await groupRef.update({
    'pendingInvites': FieldValue.arrayUnion([email]),
  });
}
  Stream<QuerySnapshot> getPendingInvitesForUser(String email) {
  return FirebaseFirestore.instance
      .collection('familyGroups')
      .where('pendingInvites', arrayContains: email)
      .snapshots();
}
  Future<void> acceptInvitation(String groupId, String userId, String email) async {
  final groupRef = FirebaseFirestore.instance.collection('familyGroups').doc(groupId);

  await groupRef.update({
    'members': FieldValue.arrayUnion([userId]),
    'pendingInvites': FieldValue.arrayRemove([email]),
  });

  // Optional: Update user's document with familyId
  await FirebaseFirestore.instance.collection('users').doc(userId).update({
    'familyId': groupId,
  });
}
  Future<void> removeMemberFromFamily(String groupId, String memberId) async {
    await _db.collection('familyGroups').doc(groupId).update({
      'members': FieldValue.arrayRemove([memberId])
    });
  }

  
}
