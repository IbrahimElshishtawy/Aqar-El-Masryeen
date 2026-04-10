import 'package:aqarelmasryeen/shared/models/partner_models.dart';

String resolveCurrentPartyLabel(
  Partner? currentPartner, {
  String fallback = 'المستخدم',
}) {
  final label = currentPartner == null
      ? ''
      : _resolvePartnerDisplayName(currentPartner);
  return label.isEmpty ? fallback : label;
}

String summarizePartnerNames(
  Iterable<Partner> partners, {
  String fallback = 'الشريك',
  int maxVisibleNames = 2,
}) {
  final names = partners
      .map(_resolvePartnerDisplayName)
      .where((name) => name.isNotEmpty)
      .toList(growable: false);
  if (names.isEmpty) {
    return fallback;
  }
  if (names.length == 1) {
    return names.first;
  }
  if (names.length <= maxVisibleNames) {
    return names.join(' / ');
  }
  final visibleNames = names.take(maxVisibleNames).join(' / ');
  return '$visibleNames +${names.length - maxVisibleNames}';
}

String resolveCounterpartPartyLabel({
  required List<Partner> partners,
  Partner? currentPartner,
  String fallback = 'الشريك',
  int maxVisibleNames = 2,
}) {
  final counterpartPartners = currentPartner == null
      ? partners
      : partners.where((partner) => partner.id != currentPartner.id);
  return summarizePartnerNames(
    counterpartPartners,
    fallback: fallback,
    maxVisibleNames: maxVisibleNames,
  );
}

String _resolvePartnerDisplayName(Partner partner) {
  final name = partner.name.trim();
  if (name.isNotEmpty) {
    return name;
  }

  final linkedEmail = partner.linkedEmail.trim();
  if (linkedEmail.isNotEmpty) {
    return linkedEmail;
  }

  return '';
}
