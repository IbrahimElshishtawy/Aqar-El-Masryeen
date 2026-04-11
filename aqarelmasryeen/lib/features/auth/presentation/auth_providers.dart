import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/features/auth/data/firebase_auth_repository.dart';
import 'package:aqarelmasryeen/features/auth/domain/app_session.dart';
import 'package:aqarelmasryeen/features/partners/data/partner_repository.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'controllers/credential_login_controller.dart';
export 'controllers/profile_setup_controller.dart';
export 'controllers/register_controller.dart';
export 'controllers/security_setup_controller.dart';

final authSessionProvider = StreamProvider<AppSession?>((ref) {
  return ref.watch(authRepositoryProvider).watchSession();
});

final linkedSessionPartnerProvider = StreamProvider.autoDispose<Partner?>((
  ref,
) {
  final session = ref.watch(authSessionProvider).valueOrNull;
  final linkedPartnerId = session?.profile?.linkedPartnerId.trim() ?? '';
  if (linkedPartnerId.isEmpty) {
    return Stream.value(null);
  }

  return ref.watch(partnerRepositoryProvider).watchPartner(linkedPartnerId);
});

final currentWorkspaceIdProvider = Provider.autoDispose<String>((ref) {
  final session = ref.watch(authSessionProvider).valueOrNull;
  final profile = session?.profile;
  final profileWorkspaceId = profile?.workspaceId.trim() ?? '';
  final linkedPartnerWorkspaceId =
      ref.watch(linkedSessionPartnerProvider).valueOrNull?.workspaceId.trim() ??
      '';

  if (linkedPartnerWorkspaceId.isNotEmpty &&
      (profileWorkspaceId.isEmpty ||
          profileWorkspaceId.startsWith('workspace_') ||
          profileWorkspaceId != linkedPartnerWorkspaceId)) {
    return linkedPartnerWorkspaceId;
  }

  return profileWorkspaceId;
});

final biometricAvailabilityProvider = FutureProvider((ref) async {
  return ref.read(biometricServiceProvider).getAvailability();
});
