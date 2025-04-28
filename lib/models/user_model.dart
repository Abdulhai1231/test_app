import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String uid;
  final String? email;
  final String? displayName;

  UserModel(this.uid, {this.email, this.displayName, required String userId});

  factory UserModel.fromFirebase(User user) {
    return UserModel(
      user.uid,
      email: user.email,
      displayName: user.displayName, userId: '',
    );
  }

  static fromFirebaseUser(User user) {}
}