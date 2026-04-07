import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/core/widgets/app_form_sheet.dart';
import 'package:aqarelmasryeen/features/auth/data/firebase_auth_repository.dart';
import 'package:aqarelmasryeen/features/auth/domain/app_session.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_validators.dart';
import 'package:aqarelmasryeen/features/notifications/data/notification_repository.dart';
import 'package:aqarelmasryeen/features/partners/data/partner_repository.dart';
import 'package:aqarelmasryeen/features/settings/data/activity_repository.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/app_user.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PartnerFormSheet extends ConsumerStatefulWidget {
  const PartnerFormSheet({super.key, this.partner});

  final Partner? partner;

  @override
  ConsumerState<PartnerFormSheet> createState() => _PartnerFormSheetState();
}

class _PartnerFormSheetState extends ConsumerState<PartnerFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _shareController;
  late final TextEditingController _contributionController;
  late final TextEditingController _emailController;
  bool _linkToCurrentAccount = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.partner?.name ?? '');
    _shareController = TextEditingController(
      text: widget.partner == null
          ? '50'
          : (widget.partner!.shareRatio * 100).toStringAsFixed(0),
    );
    _contributionController = TextEditingController(
      text: widget.partner == null
          ? '0'
          : widget.partner!.contributionTotal.toStringAsFixed(0),
    );
    _emailController = TextEditingController(
      text: widget.partner?.linkedEmail ?? '',
    );
    _linkToCurrentAccount = false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shareController.dispose();
    _contributionController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;

    final currentEmail = _resolveSessionEmail(session);
    final normalizedEmail = _linkToCurrentAccount
        ? currentEmail
        : _emailController.text.trim().toLowerCase();

    setState(() => _saving = true);

    try {
      final existingPartners = await ref
          .read(partnerRepositoryProvider)
          .watchPartners()
          .first;

      AppUser? targetProfile;
      var linkedUserId = '';
      var requestSent = false;

      if (normalizedEmail.isNotEmpty) {
        if (normalizedEmail == currentEmail) {
          linkedUserId = session.userId;
        } else {
          targetProfile = await ref
              .read(userProfileRemoteDataSourceProvider)
              .fetchProfileByEmail(normalizedEmail);
          if (targetProfile == null) {
            _showMessage('لا يوجد حساب مسجل بهذا البريد الإلكتروني.');
            return;
          }
          if (widget.partner?.userId == targetProfile.uid) {
            linkedUserId = targetProfile.uid;
          } else {
            requestSent = true;
          }
        }
      }

      final now = DateTime.now();
      final partner = Partner(
        id: widget.partner?.id ?? '',
        userId: linkedUserId,
        linkedEmail: normalizedEmail,
        name: _nameController.text.trim(),
        shareRatio: (double.tryParse(_shareController.text.trim()) ?? 0) / 100,
        contributionTotal:
            double.tryParse(_contributionController.text.trim()) ?? 0,
        createdAt: widget.partner?.createdAt ?? now,
        updatedAt: now,
      );

      final partnerId = await ref.read(partnerRepositoryProvider).upsert(partner);

      if (linkedUserId == session.userId) {
        await _unlinkOtherPartners(
          partners: existingPartners,
          linkedUserId: session.userId,
          keepPartnerId: partnerId,
        );
      }

      if (requestSent && targetProfile != null) {
        await ref
            .read(notificationRepositoryProvider)
            .create(
              userId: targetProfile.uid,
              title: 'طلب شراكة جديد',
              body:
                  '${session.profile?.name ?? 'شريك'} أرسل طلب ربط للشريك ${partner.name}.',
              type: NotificationType.partnerLinkRequest,
              route: AppRoutes.partners,
              referenceKey:
                  'partner-link-request-$partnerId-${targetProfile.uid}',
              metadata: {
                'partnerId': partnerId,
                'partnerName': partner.name,
                'requesterUserId': session.userId,
                'requesterName': session.profile?.name ?? 'شريك',
                'requesterEmail': currentEmail,
              },
            );
      }

      await ref
          .read(activityRepositoryProvider)
          .log(
            actorId: session.userId,
            actorName: session.profile?.name ?? 'Ø´Ø±ÙŠÙƒ',
            action: widget.partner == null ? 'partner_created' : 'partner_updated',
            entityType: 'partner',
            entityId: partnerId,
            metadata: {
              'shareRatio': partner.shareRatio,
              'contributionTotal': partner.contributionTotal,
              'linkedEmail': partner.linkedEmail,
              'linkedToCurrentUser': linkedUserId == session.userId,
              'requestSent': requestSent,
            },
          );

      if (!mounted) return;
      _showMessage(
        requestSent
            ? 'تم حفظ الشريك وإرسال طلب الربط على البريد.'
            : linkedUserId == session.userId
            ? 'تم حفظ الشريك وربطه بالحساب الحالي.'
            : 'تم حفظ بيانات الشريك.',
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _unlinkOtherPartners({
    required List<Partner> partners,
    required String linkedUserId,
    required String keepPartnerId,
  }) async {
    for (final partner in partners) {
      if (partner.userId != linkedUserId || partner.id == keepPartnerId) {
        continue;
      }
      await ref.read(partnerRepositoryProvider).upsert(
            partner.copyWith(
              userId: '',
              linkedEmail: '',
              updatedAt: DateTime.now(),
            ),
          );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppFormSheet(
      title: widget.partner == null ? 'إضافة شريك' : 'تعديل الشريك',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'اسم الشريك'),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'أدخل اسم الشريك.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _shareController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'نسبة الشراكة %'),
              validator: (value) {
                final share = double.tryParse((value ?? '').trim()) ?? -1;
                if (share <= 0 || share > 100) {
                  return 'أدخل قيمة بين 0 و100.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contributionController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'المساهمات الرأسمالية',
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _linkToCurrentAccount,
              onChanged: (value) => setState(() {
                _linkToCurrentAccount = value;
                if (value) {
                  final session = ref.read(authSessionProvider).valueOrNull;
                  _emailController.text = _resolveSessionEmail(session);
                }
              }),
              title: const Text('ربط بالحساب الحالي مباشرة'),
              subtitle: const Text(
                'فعّل هذا الخيار لو الشريك هو نفس الحساب المفتوح الآن.',
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              enabled: !_linkToCurrentAccount,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'بريد حساب الشريك',
                helperText:
                    'اكتب بريد الشريك لإرسال طلب ربط، وبعد الموافقة يظهر الربط تلقائيًا.',
                helperStyle: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
              validator: (value) {
                final text = (value ?? '').trim();
                if (text.isEmpty) {
                  return null;
                }
                return AuthValidators.email(text);
              },
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: Text(
                  _saving
                      ? 'جار الحفظ...'
                      : _linkToCurrentAccount
                      ? 'حفظ وربط'
                      : 'حفظ / إرسال طلب',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _resolveSessionEmail(AppSession? session) {
  final profileEmail = session?.profile?.email.trim().toLowerCase() ?? '';
  if (profileEmail.isNotEmpty) {
    return profileEmail;
  }
  return session?.email?.trim().toLowerCase() ?? '';
}
