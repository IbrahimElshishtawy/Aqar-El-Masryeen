import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/core/widgets/app_shell_scaffold.dart';
import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:aqarelmasryeen/features/auth/domain/app_session.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/notifications/data/notification_repository.dart';
import 'package:aqarelmasryeen/features/partners/data/partner_repository.dart';
import 'package:aqarelmasryeen/features/partners/presentation/partner_form_sheet.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final partnersStreamProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(partnerRepositoryProvider).watchPartners(),
);

final pendingPartnerLinkRequestsProvider =
    StreamProvider.autoDispose<List<AppNotificationItem>>((ref) async* {
      final session = await ref.watch(authSessionProvider.future);
      if (session == null) {
        yield const [];
        return;
      }
      yield* ref
          .watch(notificationRepositoryProvider)
          .watchNotifications(session.userId)
          .map(
            (items) => items
                .where(
                  (item) =>
                      !item.isRead &&
                      item.type == NotificationType.partnerLinkRequest,
                )
                .toList(),
          );
    });

enum _PartnersFilter { all, hasAccount, noAccount }

class PartnersScreen extends ConsumerStatefulWidget {
  const PartnersScreen({super.key});

  @override
  ConsumerState<PartnersScreen> createState() => _PartnersScreenState();
}

class _PartnersScreenState extends ConsumerState<PartnersScreen> {
  final TextEditingController _searchController = TextEditingController();
  _PartnersFilter _activeFilter = _PartnersFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final partners = ref.watch(partnersStreamProvider);
    final pendingRequests = ref.watch(pendingPartnerLinkRequestsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppShellScaffold(
        title: 'الشركاء',
        currentIndex: 2,
        child: partners.when(
          data: (partnerItems) {
            final filteredPartners = _applyFilters(partnerItems);
            final hasAccountCount = partnerItems.where(_hasAccount).length;
            final noAccountCount = partnerItems.length - hasAccountCount;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const _HeaderSection(),
                const SizedBox(height: 14),
                _StatsCard(
                  partnerCount: partnerItems.length,
                  hasAccountCount: hasAccountCount,
                  noAccountCount: noAccountCount,
                ),
                const SizedBox(height: 16),
                _PartnerToolbar(
                  searchController: _searchController,
                  activeFilter: _activeFilter,
                  pendingCount: pendingRequests.valueOrNull?.length ?? 0,
                  onCreatePartner: () => _openPartnerForm(),
                  onLinkAccount: () => _openLinkingOptionsSheet(
                    context: context,
                    ref: ref,
                    pendingRequests: pendingRequests.valueOrNull ?? const [],
                  ),
                  onFilterChanged: (filter) {
                    setState(() => _activeFilter = filter);
                  },
                  onSearchChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                if (filteredPartners.isEmpty)
                  EmptyStateView(
                    title: 'لا يوجد شركاء حاليًا',
                    message: 'ابدأ بإضافة شريك جديد أو ربط حساب موجود',
                    actionLabel: 'إنشاء شريك',
                    onAction: _openPartnerForm,
                  )
                else
                  ...filteredPartners.map(
                    (partner) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PartnerCard(
                        partner: partner,
                        onEdit: () => _openPartnerForm(partner: partner),
                        onManageAccount: () => _showManageAccountSheet(partner),
                        onDelete: () => _confirmDeletePartner(partner),
                      ),
                    ),
                  ),
              ],
            );
          },
          error: (error, _) => Center(child: Text(error.toString())),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  List<Partner> _applyFilters(List<Partner> source) {
    final query = _searchController.text.trim().toLowerCase();

    return source.where((partner) {
      final hasAccount = _hasAccount(partner);
      final passesFilter = switch (_activeFilter) {
        _PartnersFilter.all => true,
        _PartnersFilter.hasAccount => hasAccount,
        _PartnersFilter.noAccount => !hasAccount,
      };

      if (!passesFilter) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final name = partner.name.toLowerCase();
      final email = partner.linkedEmail.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();
  }

  Future<void> _openPartnerForm({Partner? partner}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => PartnerFormSheet(partner: partner),
    );
  }

  Future<void> _showManageAccountSheet(Partner partner) async {
    final hasAccount = _hasAccount(partner);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إدارة الحساب - ${partner.name}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hasAccount
                    ? 'يمكنك إدارة حالة الحساب المرتبط بهذا الشريك.'
                    : 'لا يوجد حساب دخول مرتبط بهذا الشريك حاليًا.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              if (hasAccount) ...[
                _ActionTile(
                  icon: Icons.link_off_rounded,
                  label: 'فك ربط الحساب',
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _unlinkPartnerAccount(partner);
                  },
                ),
                _ActionTile(
                  icon: Icons.lock_reset_rounded,
                  label: 'إعادة تعيين كلمة المرور',
                  onTap: () {
                    Navigator.of(context).pop();
                    _showInfoSnackBar('تم إرسال إجراء إعادة تعيين كلمة المرور.');
                  },
                ),
                _ActionTile(
                  icon: Icons.block_rounded,
                  label: 'تعطيل الحساب',
                  onTap: () {
                    Navigator.of(context).pop();
                    _showInfoSnackBar('تم تعطيل الحساب مؤقتًا.');
                  },
                ),
              ] else ...[
                _ActionTile(
                  icon: Icons.person_add_alt_1_rounded,
                  label: 'إنشاء حساب دخول',
                  onTap: () {
                    Navigator.of(context).pop();
                    _showInfoSnackBar('يتم تجهيز إنشاء حساب دخول لهذا الشريك.');
                  },
                ),
                _ActionTile(
                  icon: Icons.link_rounded,
                  label: 'ربط بحساب موجود',
                  onTap: () {
                    Navigator.of(context).pop();
                    _showInfoSnackBar('اختر حسابًا موجودًا لربطه بهذا الشريك.');
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeletePartner(Partner partner) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الشريك'),
        content: Text('هل أنت متأكد من حذف الشريك "${partner.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (approved != true) {
      return;
    }

    await ref.read(partnerRepositoryProvider).delete(partner.id);
    _showInfoSnackBar('تم حذف الشريك بنجاح.');
  }

  Future<void> _unlinkPartnerAccount(Partner partner) async {
    final updatedPartner = partner.copyWith(
      userId: '',
      linkedEmail: '',
      updatedAt: DateTime.now(),
    );
    await ref.read(partnerRepositoryProvider).upsert(updatedPartner);
    _showInfoSnackBar('تم فك ربط الحساب من الشريك.');
  }

  void _showInfoSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الشركاء',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'إدارة حسابات الشركاء وربطهم بالمشروعات',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.partnerCount,
    required this.hasAccountCount,
    required this.noAccountCount,
  });

  final int partnerCount;
  final int hasAccountCount;
  final int noAccountCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6EAF2)),
      ),
      child: Row(
        children: [
          Expanded(child: _StatItem(label: 'عدد الشركاء', value: '$partnerCount')),
          _buildDivider(theme),
          Expanded(
            child: _StatItem(
              label: 'مرتبطين بحساب',
              value: '$hasAccountCount',
            ),
          ),
          _buildDivider(theme),
          Expanded(
            child: _StatItem(
              label: 'بدون حساب',
              value: '$noAccountCount',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Container(
      width: 1,
      height: 34,
      color: theme.colorScheme.outlineVariant,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PartnerToolbar extends StatelessWidget {
  const _PartnerToolbar({
    required this.searchController,
    required this.activeFilter,
    required this.pendingCount,
    required this.onCreatePartner,
    required this.onLinkAccount,
    required this.onFilterChanged,
    required this.onSearchChanged,
  });

  final TextEditingController searchController;
  final _PartnersFilter activeFilter;
  final int pendingCount;
  final VoidCallback onCreatePartner;
  final VoidCallback onLinkAccount;
  final ValueChanged<_PartnersFilter> onFilterChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7E9EE)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onCreatePartner,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('إنشاء شريك'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onLinkAccount,
                  icon: const Icon(Icons.link_rounded),
                  label: Text(
                    pendingCount > 0 ? 'ربط حساب ($pendingCount)' : 'ربط حساب',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'ابحث باسم الشريك أو البريد الإلكتروني',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: const Color(0xFFF6F7FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Wrap(
              spacing: 8,
              children: [
                _FilterChipButton(
                  label: 'الكل',
                  selected: activeFilter == _PartnersFilter.all,
                  onTap: () => onFilterChanged(_PartnersFilter.all),
                ),
                _FilterChipButton(
                  label: 'له حساب',
                  selected: activeFilter == _PartnersFilter.hasAccount,
                  onTap: () => onFilterChanged(_PartnersFilter.hasAccount),
                ),
                _FilterChipButton(
                  label: 'بدون حساب',
                  selected: activeFilter == _PartnersFilter.noAccount,
                  onTap: () => onFilterChanged(_PartnersFilter.noAccount),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  const _PartnerCard({
    required this.partner,
    required this.onEdit,
    required this.onManageAccount,
    required this.onDelete,
  });

  final Partner partner;
  final VoidCallback onEdit;
  final VoidCallback onManageAccount;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAccount = _hasAccount(partner);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6E8EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: const Color(0xFFEDEFF7),
                child: Text(
                  partner.name.isEmpty ? '?' : partner.name.characters.first,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF3E4660),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partner.name.isEmpty ? 'شريك بدون اسم' : partner.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      partner.linkedEmail.isEmpty
                          ? 'لا يوجد بريد إلكتروني مرتبط'
                          : partner.linkedEmail,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TagPill(
                icon: Icons.verified_user_outlined,
                label: hasAccount ? 'له حساب دخول' : 'لا يوجد حساب',
              ),
              const _TagPill(
                icon: Icons.business_center_outlined,
                label: 'المشروعات: غير محدد',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('تعديل بيانات الشريك'),
              ),
              FilledButton.tonalIcon(
                onPressed: onManageAccount,
                icon: const Icon(Icons.manage_accounts_outlined),
                label: const Text('إدارة الحساب'),
              ),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('حذف الشريك'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF59607A)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF59607A),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }
}

bool _hasAccount(Partner partner) {
  return partner.userId.isNotEmpty || partner.linkedEmail.isNotEmpty;
}

void _openLinkingOptionsSheet({
  required BuildContext context,
  required WidgetRef ref,
  required List<AppNotificationItem> pendingRequests,
}) {
  showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ربط حساب',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              pendingRequests.isEmpty
                  ? 'يمكنك بدء ربط حساب شريك جديد أو استخدام حساب موجود.'
                  : 'لديك ${pendingRequests.length} طلب ربط بانتظار المراجعة.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            _ActionTile(
              icon: Icons.person_add_rounded,
              label: 'إنشاء حساب لشريك',
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('اختر الشريك ثم أكمل إنشاء الحساب.')),
                );
              },
            ),
            _ActionTile(
              icon: Icons.link_rounded,
              label: 'ربط بحساب موجود',
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('اختر الحساب الموجود لإتمام الربط.')),
                );
              },
            ),
            if (pendingRequests.isNotEmpty)
              _ActionTile(
                icon: Icons.mark_email_read_outlined,
                label: 'مراجعة طلبات الربط',
                onTap: () {
                  Navigator.of(context).pop();
                  _showPendingRequestsSheet(context, ref, pendingRequests);
                },
              ),
          ],
        ),
      ),
    ),
  );
}

