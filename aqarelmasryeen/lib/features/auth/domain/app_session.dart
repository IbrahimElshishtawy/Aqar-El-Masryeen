import 'package:equatable/equatable.dart';
import 'package:aqarelmasryeen/shared/models/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppSession extends Equatable {
  const AppSession({
    required this.userId,
    required this.profile,
    this.email,
    this.displayName,
    this.phoneNumber,
    this.providerIds = const [],
  });

  factory AppSession.fromFirebaseUser({
    required User firebaseUser,
    required AppUser? profile,
  }) {
    return AppSession(
      userId: firebaseUser.uid,
      profile: profile,
      email: firebaseUser.email,
      displayName: firebaseUser.displayName,
      phoneNumber: firebaseUser.phoneNumber,
      providerIds: firebaseUser.providerData
          .map((provider) => provider.providerId)
          .toList(growable: false),
    );
  }

  final String userId;
  final AppUser? profile;
  final String? email;
  final String? displayName;
  final String? phoneNumber;
  final List<String> providerIds;

  bool get hasProfile => profile != null;

  bool get isProfileComplete => profile?.isProfileComplete ?? false;

  bool get needsProfileCompletion => !hasProfile || !isProfileComplete;

  bool get needsSecuritySetup =>
      !needsProfileCompletion && !(profile?.isSecuritySetupComplete ?? false);

  bool get isActive => profile?.isActive ?? true;

  @override
  List<Object?> get props => [
    userId,
    email,
    displayName,
    phoneNumber,
    providerIds,
    profile,
  ];
}
