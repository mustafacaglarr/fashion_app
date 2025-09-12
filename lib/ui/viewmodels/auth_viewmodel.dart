import 'package:flutter/foundation.dart';
import '../../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService auth;
  bool isBusy = false;
  String? error;

  AuthViewModel(this.auth);

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required Plan plan,
  }) async {
    try {
      isBusy = true; error = null; notifyListeners();
      await auth.registerWithEmail(name: name, email: email, password: password, plan: plan);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isBusy = false; notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    try {
      isBusy = true; error = null; notifyListeners();
      await auth.loginWithEmail(email: email, password: password);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isBusy = false; notifyListeners();
    }
  }

  Future<void> loginWithGoogle({Plan? planHint}) async {
    try {
      isBusy = true; error = null; notifyListeners();
      await auth.loginWithGoogle(planHint: planHint);
    } catch (e) {
      error = e.toString();
    } finally {
      isBusy = false; notifyListeners();
    }
  }

  Future<void> resetPassword(String email) => auth.sendPasswordReset(email);

  Future<void> logout() => auth.logout();
}
