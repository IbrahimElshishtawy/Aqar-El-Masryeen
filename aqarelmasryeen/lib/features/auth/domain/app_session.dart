import 'package:equatable/equatable.dart';
import 'package:aqarelmasryeen/shared/models/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppSession extends Equatable {
  const AppSession({required this.firebaseUser, required this.profile});

  final User firebaseUser;
  final AppUser? profile;

  bool get isProfileComplete => profile?.isProfileComplete ?? false;

  bool get needsSecuritySetup =>
      isProfileComplete && !(profile?.isSecuritySetupComplete ?? false);

  bool get isActive => profile?.isActive ?? true;

  @override
  List<Object?> get props => [firebaseUser.uid, profile];
}
