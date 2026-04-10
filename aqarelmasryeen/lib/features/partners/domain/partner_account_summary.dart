import 'package:aqarelmasryeen/shared/models/app_user.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';

class PartnerAccountSummary {
  const PartnerAccountSummary({
    required this.user,
    required this.linkedPartner,
    required this.createdByName,
    required this.createdByCurrentUser,
  });

  final AppUser user;
  final Partner? linkedPartner;
  final String createdByName;
  final bool createdByCurrentUser;

  bool get isLinked => linkedPartner != null || user.isLinkedToPartner;
}