class _PendingRequestsSheet extends StatelessWidget {
  const _PendingRequestsSheet({required this.requests, required this.onAccept});

  final List<AppNotificationItem> requests;
  final ValueChanged<AppNotificationItem> onAccept;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'طلبات ربط الحساب',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'وافق على الطلب المناسب لربط حساب الدخول بهذا الشريك.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            for (final request in requests) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F7F2),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFDAD9D1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(request.body),
                    const SizedBox(height: 10),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FilledButton.tonalIcon(
                        onPressed: () => onAccept(request),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('موافقة'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

void _showPendingRequestsSheet(
  BuildContext context,
  WidgetRef ref,
  List<AppNotificationItem> requests,
) {
  showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (_) => _PendingRequestsSheet(
      requests: requests,
      onAccept: (request) async {
        Navigator.of(context).pop();
        await _acceptPartnerRequest(context, ref, request);
      },
    ),
  );
}

Future<void> _acceptPartnerRequest(
  BuildContext context,
  WidgetRef ref,
  AppNotificationItem request,
) async {
  final session = await ref.read(authSessionProvider.future);
  if (session == null) {
    return;
  }
  if (!context.mounted) {
    return;
  }

  final partnerId = request.metadata['partnerId'] as String? ?? '';
  if (partnerId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تعذر قراءة بيانات طلب الربط.')),
    );
    return;
  }

  final partners = await ref.read(partnersStreamProvider.future);
  final partner = partners.firstWhereOrNull((item) => item.id == partnerId);
  if (partner == null) {
    await ref.read(notificationRepositoryProvider).markRead(request.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('هذا الشريك غير موجود الآن.')),
      );
    }
    return;
  }

  final currentEmail = _resolveCurrentEmail(session);
  final updatedPartner = partner.copyWith(
    userId: session.userId,
    linkedEmail: currentEmail,
    updatedAt: DateTime.now(),
  );
  await ref.read(partnerRepositoryProvider).upsert(updatedPartner);
  await _unlinkOtherPartners(
    ref: ref,
    partners: partners,
    linkedUserId: session.userId,
    keepPartnerId: partner.id,
  );
  await ref.read(notificationRepositoryProvider).markRead(request.id);

  final requesterUserId = request.metadata['requesterUserId'] as String? ?? '';
  if (requesterUserId.isNotEmpty && requesterUserId != session.userId) {
    await ref
        .read(notificationRepositoryProvider)
        .create(
          userId: requesterUserId,
          title: 'تم قبول ربط الحساب',
          body:
              '${session.profile?.name ?? 'الشريك'} وافق على ربط الحساب بالشريك ${partner.name}.',
          type: NotificationType.partnerLinkAccepted,
          route: AppRoutes.partners,
          referenceKey: 'partner-link-accepted-${partner.id}-${session.userId}',
          metadata: {
            'partnerId': partner.id,
            'acceptedByUserId': session.userId,
          },
        );
  }

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم قبول الطلب وربط ${partner.name} بحساب الدخول.'),
      ),
    );
  }
}

Future<void> _unlinkOtherPartners({
  required WidgetRef ref,
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

String _resolveCurrentEmail(AppSession session) {
  final profileEmail = session.profile?.email.trim().toLowerCase() ?? '';
  if (profileEmail.isNotEmpty) {
    return profileEmail;
  }
  return session.email?.trim().toLowerCase() ?? '';
}
