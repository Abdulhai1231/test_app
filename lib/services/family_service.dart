import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Zentrale Klasse für Familien-Gruppen-Funktionalitäten
/// 
/// Verantwortlich für:
/// - Erstellung und Verwaltung von Familien-Gruppen
/// - Einladungsmanagement (Versand/Akzeptieren)
/// - Mitgliederverwaltung (Hinzufügen/Entfernen)
/// - Synchronisation mit Firebase Firestore
class FamilyService {
  // Firebase Instanzen für Firestore und Authentifizierung
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /* ==================== GRUNDLEGENDE METHODEN ==================== */

  /// Gibt den aktuellen Authentifizierungszustand als Stream zurück
  Stream<User?> userStream() {
    return _auth.authStateChanges();
  }

  /* ==================== GRUPPENVERWALTUNG ==================== */

  /// Erstellt eine neue Familien-Gruppe
  Future<String> createFamilyGroup(String name) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // 1. Benutzerdokument erstellen/aktualisieren
    await _db.collection('users').doc(user.uid).set({
      'email': user.email,
      'displayName': user.displayName ?? 'User',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 2. Neue Gruppe erstellen
    final groupRef = _db.collection('familyGroups').doc();
    await groupRef.set({
      'name': name,
      'admin': user.uid,
      'members': [user.uid],
      'pendingInvites': [],
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 3. Familien-ID im Benutzerprofil speichern
    await updateUserFamilyId(user.uid, groupRef.id);

    return groupRef.id;
  }

  /// Holt alle Familien-Gruppen eines Benutzers als Stream
  Stream<QuerySnapshot> getUserFamilyGroups(String userId) {
    return _db.collection('familyGroups')
        .where('members', arrayContains: userId)
        .snapshots();
  }

  /// Holt die aktuelle Familien-ID des Benutzers
  Future<String?> _getCurrentFamilyId() async {
    final snapshot = await _db.collection('familyGroups')
        .where('members', arrayContains: _auth.currentUser!.uid)
        .limit(1)
        .get();
    return snapshot.docs.isEmpty ? null : snapshot.docs.first.id;
  }

  /* ==================== MITGLIEDERVERWALTUNG ==================== */

  /// Fügt ein Mitglied zur Gruppe hinzu (für Einladungsflow)
  Future<void> acceptFamilyInvite(String userId, String userEmail, String groupId) async {
    await _db.collection('familyGroups').doc(groupId).update({
      'members': FieldValue.arrayUnion([userId]),
      'pendingInvites': FieldValue.arrayRemove([userEmail.toLowerCase()]),
    });
    await updateUserFamilyId(userId, groupId);
  }

  /// Entfernt ein Mitglied aus der Gruppe
  Future<void> removeMember(String groupId, String memberId) async {
    await _db.collection('familyGroups').doc(groupId).update({
      'members': FieldValue.arrayRemove([memberId])
    });
  }

  /// Spezielle Methode zum Entfernen von Mitgliedern
  Future<void> removeMemberFromFamily(String groupId, String memberId) async {
    await _db.collection('familyGroups').doc(groupId).update({
      'members': FieldValue.arrayRemove([memberId])
    });
  }

  /* ==================== EINLADUNGSMANAGEMENT ==================== */

  /// Sendet eine Einladung an eine E-Mail-Adresse
  Future<void> inviteMember(String groupId, String email) async {
    final emailLower = email.trim().toLowerCase();
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

    if (members.contains(userId)) throw Exception('User already a member');
    if (pendingInvites.contains(emailLower)) throw Exception('User already invited');

    await _db.collection('familyGroups').doc(groupId).update({
      'pendingInvites': FieldValue.arrayUnion([emailLower])
    });
  }

  /// Alternative Einladungsmethode
  Future<void> sendInvitation(String groupId, String email) async {
    final groupRef = _db.collection('familyGroups').doc(groupId);
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

  /// Holt ausstehende Einladungen für einen Benutzer
  Stream<QuerySnapshot> getPendingInvitesForUser(String email) {
    return _db.collection('familyGroups')
        .where('pendingInvites', arrayContains: email)
        .snapshots();
  }

  /// Akzeptiert eine Einladung
  Future<void> acceptInvitation(String groupId, String userId, String email) async {
    await _db.collection('familyGroups').doc(groupId).update({
      'members': FieldValue.arrayUnion([userId]),
      'pendingInvites': FieldValue.arrayRemove([email]),
    });
    await updateUserFamilyId(userId, groupId);
  }

  /// Bricht eine Einladung ab
  Future<void> cancelInvitation(String groupId, String email) async {
    await _db.collection('familyGroups').doc(groupId).update({
      'pendingInvites': FieldValue.arrayRemove([email.toLowerCase()])
    });
  }

  /* ==================== GRUPPENBEITRITT/-VERLASSEN ==================== */

  /// Tritt einer Gruppe bei
  Future<void> joinFamilyGroup(String groupId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _db.collection('familyGroups').doc(groupId).update({
      'members': FieldValue.arrayUnion([user.uid]),
      'pendingInvites': FieldValue.arrayRemove([user.email?.toLowerCase()]),
    });
  }

  /// Verlässt eine Gruppe
  Future<void> leaveFamilyGroup(String groupId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final groupRef = _db.collection('familyGroups').doc(groupId);
    final groupSnap = await groupRef.get();

    if (!groupSnap.exists) throw Exception('Family group not found');

    final data = groupSnap.data()!;
    final admin = data['admin'];

    if (admin == user.uid) {
      await groupRef.delete();
    } else {
      await _db.collection('users').doc(user.uid).update({
        'familyId': FieldValue.delete()
      });
    }

    await _db.collection('users').doc(user.uid).update({
      'familyId': FieldValue.delete()
    });
  }

  /// Überträgt Admin-Rechte und verlässt die Gruppe
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

  /* ==================== HILFSMETHODEN ==================== */

  /// Aktualisiert die Familien-ID eines Benutzers
  Future<void> updateUserFamilyId(String userId, String familyId) async {
    await _db.collection('users').doc(userId).update({'familyId': familyId});
  }

  /// Löscht die Familien-ID eines Benutzers
  Future<void> clearUserFamilyId(String userId) async {
    await _db.collection('users').doc(userId).update({'familyId': FieldValue.delete()});
  }
}