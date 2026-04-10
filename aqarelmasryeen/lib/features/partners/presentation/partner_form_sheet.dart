import 'package:aqarelmasryeen/core/errors/failure_mapper.dart';
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
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  bool _linkToCurrentAccount = false;
  bool _createPartnerAccount = false;
  bool _saving = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool get _canCreateLinkedAccount =>
      widget.partner == null || widget.partner!.userId.isEmpty;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.partner?.name ?? '');
    _emailController = TextEditingController(
      text: widget.partner?.linkedEmail ?? '',
    );
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _createPartnerAccount = widget.partner == null && _canCreateLinkedAccount;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;

    final currentEmail = _resolveSessionEmail(session);
    final workspaceId = _resolveWorkspaceId(session);
    final normalizedEmail = _linkToCurrentAccount
        ? currentEmail
        : _emailController.text.trim().toLowerCase();

    setState(() => _saving = true);

    try {
      final existingPartners = await ref
          .read(partnerRepositoryProvider)
          .watchPartners()
          .first;

      var linkedUserId = '';
      var targetUserId = '';
      var requestSent = false;
      var accountCreated = false;

      if (_createPartnerAccount) {
        final createdProfile = await ref
            .read(authRepositoryProvider)
            .provisionPartnerAccount(
              fullName: _nameController.text.trim(),
              email: normalizedEmail,
              password: _passwordController.text,
              createdBy: session.userId,
              createdByName: session.profile?.name ?? 'شريك',
              workspaceId: workspaceId,
            );
        linkedUserId = createdProfile.uid;
        accountCreated = true;
      } else if (normalizedEmail.isNotEmpty) {
        if (normalizedEmail == currentEmail) {
          linkedUserId = session.userId;
        } else if (_isCurrentPartnerEmail(normalizedEmail)) {
          linkedUserId = widget.partner!.userId;
        } else {
          targetUserId =
              await ref
                  .read(userProfileRemoteDataSourceProvider)
                  .fetchUserIdByEmail(normalizedEmail) ??
              '';
          if (targetUserId.isEmpty) {
            _showMessage('لا يوجد حساب مسجل بهذا البريد الإلكتروني.');
            return;
          }
          if (widget.partner?.userId == targetUserId) {
            linkedUserId = targetUserId;
          } else {
            requestSent = true;
          }
        }
      }

      final now = DateTime.now();
      final previousLinkedUserId = widget.partner?.userId.trim() ?? '';
      final partner = Partner(
        id: widget.partner?.id ?? '',
        userId: linkedUserId,
        linkedEmail: normalizedEmail,
        name: _nameController.text.trim(),
        shareRatio: widget.partner?.shareRatio ?? 0,
        contributionTotal: widget.partner?.contributionTotal ?? 0,
        createdAt: widget.partner?.createdAt ?? now,
        updatedAt: now,
        createdBy: widget.partner?.createdBy ?? session.userId,
        updatedBy: session.userId,
        workspaceId: widget.partner?.workspaceId ?? workspaceId,
      );

      final partnerId = await ref
          .read(partnerRepositoryProvider)
          .upsert(partner);

      if (linkedUserId.isNotEmpty) {
        await _unlinkOtherPartners(
          partners: existingPartners,
          linkedUserId: linkedUserId,
          keepPartnerId: partnerId,
        );
        await ref
            .read(userProfileRemoteDataSourceProvider)
            .setPartnerLink(
              uid: linkedUserId,
              partnerId: partnerId,
              partnerName: partner.name,
              workspaceId: workspaceId,
            );
      }

      if (previousLinkedUserId.isNotEmpty &&
          previousLinkedUserId != linkedUserId) {
        await ref
            .read(userProfileRemoteDataSourceProvider)
            .clearPartnerLink(
              previousLinkedUserId,
              expectedPartnerId: widget.partner?.id,
            );
      }

      if (requestSent && targetUserId.isNotEmpty) {
        await ref
            .read(notificationRepositoryProvider)
            .create(
              userId: targetUserId,
              title: 'طلب ربط حساب',
              body:
                  '${session.profile?.name ?? 'شريك'} أرسل طلب ربط حساب للشريك ${partner.name}.',
              type: NotificationType.partnerLinkRequest,
              route: AppRoutes.partners,
              referenceKey: 'partner-link-request-$partnerId-$targetUserId',
              metadata: {
                'partnerId': partnerId,
                'partnerName': partner.name,
                'requesterUserId': session.userId,
                'requesterName': session.profile?.name ?? 'شريك',
                'requesterEmail': currentEmail,
              },
              workspaceId: workspaceId,
            );
      }

      await ref
          .read(activityRepositoryProvider)
          .log(
            actorId: session.userId,
            actorName: session.profile?.name ?? 'شريك',
            action: widget.partner == null
                ? 'partner_created'
                : 'partner_updated',
            entityType: 'partner',
            entityId: partnerId,
            metadata: {
              'shareRatio': partner.shareRatio,
              'contributionTotal': partner.contributionTotal,
              'linkedEmail': partner.linkedEmail,
              'linkedUserId': linkedUserId,
              'linkedToCurrentUser': linkedUserId == session.userId,
              'requestSent': requestSent,
              'accountCreated': accountCreated,
            },
            workspaceId: workspaceId,
          );

      if (!mounted) return;

      _showMessage(
        accountCreated
            ? 'تم إنشاء حساب الشريك وربطه مباشرة. أول ما يسجل دخول هيظهر له نفس المشروعات والحسابات.'
            : requestSent
            ? 'تم حفظ الشريك وإرسال طلب ربط الحساب.'
            : linkedUserId == session.userId
            ? 'تم حفظ الشريك وربطه بالحساب الحالي.'
            : linkedUserId.isNotEmpty
            ? 'تم حفظ الشريك وربطه بالحساب المحدد.'
            : 'تم حفظ بيانات الشريك.',
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      _showMessage(mapException(error).message);
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
      await ref
          .read(partnerRepositoryProvider)
          .upsert(
            partner.copyWith(
              userId: '',
              linkedEmail: '',
              updatedAt: DateTime.now(),
            ),
          );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isCurrentPartnerEmail(String normalizedEmail) {
    final partner = widget.partner;
    if (partner == null || partner.userId.isEmpty) {
      return false;
    }
    return partner.linkedEmail.trim().toLowerCase() == normalizedEmail;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppFormSheet(
      title: widget.partner == null ? 'إنشاء شريك وحساب دخول' : 'تعديل الشريك',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'اسم الشريك'),
              validator: AuthValidators.name,
            ),
            if (_canCreateLinkedAccount) ...[
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _createPartnerAccount,
                onChanged: _linkToCurrentAccount
                    ? null
                    : (value) => setState(() {
                        _createPartnerAccount = value;
                        if (value) {
                          _linkToCurrentAccount = false;
                        }
                      }),
                title: const Text('إنشاء حساب دخول للشريك'),
                subtitle: const Text(
                  'اكتب اسم الشريك وإيميله وكلمة المرور، وبعد أول تسجيل دخول هيظهر له نفس المشروعات والحسابات.',
                ),
              ),
            ],
            const SizedBox(height: 4),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _linkToCurrentAccount,
              onChanged: _createPartnerAccount
                  ? null
                  : (value) => setState(() {
                      _linkToCurrentAccount = value;
                      if (value) {
                        final session = ref
                            .read(authSessionProvider)
                            .valueOrNull;
                        _emailController.text = _resolveSessionEmail(session);
                      }
                    }),
              title: const Text('ربط بالحساب الحالي مباشرة'),
              subtitle: const Text(
                'استخدمه فقط لو هذا الشريك هو نفس الحساب المفتوح الآن.',
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              enabled: !_linkToCurrentAccount,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'إيميل تسجيل الدخول',
                helperText: _createPartnerAccount
                    ? 'هذا الإيميل وكلمة المرور هما بيانات دخول الشريك.'
                    : 'اكتب إيميل حساب موجود لربطه بالشريك أو لإرسال طلب ربط.',
                helperStyle: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
              validator: (value) {
                final text = (value ?? '').trim();
                if (_linkToCurrentAccount) {
                  return null;
                }
                if (text.isEmpty) {
                  return _createPartnerAccount
                      ? 'أدخل بريد الشريك لإنشاء الحساب.'
                      : null;
                }
                return AuthValidators.email(text);
              },
            ),
            if (_createPartnerAccount) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: AuthValidators.password,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'تأكيد كلمة المرور',
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) => AuthValidators.confirmPassword(
                  value,
                  _passwordController.text,
                ),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: Text(
                  _saving
                      ? 'جار الحفظ...'
                      : _createPartnerAccount
                      ? 'إنشاء الحساب وربط الشريك'
                      : _linkToCurrentAccount
                      ? 'حفظ وربط بالحساب الحالي'
                      : 'حفظ وإرسال طلب ربط',
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

String _resolveWorkspaceId(AppSession? session) {
  final workspaceId = session?.profile?.workspaceId.trim() ?? '';
  if (workspaceId.isNotEmpty) {
    return workspaceId;
  }
  return 'workspace_main';
}
