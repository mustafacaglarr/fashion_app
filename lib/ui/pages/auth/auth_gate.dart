import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../landing_view.dart';
import 'login_view.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _auth = FirebaseAuth.instance;

  Future<bool> _validateSession() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Token’ı zorla yenile + sunucuyla senkronize et
      await user.reload();
      await user.getIdToken(true);

      // Firestore’da kullanıcı dokümanı var mı?
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (snap.exists) return true;

      // Doküman yoksa, hesabı console’dan silmiş olabilirsin → çıkış
      await _auth.signOut();
      return false;
    } catch (_) {
      // Hata varsa güvenli taraf: çıkış
      await _auth.signOut();
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (_, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Giriş yok → Login
        if (authSnap.data == null) return const LoginView();

        // Giriş var görünüyor → doğrula (token refresh + Firestore doc)
        return FutureBuilder<bool>(
          future: _validateSession(),
          builder: (_, validSnap) {
            if (validSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            final ok = validSnap.data == true;
            return ok ? const LandingView() : const LoginView();
          },
        );
      },
    );
  }
}
