import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/widgets/app_shell_scaffold.dart';
import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:aqarelmasryeen/core/widgets/load_failure_view.dart';
import 'package:aqarelmasryeen/features/auth/data/firebase_auth_repository.dart';
import 'package:aqarelmasryeen/features/auth/domain/app_session.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/notifications/data/notification_repository.dart';
import 'package:aqarelmasryeen/features/partners/data/partner_repository.dart';
import 'package:aqarelmasryeen/features/partners/domain/partner_account_summary.dart';
import 'package:aqarelmasryeen/features/partners/presentation/partner_form_sheet.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/app_user.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final partnersStreamProvider = StreamProvider.autoDispose<List<Partner>>(
  (ref) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final workspaceId = session?.profile?.workspaceId.trim() ?? '';
    return ref.watch(partnerRepositoryProvider).watchPartners().map(
      (partners) => workspaceId.isEmpty
          ? const <Partner>[]
          : partners
                .where((partner) => partner.workspaceId.trim() == workspaceId)
                .toList(growable: false),
    );
  },
);

final partnerAccountsStreamProvider = StreamProvider.autoDispose<List<AppUser>>(
  (ref) {
    return ref
        .watch(userProfileRemoteDataSourceProvider)
        .watchAllProfiles();
  },
);

final partnerAccountsProvider =
    Provider.autoDispose<AsyncValue<List<PartnerAccountSummary>>>((ref) {
      final usersAsync = ref.watch(partnerAccountsStreamProvider);
      final partnersAsync = ref.watch(partnersStreamProvider);
      if (usersAsync.hasError) {
        return AsyncError(
          usersAsync.error!,
          usersAsync.stackTrace ?? StackTrace.current,
        );
      }
      if (partnersAsync.hasError) {
        return AsyncError(
          partnersAsync.error!,
          partnersAsync.stackTrace ?? StackTrace.current,
        );
      }
      if (!usersAsync.hasValue || !partnersAsync.hasValue) {
        return const AsyncLoading();
      }

      final session = ref.watch(authSessionProvider).valueOrNull;
      final currentUserId = session?.userId ?? '';
      final users = usersAsync.valueOrNull ?? const <AppUser>[];
      final partners = partnersAsync.valueOrNull ?? const <Partner>[];
      final usersById = {for (final user in users) user.uid: user};
      final partnerByUserId = {
        for (final partner in partners)
          if (partner.userId.trim().isNotEmpty) partner.userId: partner,
      };

      final summaries = users.map((user) {
        final linkedPartner =
            partnerByUserId[user.uid] ??
            partners.firstWhereOrNull(
              (partner) => partner.id == user.linkedPartnerId,
            );
        final creator = usersById[user.createdBy];
        final createdByCurrentUser =
            currentUserId.isNotEmpty && user.createdBy == currentUserId;
        final creatorName = createdByCurrentUser
            ? 'أنا'
            : user.createdByName.trim().isNotEmpty
            ? user.createdByName.trim()
            : creator?.fullName.trim().isNotEmpty == true
            ? creator!.fullName.trim()
            : 'غير محدد';
        return PartnerAccountSummary(
          user: user,
          linkedPartner: linkedPartner,
          createdByName: creatorName,
          createdByCurrentUser: createdByCurrentUser,
        );
      }).toList(growable: false)
        ..sort((a, b) => b.user.createdAt.compareTo(a.user.createdAt));

      return AsyncData(summaries);
    });

