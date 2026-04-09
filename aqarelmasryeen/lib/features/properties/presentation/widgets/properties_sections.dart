import 'package:aqarelmasryeen/core/errors/failure_mapper.dart';
import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/core/widgets/app_panel.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/properties/data/property_repository.dart';
import 'package:aqarelmasryeen/features/properties/domain/property_financial_summary.dart';
import 'package:aqarelmasryeen/features/settings/data/activity_repository.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProjectsOverviewSection extends StatelessWidget {
  const ProjectsOverviewSection({
    super.key,
    required this.projectCount,
    required this.totalExpenses,
    required this.totalPayments,
  });

  final int projectCount;
  final double totalExpenses;
  final double totalPayments;

  @override
  Widget build(BuildContext context) {
    final balance = totalPayments - totalExpenses;

    return AppPanel(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 720;

          final hero = OverviewHeroCard(
            projectCount: projectCount,
            balance: balance,
          );
          final metrics = [
            OverviewMetricCard(
              label: 'المصروفات',
              value: totalExpenses.egp,
              subtitle: 'إجمالي مصروفات المشروعات',
              icon: Icons.north_east_rounded,
            ),
            OverviewMetricCard(
              label: 'التحصيلات',
              value: totalPayments.egp,
              subtitle: 'إجمالي تحصيلات المشروعات',
              icon: Icons.south_west_rounded,
            ),
          ];

          if (isCompact) {
            return Column(
              children: [
                hero,
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: metrics[0]),
                    const SizedBox(width: 12),
                    Expanded(child: metrics[1]),
                  ],
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 8, child: hero),
              const SizedBox(width: 12),
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    Expanded(child: metrics[0]),
                    const SizedBox(height: 12),
                    Expanded(child: metrics[1]),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class OverviewHeroCard extends StatelessWidget {
  const OverviewHeroCard({
    super.key,
    required this.projectCount,
    required this.balance,
  });

  final int projectCount;
  final double balance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final balanceColor = balance >= 0
        ? const Color(0xFF175546)
        : const Color(0xFF9E3D2D);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFFFFEFB), Color(0xFFF4F1E8)],
        ),
        border: Border.all(color: const Color(0xFFD8D8D2)),
      ),
      padding: const EdgeInsets.all(18),
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
                      'المشروعات',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'نظرة سريعة على المحفظة الحالية',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD8D8D2)),
                ),
                child: const Icon(Icons.apartment_rounded, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '$projectCount',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            projectCount == 1
                ? 'مشروع نشط داخل المحفظة'
                : 'مشروعات نشطة داخل المحفظة',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.84),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD8D8D2)),
            ),
            child: Row(
              children: [
                Icon(Icons.wallet_outlined, size: 18, color: balanceColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'صافي الحركة',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
                Text(
                  balance.egp,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: balanceColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OverviewMetricCard extends StatelessWidget {
  const OverviewMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD8D8D2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD8D8D2)),
                ),
                child: Icon(icon, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class PropertySummaryCard extends ConsumerWidget {
  const PropertySummaryCard({super.key, required this.summary});

  final PropertyFinancialSummary summary;

  Future<void> _archiveProperty(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('أرشفة العقار'),
        content: Text(
          'سيتم إخفاء "${summary.property.name}" من قائمة المشروعات ولن يظهر ضمن المشروعات النشطة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('أرشفة'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      return;
    }

    try {
      await ref
          .read(propertyRepositoryProvider)
          .archive(summary.property.id, actorId: session.userId);
      await ref
          .read(activityRepositoryProvider)
          .log(
            actorId: session.userId,
            actorName: session.profile?.name ?? 'شريك',
            action: 'property_archived',
            entityType: 'property',
            entityId: summary.property.id,
            metadata: {
              'name': summary.property.name,
              'location': summary.property.location,
            },
          );

      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تمت أرشفة ${summary.property.name}.')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mapException(error).message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => context.push(AppRoutes.propertyDetails(summary.property.id)),
      child: AppPanel(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final theme = Theme.of(context);
            final isCompact = constraints.maxWidth < 400;

            return Column(
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
                            summary.property.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            summary.property.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const OpenProjectBadge(),
                            const SizedBox(width: 8),
                            _PropertyCardMenu(
                              onArchive: () => _archiveProperty(context, ref),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        StatusChip(label: summary.property.status.label),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: MiniStat(
                        label: 'إجمالي المصاريف',
                        value: summary.totalExpenses.egp,
                        compact: isCompact,
                        icon: Icons.north_east_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: MiniStat(
                        label: 'إجمالي المبيعات',
                        value: summary.totalSales.egp,
                        compact: isCompact,
                        icon: Icons.trending_up_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                MiniStat(
                  label: 'عدد الشقق',
                  value: '${summary.apartmentCount}',
                  compact: isCompact,
                  icon: Icons.apartment_rounded,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'الرصيد ${summary.balance.egp}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: isCompact ? 15 : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PropertyCardMenu extends StatelessWidget {
  const _PropertyCardMenu({required this.onArchive});

  final Future<void> Function() onArchive;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_PropertyCardAction>(
      tooltip: 'إجراءات العقار',
      onSelected: (value) async {
        if (value == _PropertyCardAction.archive) {
          await onArchive();
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem<_PropertyCardAction>(
          value: _PropertyCardAction.archive,
          child: Text('أرشفة العقار'),
        ),
      ],
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD8D8D2)),
        ),
        child: const Icon(Icons.more_horiz_rounded, size: 18),
      ),
    );
  }
}

enum _PropertyCardAction { archive }

class OpenProjectBadge extends StatelessWidget {
  const OpenProjectBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD8D8D2)),
      ),
      child: const Icon(Icons.arrow_outward_rounded, size: 18),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0EA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class MiniStat extends StatelessWidget {
  const MiniStat({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.compact = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8D8D2)),
      ),
      padding: EdgeInsets.all(compact ? 12 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.secondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 6 : 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: compact ? 14 : null,
            ),
          ),
        ],
      ),
    );
  }
}
