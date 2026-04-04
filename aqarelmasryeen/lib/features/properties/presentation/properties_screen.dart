import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/core/widgets/app_shell_scaffold.dart';
import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:aqarelmasryeen/core/widgets/metric_card.dart';
import 'package:aqarelmasryeen/features/properties/data/property_repository.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/property_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final propertiesStreamProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(propertyRepositoryProvider).watchProperties(),
);

class PropertiesScreen extends ConsumerWidget {
  const PropertiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final properties = ref.watch(propertiesStreamProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 640;

    return AppShellScaffold(
      title: 'العقارات',
      currentIndex: 1,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('${AppRoutes.properties}/new'),
        icon: const Icon(Icons.add),
        label: const Text('إضافة عقار'),
      ),
      child: properties.when(
        data: (items) {
          final activeCount = items
              .where((item) => item.status == PropertyStatus.active)
              .length;
          final planningCount = items
              .where((item) => item.status == PropertyStatus.planning)
              .length;
          final deliveredCount = items
              .where((item) => item.status == PropertyStatus.delivered)
              .length;
          final archivedCount = items
              .where(
                (item) =>
                    item.status == PropertyStatus.archived || item.archived,
              )
              .length;
          final totalBudget = items.fold<double>(
            0,
            (sum, item) => sum + item.totalBudget,
          );
          final totalTarget = items.fold<double>(
            0,
            (sum, item) => sum + item.totalSalesTarget,
          );

          return ListView(
            padding: EdgeInsets.all(isCompact ? 12 : 16),
            children: [
              _PropertiesBanner(
                propertyCount: items.length,
                activeCount: activeCount,
                totalBudget: totalBudget,
                totalTarget: totalTarget,
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: screenWidth < 520 ? 2 : 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: screenWidth < 520 ? 1.22 : 1.18,
                children: [
                  MetricCard(
                    label: 'نشطة',
                    value: '$activeCount',
                    icon: Icons.rocket_launch_outlined,
                  ),
                  MetricCard(
                    label: 'تحت التخطيط',
                    value: '$planningCount',
                    icon: Icons.timeline_outlined,
                    color: Colors.indigo,
                  ),
                  MetricCard(
                    label: 'تم التسليم',
                    value: '$deliveredCount',
                    icon: Icons.task_alt_outlined,
                    color: Colors.teal,
                  ),
                  MetricCard(
                    label: 'مؤرشفة',
                    value: '$archivedCount',
                    icon: Icons.archive_outlined,
                    color: Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const _SectionHeading(
                title: 'سجل العقارات',
                subtitle: 'كل مشروع ظاهر بحالته وموازنته والمستهدف البيعي.',
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const EmptyStateView(
                  title: 'لا توجد عقارات بعد',
                  message:
                      'أضف أول مشروع عقاري لتبدأ في متابعة المبيعات والمصروفات والشركاء بشكل واضح.',
                )
              else
                for (final item in items) ...[
                  _PropertyCard(property: item),
                  const SizedBox(height: 12),
                ],
            ],
          );
        },
        error: (error, _) => Center(child: Text(error.toString())),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _PropertiesBanner extends StatelessWidget {
  const _PropertiesBanner({
    required this.propertyCount,
    required this.activeCount,
    required this.totalBudget,
    required this.totalTarget,
  });

  final int propertyCount;
  final int activeCount;
  final double totalBudget;
  final double totalTarget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.20),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'محفظة العقارات',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'تابع حالة المشروعات والموازنة والمستهدف البيعي من شاشة واحدة.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                  child: const Icon(
                    Icons.apartment_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _BannerPill(label: 'إجمالي العقارات', value: '$propertyCount'),
                _BannerPill(label: 'عقارات نشطة', value: '$activeCount'),
                _BannerPill(label: 'إجمالي الموازنة', value: totalBudget.egp),
                _BannerPill(label: 'المستهدف البيعي', value: totalTarget.egp),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.property});

  final PropertyProject property;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(property.status);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.30),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              property.location,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _StatusChip(
                  label: property.status.label,
                  color: statusColor,
                ),
              ],
            ),
            if (property.description.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                property.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ValueTile(
                    label: 'الموازنة',
                    value: property.totalBudget.egp,
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ValueTile(
                    label: 'المستهدف البيعي',
                    value: property.totalSalesTarget.egp,
                    icon: Icons.trending_up_outlined,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                onPressed: () =>
                    context.push('${AppRoutes.properties}/${property.id}'),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('فتح تفاصيل المشروع'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(PropertyStatus status) {
    switch (status) {
      case PropertyStatus.planning:
        return Colors.indigo;
      case PropertyStatus.active:
        return Colors.green;
      case PropertyStatus.delivered:
        return Colors.teal;
      case PropertyStatus.archived:
        return Colors.orange;
    }
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
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
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
    this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.primary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: accent.withValues(alpha: 0.16),
              child: Icon(icon, color: accent, size: 18),
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
