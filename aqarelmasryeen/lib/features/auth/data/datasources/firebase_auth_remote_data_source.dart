import 'package:aqarelmasryeen/core/errors/app_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthRemoteDataSource {
  FirebaseAuthRemoteDataSource(this._auth);

  final FirebaseAuth _auth;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> createUserWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> linkEmailCredential({
    required User user,
    required String email,
    required String password,
  }) async {
    final providers = user.providerData.map((provider) => provider.providerId);
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    if (!providers.contains(EmailAuthProvider.PROVIDER_ID)) {
      await user.linkWithCredential(credential);
      return;
    }

    if (user.email != email) {
      await user.verifyBeforeUpdateEmail(email);
    }
  }

  Future<void> updateEmail(User user, String email) async {
    final existingEmail = user.email?.trim().toLowerCase();
    if (existingEmail == email) {
      return;
    }
    try {
      await user.verifyBeforeUpdateEmail(email);
    } on FirebaseAuthException catch (error) {
      if (error.code == 'requires-recent-login') {
        throw const AppException(
          'أعد إدخال بيانات الدخول قبل تغيير بريد تسجيل الدخول.',
          code: 'requires_recent_login',
        );
      }
      rethrow;
    }
  }

  Future<void> updateDisplayName(User user, String fullName) {
    return user.updateDisplayName(fullName);
  }

  Future<void> reloadUser(User user) => user.reload();

  Future<void> signOut() => _auth.signOut();
}
