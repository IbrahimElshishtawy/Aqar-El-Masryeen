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
    final maxValue = buckets.fold<double>(0, (current, bucket) {
      final bucketMax = bucket.expenses > bucket.payments
          ? bucket.expenses
          : bucket.payments;
      return current > bucketMax ? current : bucketMax;
    });
    final topValue = maxValue == 0 ? 1.0 : maxValue * 1.2;

    return AppPanel(
      title: 'Financial movement',
      subtitle: 'Expenses versus payments over the last six months',
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: topValue,
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      const FlLine(color: Color(0xFFE5E5DE), strokeWidth: 1),
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
                      reservedSize: 48,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          value.egp,
                          style: Theme.of(context).textTheme.labelSmall,
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= buckets.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            buckets[index].label,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var index = 0; index < buckets.length; index++)
                    BarChartGroupData(
                      x: index,
                      barsSpace: 6,
                      barRods: [
                        BarChartRodData(
                          toY: buckets[index].expenses,
                          width: 10,
                          color: const Color(0xFFB3B3AB),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        BarChartRodData(
                          toY: buckets[index].payments,
                          width: 10,
                          color: const Color(0xFF111111),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              _ChartLegend(color: Color(0xFF111111), label: 'Payments'),
              SizedBox(width: 16),
              _ChartLegend(color: Color(0xFFB3B3AB), label: 'Expenses'),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}
