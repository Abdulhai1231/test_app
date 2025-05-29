import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String userId;
  final String email;
  final String displayName;
  final String? familyId;
  final bool emailVerified;

  
  UserModel({
    required this.userId,
    required this.email,
    required this.displayName,
    this.familyId,
    required this.emailVerified,
    
  });
  

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      userId: uid,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      familyId: data['familyId'],
      emailVerified: data['emailVerified'] ?? false,
    );
  }
  factory UserModel.fromDocument(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  return UserModel.fromMap(data, doc.id);
}

  static UserModel fromFirebase(User user) {
    return UserModel(
      userId: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      emailVerified: user.emailVerified,
      familyId: null, // You can load this separately from Firestore if needed
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'familyId': familyId,
      'emailVerified': emailVerified,
    };
  }



  // Optional getter for Firebase user ID
  String get uid => userId;
}
