import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/widgets/app_panel.dart';
import 'package:aqarelmasryeen/features/dashboard/domain/dashboard_snapshot.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DashboardFinanceChart extends StatelessWidget {
  const DashboardFinanceChart({super.key, required this.buckets});

  final List<DashboardChartBucket> buckets;

  @override
  Widget build(BuildContext context) {
    const financeTitle =
        '\u0627\u0644\u062d\u0631\u0643\u0629 \u0627\u0644\u0645\u0627\u0644\u064a\u0629';
    const financeSubtitle =
        '\u0645\u0642\u0627\u0631\u0646\u0629 \u0628\u064a\u0646 \u0627\u0644\u0645\u0635\u0631\u0648\u0641\u0627\u062a \u0648\u0627\u0644\u062a\u062d\u0635\u064a\u0644\u0627\u062a \u062e\u0644\u0627\u0644 \u0622\u062e\u0631 \u0633\u062a\u0629 \u0623\u0634\u0647\u0631';
    const paymentsLabel =
        '\u0627\u0644\u062a\u062d\u0635\u064a\u0644\u0627\u062a';
    const expensesLabel =
        '\u0627\u0644\u0645\u0635\u0631\u0648\u0641\u0627\u062a';

    final theme = Theme.of(context);
    final maxValue = buckets.fold<double>(0, (current, bucket) {
      final bucketMax = bucket.expenses > bucket.payments
          ? bucket.expenses
          : bucket.payments;
      return current > bucketMax ? current : bucketMax;
    });
    final totalExpenses = buckets.fold<double>(
      0,
      (sum, bucket) => sum + bucket.expenses,
    );
    final totalPayments = buckets.fold<double>(
      0,
      (sum, bucket) => sum + bucket.payments,
    );
    final topValue = maxValue == 0 ? 1.0 : maxValue * 1.2;

    const expensesColor = Color(0xFFBBB6A9);
    const paymentsColor = Color(0xFF111111);

    return AppPanel(
      title: financeTitle,
      subtitle: financeSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _FinanceSummaryChip(
                label: paymentsLabel,
                value: totalPayments.egp,
                color: paymentsColor,
              ),
              _FinanceSummaryChip(
                label: expensesLabel,
                value: totalExpenses.egp,
                color: expensesColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFFEFB), Color(0xFFF6F4EC)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD8D8D2)),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: (buckets.length - 1).toDouble(),
                      minY: 0,
                      maxY: topValue,
                      lineTouchData: LineTouchData(
                        handleBuiltInTouches: true,
                        touchTooltipData: LineTouchTooltipData(
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          tooltipRoundedRadius: 14,
                          tooltipPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          tooltipBorder: BorderSide(
                            color: Colors.black.withValues(alpha: 0.06),
                          ),
                          getTooltipColor: (_) => Colors.white,
                          getTooltipItems: (spots) {
                            return spots.map((spot) {
                              final isPayments = spot.barIndex == 1;
                              return LineTooltipItem(
                                '${buckets[spot.x.toInt()].label}\n${spot.y.egp}',
                                theme.textTheme.labelMedium!.copyWith(
                                  color: isPayments
                                      ? paymentsColor
                                      : expensesColor,
                                  fontWeight: FontWeight.w700,
                                  height: 1.35,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        horizontalInterval: topValue / 4,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: const Color(0xFFD9D7CF).withValues(alpha: 0.8),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            interval: topValue / 4,
                            getTitlesWidget: (value, meta) {
                              if (value <= 0) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  end: 8,
                                ),
                                child: Text(
                                  _compactCurrency(value),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= buckets.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  buckets[index].label,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        _buildSeries(
                          buckets: buckets,
                          selector: (bucket) => bucket.expenses,
                          color: expensesColor,
                        ),
                        _buildSeries(
                          buckets: buckets,
                          selector: (bucket) => bucket.payments,
                          color: paymentsColor,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    _ChartLegend(color: paymentsColor, label: paymentsLabel),
                    SizedBox(width: 12),
                    _ChartLegend(color: expensesColor, label: expensesLabel),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

LineChartBarData _buildSeries({
  required List<DashboardChartBucket> buckets,
  required double Function(DashboardChartBucket bucket) selector,
  required Color color,
}) {
  return LineChartBarData(
    isCurved: true,
    curveSmoothness: 0.28,
    color: color,
    barWidth: 3,
    isStrokeCapRound: true,
    belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.08)),
    dotData: FlDotData(
      show: true,
      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
        radius: 3.8,
        color: color,
        strokeWidth: 2,
        strokeColor: Colors.white,
      ),
    ),
    spots: [
      for (var index = 0; index < buckets.length; index++)
        FlSpot(index.toDouble(), selector(buckets[index])),
    ],
  );
}

String _compactCurrency(double value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(value >= 10000000 ? 0 : 1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(value >= 100000 ? 0 : 1)}K';
  }
  return value.toStringAsFixed(0);
}

class _FinanceSummaryChip extends StatelessWidget {
  const _FinanceSummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8D8D2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD8D8D2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
