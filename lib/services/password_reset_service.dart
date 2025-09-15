// lib/services/password_reset_service.dart
import 'package:firebase_auth/firebase_auth.dart';

class PasswordResetService {
  final _auth = FirebaseAuth.instance;

  Future<void> sendResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}
