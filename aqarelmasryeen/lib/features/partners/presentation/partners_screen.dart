import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/core/widgets/app_shell_scaffold.dart';
import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:aqarelmasryeen/core/widgets/metric_card.dart';
import 'package:aqarelmasryeen/features/auth/domain/app_session.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/expenses/data/expense_repository.dart';
import 'package:aqarelmasryeen/features/notifications/data/notification_repository.dart';
import 'package:aqarelmasryeen/features/partners/data/partner_repository.dart';
import 'package:aqarelmasryeen/features/partners/domain/partner_settlement_calculator.dart';
import 'package:aqarelmasryeen/features/partners/presentation/partner_form_sheet.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final partnersStreamProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(partnerRepositoryProvider).watchPartners(),
);

final partnersExpensesProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(expenseRepositoryProvider).watchAll(),
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

class PartnersScreen extends ConsumerWidget {
  const PartnersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partners = ref.watch(partnersStreamProvider);
    final expenses = ref.watch(partnersExpensesProvider);
    final pendingRequests = ref.watch(pendingPartnerLinkRequestsProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;

    return AppShellScaffold(
      title: 'الشركاء',
      subtitle: 'متابعة النسب والمساهمات والأرصدة',
      currentIndex: 2,
      actions: _buildActions(context, ref, pendingRequests),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => const PartnerFormSheet(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('إضافة شريك'),
      ),
      child: partners.when(
        data: (partnerItems) => expenses.when(
          data: (expenseItems) {
            final settlements = const PartnerSettlementCalculator().build(
              partners: partnerItems,
              expenses: expenseItems,
            );
            final totalCapital = partnerItems.fold<double>(
              0,
              (sum, item) => sum + item.contributionTotal,
            );
            final totalExpected = settlements.fold<double>(
              0,
              (sum, item) => sum + item.expectedContribution,
            );
            final positiveBalances = settlements
                .where((item) => item.balanceDelta >= 0)
                .fold<double>(0, (sum, item) => sum + item.balanceDelta);
            final negativeBalances = settlements
                .where((item) => item.balanceDelta < 0)
                .fold<double>(0, (sum, item) => sum + item.balanceDelta.abs());
            final averageShare = partnerItems.isEmpty
                ? 0.0
                : partnerItems.fold<double>(
                        0,
                        (sum, item) => sum + item.shareRatio,
                      ) /
                      partnerItems.length;

            return ListView(
              padding: EdgeInsets.all(screenWidth < 640 ? 12 : 16),
              children: [
                _PartnersBanner(
                  partnerCount: partnerItems.length,
                  totalCapital: totalCapital,
                  totalExpected: totalExpected,
                  averageShare: averageShare,
                  pendingRequestsCount: pendingRequests.valueOrNull?.length ?? 0,
                ),
                const SizedBox(height: 14),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: screenWidth < 520 ? 2 : 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: screenWidth < 520 ? 1.18 : 1.14,
                  children: [
                    MetricCard(
                      label: 'عدد الشركاء',
                      value: '${partnerItems.length}',
                      icon: Icons.groups_outlined,
                      color: const Color(0xFF6B6A63),
                    ),
                    MetricCard(
                      label: 'إجمالي المساهمات',
                      value: totalCapital.egp,
                      icon: Icons.account_balance_wallet_outlined,
                      color: const Color(0xFF7A725A),
                    ),
                    MetricCard(
                      label: 'أرصدة دائنة',
                      value: positiveBalances.egp,
                      icon: Icons.north_east_rounded,
                      color: const Color(0xFF4D8B5A),
                    ),
                    MetricCard(
                      label: 'أرصدة مستحقة',
                      value: negativeBalances.egp,
                      icon: Icons.south_west_rounded,
                      color: const Color(0xFFB76A6A),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const _SectionHeading(
                  title: 'تفاصيل الشركاء',
                  subtitle:
                      'متابعة سريعة للنسبة والمساهمة والإيميل وحالة الربط والرصيد الحالي.',
                ),
                const SizedBox(height: 12),
                if (partnerItems.isEmpty)
                  const EmptyStateView(
                    title: 'لا توجد سجلات للشركاء',
                    message:
                        'أضف الشركاء لتبدأ في متابعة المساهمات والتسويات والأرصدة.',
                  )
                else
                  for (final settlement in settlements) ...[
                    _PartnerCard(
                      settlement: settlement,
                      partner: partnerItems.firstWhere(
                        (partner) => partner.id == settlement.partnerId,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
              ],
            );
          },
          error: (error, _) => Center(child: Text(error.toString())),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Center(child: Text(error.toString())),
        loading: () => const Center(child: CircularProgressIndicator()),
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
            padding: const EdgeInsetsDirectional.only(end: 4, top: 8, bottom: 8),
            child: FilledButton.tonalIcon(
              onPressed: () => _showPendingRequestsSheet(context, ref, items),
              icon: const Icon(Icons.handshake_outlined, size: 18),
              label: Text(items.length == 1 ? 'قبول الشراكة' : 'طلبات الشراكة'),
            ),
          ),
        ];
      },
      error: (_, _) => null,
      loading: () => null,
    );
  }
}

class _PartnersBanner extends StatelessWidget {
  const _PartnersBanner({
    required this.partnerCount,
    required this.totalCapital,
    required this.totalExpected,
    required this.averageShare,
    required this.pendingRequestsCount,
  });

  final int partnerCount;
  final double totalCapital;
  final double totalExpected;
  final double averageShare;
  final int pendingRequestsCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDAD9D1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EFE9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.groups_rounded, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إدارة الشركاء',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'متابعة هادئة وواضحة للنسب والمساهمات والربط بالإيميل.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (pendingRequestsCount > 0)
                  _MiniPill(
                    label: pendingRequestsCount == 1
                        ? 'طلب واحد'
                        : '$pendingRequestsCount طلبات',
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _BannerPill(label: 'عدد الشركاء', value: '$partnerCount'),
                _BannerPill(label: 'إجمالي المساهمة', value: totalCapital.egp),
                _BannerPill(label: 'المتوقع تغطيته', value: totalExpected.egp),
                _BannerPill(
                  label: 'متوسط النسبة',
                  value: _formatPercentage(averageShare),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  const _PartnerCard({required this.settlement, required this.partner});

  final PartnerSettlement settlement;
  final Partner partner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = settlement.balanceDelta >= 0;
    final accent = isPositive
        ? const Color(0xFF4D8B5A)
        : const Color(0xFFB76A6A);
    final linkState = partner.userId.isNotEmpty
        ? 'مربوط'
        : partner.linkedEmail.isNotEmpty
        ? 'بانتظار القبول'
        : 'بدون ربط';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDAD9D1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFF2F1EB),
                  child: Text(
                    partner.name.isEmpty ? '?' : partner.name.characters.first,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF5A584F),
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
                        settlement.partnerName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'نسبة الشراكة ${_formatPercentage(partner.shareRatio)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _BalanceChip(
                  label: isPositive ? 'رصيد دائن' : 'رصيد مستحق',
                  value: settlement.balanceDelta.egp,
                  color: accent,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.alternate_email_rounded,
                  label: partner.linkedEmail.isEmpty
                      ? 'لا يوجد بريد ربط'
                      : partner.linkedEmail,
                ),
                _InfoChip(
                  icon: Icons.link_rounded,
                  label: linkState,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _ValueTile(
                    label: 'المتوقع',
                    value: settlement.expectedContribution.egp,
                    icon: Icons.pie_chart_outline_rounded,
                    color: const Color(0xFF8A7E5F),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ValueTile(
                    label: 'المدفوع',
                    value: settlement.contributedAmount.egp,
                    icon: Icons.payments_outlined,
                    color: const Color(0xFF6C7A8A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => PartnerFormSheet(partner: partner),
                ),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('تعديل بيانات الشريك'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerPill extends StatelessWidget {
  const _BannerPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F3EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1DFD6)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EDDA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF7B6540),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _BalanceChip extends StatelessWidget {
  const _BalanceChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueTile extends StatelessWidget {
  const _ValueTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: color.withValues(alpha: 0.14),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
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
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F4EF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6A675E)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF5B5A55),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingRequestsSheet extends StatelessWidget {
  const _PendingRequestsSheet({
    required this.requests,
    required this.onAccept,
  });

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
              'طلبات الشراكة',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'اقبل الطلب المناسب ليتم ربط الحساب تلقائيًا بالشريك.',
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
                        label: const Text('Accept'),
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

  final partnerId = request.metadata['partnerId'] as String? ?? '';
  if (partnerId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تعذر قراءة بيانات طلب الشراكة.')),
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
          title: 'تم قبول طلب الشراكة',
          body:
              '${session.profile?.name ?? 'الشريك'} وافق على ربط الشريك ${partner.name}.',
          type: NotificationType.partnerLinkAccepted,
          route: AppRoutes.partners,
          referenceKey:
              'partner-link-accepted-${partner.id}-${session.userId}',
          metadata: {
            'partnerId': partner.id,
            'acceptedByUserId': session.userId,
          },
        );
  }

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم قبول الطلب وربط ${partner.name} بالحساب.')),
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
    await ref.read(partnerRepositoryProvider).upsert(
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

String _formatPercentage(double ratio) {
  final percentage = ratio * 100;
  final decimals = percentage == percentage.roundToDouble() ? 0 : 1;
  return '${percentage.toStringAsFixed(decimals)}%';
}
