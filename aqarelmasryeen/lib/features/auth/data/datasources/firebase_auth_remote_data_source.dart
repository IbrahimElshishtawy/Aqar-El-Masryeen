import 'package:aqarelmasryeen/core/errors/app_exception.dart';
import 'package:aqarelmasryeen/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

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

  Future<String> createUserWithEmailOnIsolatedApp({
    required String email,
    required String password,
    required String fullName,
    required String appName,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      secondaryApp = Firebase.apps.cast<FirebaseApp?>().firstWhere(
        (app) => app?.name == appName,
        orElse: () => null,
      );
      secondaryApp ??= await Firebase.initializeApp(
        name: appName,
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AppException('Authentication did not return a user.');
      }
      await user.updateDisplayName(fullName);
      await user.reload();
      await secondaryAuth.signOut();
      return user.uid;
    } finally {
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }
    }
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
