import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum Plan { basic, pro, expert }

extension PlanX on Plan {
  String get value => switch (this) {
        Plan.basic => 'basic',
        Plan.pro => 'pro',
        Plan.expert => 'expert',
      };
  static Plan from(String s) {
    switch (s) {
      case 'pro':
        return Plan.pro;
      case 'expert':
        return Plan.expert;
      default:
        return Plan.basic;
    }
  }
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get onAuthStateChanged => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required Plan plan,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await cred.user?.updateDisplayName(name);
    await _createOrMergeUserDoc(uid: cred.user!.uid, name: name, email: email, plan: plan);
  }

  Future<void> loginWithEmail({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> sendPasswordReset(String email) => _auth.sendPasswordResetEmail(email: email);

  Future<void> loginWithGoogle({Plan? planHint}) async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return; // iptal

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken, idToken: googleAuth.idToken,
    );

    final cred = await _auth.signInWithCredential(credential);

    // İlk girişte kullanıcı dökümanı oluştur/merge et
    final name = cred.user?.displayName ?? '';
    final email = cred.user?.email ?? '';
    await _createOrMergeUserDoc(
      uid: cred.user!.uid,
      name: name,
      email: email,
      plan: planHint ?? Plan.basic,
    );
  }

  Future<void> logout() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  Future<void> _createOrMergeUserDoc({
    required String uid,
    required String name,
    required String email,
    required Plan plan,
  }) async {
    final ref = _db.collection('users').doc(uid);
    await ref.set({
      'uid': uid,
      'name': name,
      'email': email,
      'plan': plan.value,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }


   // ----- Re-auth -----
  Future<void> reauthWithEmailPassword(String email, String password) async {
    final user = _auth.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'no-current-user', message: 'Oturum bulunamadı');
    final cred = EmailAuthProvider.credential(email: email, password: password);
    await user.reauthenticateWithCredential(cred);
  }

  Future<void> reauthWithGoogle() async {
    final user = _auth.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'no-current-user', message: 'Oturum bulunamadı');

    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) throw FirebaseAuthException(code: 'abort-by-user', message: 'İşlem iptal edildi');
    final googleAuth = await googleUser.authentication;

    final cred = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await user.reauthenticateWithCredential(cred);
  }

  // ----- Verileri temizle -----
  Future<void> deleteUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;

    // Firestore users doc
    try { await _db.collection('users').doc(uid).delete(); } catch (_) {}

    // Eğer başka koleksiyonlarda kullanıcı verisi tutuyorsan burada sil
    // ör: await _db.collection('orders').where('uid', isEqualTo: uid)...
  }

  // ----- Firebase kullanıcıyı sil -----
  Future<void> deleteFirebaseUser() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.delete();
  }
}
