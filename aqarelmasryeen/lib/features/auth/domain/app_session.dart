import 'package:aqarelmasryeen/shared/models/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppSession {
  const AppSession({
    required this.firebaseUser,
    required this.profile,
  });

  final User firebaseUser;
  final AppUser? profile;

  bool get isProfileComplete => profile?.isProfileComplete ?? false;
}