final pendingPartnerLinkRequestsProvider =
    StreamProvider.autoDispose<List<AppNotificationItem>>((ref) async* {
      final AppSession? session = await ref.watch(authSessionProvider.future);
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

enum _PartnerAccountsFilter {
  all,
  createdByMe,
  linkedOnly,
  unlinked,
  hasLoginAccount,
  availableForLink,
}

class PartnersScreen extends ConsumerStatefulWidget {
  const PartnersScreen({super.key});

  @override
  ConsumerState<PartnersScreen> createState() => _PartnersScreenState();
}

class _PartnersScreenState extends ConsumerState<PartnersScreen> {
  final TextEditingController _searchController = TextEditingController();
  _PartnersFilter _activeFilter = _PartnersFilter.all;
  _PartnerAccountsFilter _activeAccountFilter = _PartnerAccountsFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final currentUserId = session?.userId ?? '';
    final partnersAsync = ref.watch(partnersStreamProvider);
    final accountsAsync = ref.watch(partnerAccountsProvider);
    final pendingRequestsAsync = ref.watch(pendingPartnerLinkRequestsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppShellScaffold(
        title: 'الشركاء',
        currentIndex: 2,
        actions: _buildActions(context, ref, pendingRequestsAsync),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openPartnerForm,
          icon: const Icon(Icons.add),
          label: const Text('إنشاء شريك'),
        ),
        child: partnersAsync.when(
          data: (partnerItems) {
            final filteredPartners = _applyFilters(partnerItems);
            final hasAccountCount = partnerItems.where(_hasAccount).length;
            final noAccountCount = partnerItems.length - hasAccountCount;
            final pendingCount = pendingRequestsAsync.valueOrNull?.length ?? 0;
            final accountItems =
                accountsAsync.valueOrNull ?? const <PartnerAccountSummary>[];
            final filteredAccounts = _applyAccountFilters(
              accountItems,
              currentUserId,
            );
            final availableLinkCount = accountItems
                .where((item) => !item.isLinked && item.user.isActive)
                .length;

            return ListView(
              padding: const EdgeInsets.all(6),
              children: [
                _StatsCard(
                  partnerCount: partnerItems.length,
                  hasAccountCount: hasAccountCount,
                  noAccountCount: noAccountCount,
                ),
                const SizedBox(height: 16),
                _PartnerToolbar(
                  searchController: _searchController,
                  activeFilter: _activeFilter,
                  pendingCount: pendingCount,
                  onCreatePartner: _openPartnerForm,
                  onLinkAccount: _openLinkAccountFlow,
                  onFilterChanged: (filter) {
                    setState(() => _activeFilter = filter);
                  },
                  onSearchChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                _PartnerAccountsSection(
                  accountsAsync: accountsAsync,
                  accounts: filteredAccounts,
                  activeFilter: _activeAccountFilter,
                  totalAccountsCount: accountItems.length,
                  createdByMeCount: currentUserId.isEmpty
                      ? 0
                      : accountItems
                            .where((item) => item.createdByCurrentUser)
                            .length,
                  linkedCount: accountItems.where((item) => item.isLinked).length,
                  availableLinkCount: availableLinkCount,
                  onFilterChanged: (filter) {
                    setState(() => _activeAccountFilter = filter);
                  },
                  onRetry: () {
                    ref.invalidate(partnerAccountsStreamProvider);
                    ref.invalidate(partnerAccountsProvider);
                  },
                ),
                const SizedBox(height: 12),
                if (partnerItems.isEmpty)
                  EmptyStateView(
                    title: session?.profile?.workspaceId.trim().isEmpty == true
                        ? 'لا توجد بيانات شركاء'
                        : 'لا يوجد شركاء حاليًا',
                    message: session?.profile?.workspaceId.trim().isEmpty == true
                        ? 'هذا الحساب غير مرتبط بأي مساحة عمل حاليًا.'
                        : 'ابدأ بإضافة شريك جديد أو ربط حساب موجود',
                    actionLabel: 'إنشاء شريك',
                    onAction: _openPartnerForm,
                  )
                else if (filteredPartners.isEmpty)
                  const EmptyStateView(
                    title: 'لا توجد نتائج',
                    message: 'جرّب البحث باسم مختلف أو غيّر الفلتر الحالي',
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
          error: (error, _) => LoadFailureView(
            title: 'تعذر تحميل بيانات الشركاء',
            error: error,
            onRetry: () {
              ref.invalidate(partnersStreamProvider);
              ref.invalidate(partnerAccountsStreamProvider);
              ref.invalidate(partnerAccountsProvider);
              ref.invalidate(pendingPartnerLinkRequestsProvider);
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  List<Widget>? _buildActions(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<AppNotificationItem>> pendingRequests,
  ) {
    return pendingRequests.when(
      data: (items) {
        if (items.isEmpty) {
          return null;
        }

        return [
          Padding(
            padding: const EdgeInsetsDirectional.only(
              end: 4,
              top: 8,
              bottom: 8,
            ),
            child: FilledButton.tonalIcon(
              onPressed: () => _showPendingRequestsSheet(context, ref, items),
              icon: const Icon(Icons.handshake_outlined, size: 18),
              label: Text(items.length == 1 ? 'طلب ربط' : 'طلبات الربط'),
            ),
          ),
        ];
      },
      error: (_, _) => null,
      loading: () => null,
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

  List<PartnerAccountSummary> _applyAccountFilters(
    List<PartnerAccountSummary> source,
    String currentUserId,
  ) {
    final query = _searchController.text.trim().toLowerCase();

    return source.where((item) {
      final passesFilter = switch (_activeAccountFilter) {
        _PartnerAccountsFilter.all => true,
        _PartnerAccountsFilter.createdByMe =>
          currentUserId.isNotEmpty && item.createdByCurrentUser,
        _PartnerAccountsFilter.linkedOnly => item.isLinked,
        _PartnerAccountsFilter.unlinked => !item.isLinked,
        _PartnerAccountsFilter.hasLoginAccount =>
          item.user.email.trim().isNotEmpty,
        _PartnerAccountsFilter.availableForLink =>
          !item.isLinked && item.user.isActive,
      };

      if (!passesFilter) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final uidPreview = _shortUid(item.user.uid).toLowerCase();
      return item.user.fullName.toLowerCase().contains(query) ||
          item.user.email.toLowerCase().contains(query) ||
          item.createdByName.toLowerCase().contains(query) ||
          uidPreview.contains(query) ||
          (item.linkedPartner?.name.toLowerCase().contains(query) ?? false);
    }).toList(growable: false);
  }

  Future<void> _openPartnerForm({Partner? partner}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => PartnerFormSheet(partner: partner),
    );
  }

  Future<void> _openLinkAccountFlow() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    final workspaceId = session?.profile?.workspaceId.trim() ?? '';
    if (workspaceId.isEmpty) {
      _showInfoSnackBar('هذا الحساب غير مرتبط بأي مساحة عمل حاليًا.');
      return;
    }

    final partners = ref.read(partnersStreamProvider).valueOrNull ?? const [];
    final accounts = ref.read(partnerAccountsProvider).valueOrNull ?? const [];
    if (partners.isEmpty) {
      _showInfoSnackBar('لا يوجد شركاء متاحون للربط حاليًا.');
      return;
    }

    final availablePartners = partners
        .where((partner) => partner.userId.trim().isEmpty)
        .toList(growable: false);
    if (availablePartners.isEmpty) {
      _showInfoSnackBar('كل الشركاء مرتبطون بالفعل.');
      return;
    }

    final availableUsers = accounts
        .where((account) => !account.isLinked && account.user.isActive)
        .toList(growable: false);
    if (availableUsers.isEmpty) {
      _showInfoSnackBar('لا يوجد مستخدمون متاحون للربط');
      return;
    }

    String? selectedPartnerId = availablePartners.first.id;
    String? selectedUserId = availableUsers.first.user.uid;
    var selectedStep = 0;

    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocalState) {
          return AlertDialog(
            title: const Text('ربط حساب'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('1) اختيار الشريك'),
                        selected: selectedStep == 0,
                        onSelected: (_) =>
                            setLocalState(() => selectedStep = 0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('2) اختيار الحساب'),
                        selected: selectedStep == 1,
                        onSelected: (_) =>
                            setLocalState(() => selectedStep = 1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (selectedStep == 0)
                DropdownButtonFormField<String>(
                  initialValue: selectedPartnerId,
                  decoration: const InputDecoration(labelText: 'اختيار شريك'),
                  items: [
                    for (final partner in availablePartners)
                      DropdownMenuItem(
                        value: partner.id,
                        child: Text(partner.name),
                      ),
                  ],
                  onChanged: (value) => setLocalState(() {
                    selectedPartnerId = value;
                  }),
                ),
                if (selectedStep == 0) const SizedBox(height: 12),
                if (selectedStep == 1)
                DropdownButtonFormField<String>(
                  initialValue: selectedUserId,
                  decoration: const InputDecoration(labelText: 'اختيار مستخدم'),
                  items: [
                    for (final account in availableUsers)
                      DropdownMenuItem(
                        value: account.user.uid,
                        child: Text(
                          '${account.user.fullName} - ${account.user.email}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => setLocalState(() {
                    selectedUserId = value;
                  }),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('إلغاء'),
              ),
              if (selectedStep == 0)
                OutlinedButton(
                  onPressed: () => setLocalState(() => selectedStep = 1),
                  child: const Text('التالي'),
                ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('تنفيذ الربط'),
              ),
            ],
          );
        },
      ),
    );

    if (approved != true || selectedPartnerId == null || selectedUserId == null) {
      return;
    }
    final selectedPartner = availablePartners.firstWhereOrNull(
      (partner) => partner.id == selectedPartnerId,
    );
    final selectedAccount = accounts.firstWhereOrNull(
      (account) => account.user.uid == selectedUserId,
    );
    if (selectedPartner == null || selectedAccount == null) {
      _showInfoSnackBar('تعذر العثور على بيانات الربط المطلوبة.');
      return;
    }
    await _linkPartnerToUser(
      partner: selectedPartner,
      user: selectedAccount.user,
      workspaceId: workspaceId,
    );
  }

  Future<void> _linkPartnerToUser({
    required Partner partner,
    required AppUser user,
    required String workspaceId,
  }) async {
    if (partner.userId.trim().isNotEmpty && partner.userId.trim() == user.uid.trim()) {
      _showInfoSnackBar('هذا الشريك مرتبط بالفعل بنفس المستخدم.');
      return;
    }
    if (user.linkedPartnerId.trim().isNotEmpty &&
        user.linkedPartnerId.trim() != partner.id.trim()) {
      _showInfoSnackBar('هذا المستخدم مرتبط بالفعل بشريك آخر.');
      return;
    }

    await _unlinkUserFromOtherPartners(user.uid, exceptPartnerId: partner.id);
    if (partner.userId.trim().isNotEmpty && partner.userId != user.uid) {
      await ref
          .read(userProfileRemoteDataSourceProvider)
          .clearPartnerLink(partner.userId, expectedPartnerId: partner.id);
    }

    await ref.read(partnerRepositoryProvider).upsert(
      partner.copyWith(
        userId: user.uid,
        linkedEmail: user.email.trim().toLowerCase(),
        workspaceId: workspaceId,
        updatedAt: DateTime.now(),
      ),
    );
    await ref.read(userProfileRemoteDataSourceProvider).setPartnerLink(
      uid: user.uid,
      partnerId: partner.id,
      partnerName: partner.name,
      workspaceId: workspaceId,
    );
    _showInfoSnackBar('تم ربط الحساب بالشريك بنجاح');
  }

  Future<void> _unlinkUserFromOtherPartners(
    String userId, {
    required String exceptPartnerId,
  }) async {
    final partners = ref.read(partnersStreamProvider).valueOrNull ?? const [];
    for (final partner in partners) {
      if (partner.id == exceptPartnerId || partner.userId.trim() != userId.trim()) {
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

  Future<void> _showManageAccountSheet(Partner partner) async {
    final hasAccount = _hasAccount(partner);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إدارة الحساب - ${partner.name}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
                    _showInfoSnackBar(
                      'تم إرسال إجراء إعادة تعيين كلمة المرور.',
                    );
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
                    _openPartnerForm(partner: partner);
                  },
                ),
                _ActionTile(
                  icon: Icons.link_rounded,
                  label: 'ربط بحساب موجود',
                  onTap: () {
                    Navigator.of(context).pop();
                    _openLinkAccountFlow();
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

    if (partner.userId.trim().isNotEmpty) {
      await ref
          .read(userProfileRemoteDataSourceProvider)
          .clearPartnerLink(partner.userId, expectedPartnerId: partner.id);
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
    if (partner.userId.trim().isNotEmpty) {
      await ref
          .read(userProfileRemoteDataSourceProvider)
          .clearPartnerLink(partner.userId, expectedPartnerId: partner.id);
    }
    _showInfoSnackBar('تم فك ربط الحساب من الشريك.');
  }

  void _showInfoSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
          Expanded(
            child: _StatItem(label: 'عدد الشركاء', value: '$partnerCount'),
          ),
          _buildDivider(theme),
          Expanded(
            child: _StatItem(label: 'مرتبطين بحساب', value: '$hasAccountCount'),
          ),
          _buildDivider(theme),
          Expanded(
            child: _StatItem(label: 'بدون حساب', value: '$noAccountCount'),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: theme.colorScheme.outlineVariant,
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
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
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

class _PartnerAccountsSection extends StatelessWidget {
  const _PartnerAccountsSection({
    required this.accountsAsync,
    required this.accounts,
    required this.activeFilter,
    required this.totalAccountsCount,
    required this.createdByMeCount,
    required this.linkedCount,
    required this.availableLinkCount,
    required this.onFilterChanged,
    required this.onRetry,
  });

  final AsyncValue<List<PartnerAccountSummary>> accountsAsync;
  final List<PartnerAccountSummary> accounts;
  final _PartnerAccountsFilter activeFilter;
  final int totalAccountsCount;
  final int createdByMeCount;
  final int linkedCount;
  final int availableLinkCount;
  final ValueChanged<_PartnerAccountsFilter> onFilterChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7E9EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الحسابات داخل النظام',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'عرض المستخدمين الذين لديهم حسابات فعلية أو تم إنشاؤهم وربطهم بالنظام.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TagPill(
                icon: Icons.people_alt_outlined,
                label: 'كل الحسابات: $totalAccountsCount',
              ),
              _TagPill(
                icon: Icons.person_add_alt_rounded,
                label: 'أنشأتها أنا: $createdByMeCount',
              ),
              _TagPill(
                icon: Icons.link_rounded,
                label: 'المرتبطة: $linkedCount',
              ),
              _TagPill(
                icon: Icons.person_search_rounded,
                label: 'المتاحة للربط: $availableLinkCount',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChipButton(
                label: 'كل المستخدمين',
                selected: activeFilter == _PartnerAccountsFilter.all,
                onTap: () => onFilterChanged(_PartnerAccountsFilter.all),
              ),
              _FilterChipButton(
                label: 'تم إنشاؤهم بواسطتي',
                selected: activeFilter == _PartnerAccountsFilter.createdByMe,
                onTap: () => onFilterChanged(_PartnerAccountsFilter.createdByMe),
              ),
              _FilterChipButton(
                label: 'المرتبطون فقط',
                selected: activeFilter == _PartnerAccountsFilter.linkedOnly,
                onTap: () => onFilterChanged(_PartnerAccountsFilter.linkedOnly),
              ),
              _FilterChipButton(
                label: 'غير المرتبطين',
                selected: activeFilter == _PartnerAccountsFilter.unlinked,
                onTap: () => onFilterChanged(_PartnerAccountsFilter.unlinked),
              ),
              _FilterChipButton(
                label: 'الذين لهم حساب',
                selected: activeFilter == _PartnerAccountsFilter.hasLoginAccount,
                onTap: () =>
                    onFilterChanged(_PartnerAccountsFilter.hasLoginAccount),
              ),
              _FilterChipButton(
                label: 'المتاحون للربط',
                selected: activeFilter == _PartnerAccountsFilter.availableForLink,
                onTap: () =>
                    onFilterChanged(_PartnerAccountsFilter.availableForLink),
              ),
            ],
          ),
          const SizedBox(height: 12),
          accountsAsync.when(
            data: (_) {
              if (totalAccountsCount == 0) {
                return const EmptyStateView(
                  title: 'لا توجد حسابات مسجلة داخل النظام',
                  message: 'تأكد من إنشاء profile للمستخدمين داخل مجموعة users.',
                );
              }
              if (accounts.isEmpty) {
                return const EmptyStateView(
                  title: 'لا توجد نتائج مطابقة',
                  message: 'جرّب تغيير فلتر الحسابات أو تعديل عبارة البحث.',
                );
              }
              return Column(
                children: [
                  for (var index = 0; index < accounts.length; index++) ...[
                    _PartnerAccountCard(summary: accounts[index]),
                    if (index != accounts.length - 1) const SizedBox(height: 10),
                  ],
                ],
              );
            },
            error: (error, _) => LoadFailureView(
              title: 'تعذر تحميل حسابات المستخدمين',
              error: error,
              onRetry: onRetry,
            ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }
}

class _PartnerAccountCard extends StatelessWidget {
  const _PartnerAccountCard({required this.summary});

  final PartnerAccountSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = summary.user;
    final linkedPartnerName =
        summary.linkedPartner?.name.trim().isNotEmpty == true
        ? summary.linkedPartner!.name.trim()
        : user.linkedPartnerName.trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EAF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFE8ECF5),
                child: Text(
                  user.fullName.trim().isEmpty ? '?' : user.fullName.trim()[0],
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName.trim().isEmpty
                          ? 'مستخدم بدون اسم'
                          : user.fullName.trim(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email.trim().isEmpty
                          ? 'لا يوجد بريد إلكتروني'
                          : user.email.trim(),
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
              const _TagPill(
                icon: Icons.verified_user_outlined,
                label: 'لديه حساب',
              ),
              _TagPill(
                icon: summary.createdByCurrentUser
                    ? Icons.person_add_alt_1_rounded
                    : Icons.badge_outlined,
                label: summary.createdByCurrentUser
                    ? 'تم إنشاؤه بواسطتي'
                    : 'أنشأه ${summary.createdByName}',
              ),
              _TagPill(
                icon: summary.isLinked
                    ? Icons.link_rounded
                    : Icons.link_off_rounded,
                label: summary.isLinked
                    ? 'مرتبط: ${linkedPartnerName.isEmpty ? 'نعم' : linkedPartnerName}'
                    : 'غير مرتبط',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              _InfoText(label: 'تاريخ الإنشاء', value: user.createdAt.formatShort()),
              _InfoText(label: 'UID مختصر', value: _shortUid(user.uid)),
              _InfoText(
                label: 'مساحة العمل',
                value: user.workspaceId.trim().isEmpty
                    ? 'غير محدد'
                    : user.workspaceId.trim(),
              ),
              _InfoText(
                label: 'حالة الحساب',
                value: user.isActive ? 'نشط' : 'معطل',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoText extends StatelessWidget {
  const _InfoText({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: const Color(0xFF59607A)),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: value),
        ],
      ),
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

String _shortUid(String uid) {
  final normalized = uid.trim();
  if (normalized.length <= 8) {
    return normalized;
  }
  return '${normalized.substring(0, 8)}...';
}

void _showPendingRequestsSheet(
  BuildContext context,
  WidgetRef ref,
  List<AppNotificationItem> requests,
) {
  showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _PendingRequestsSheet(
      requests: requests,
      onAccept: (request) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تمت مراجعة طلب الربط.')));
      },
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
            const SizedBox(height: 12),
            if (requests.isEmpty)
              const EmptyStateView(
                title: 'لا توجد طلبات ربط',
                message: 'عند وصول طلبات جديدة ستظهر هنا.',
              )
            else
              ...requests.map(
                (request) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(request.title),
                    subtitle: Text(
                      request.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: FilledButton.tonal(
                      onPressed: () => onAccept(request),
                      child: const Text('مراجعة'),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
