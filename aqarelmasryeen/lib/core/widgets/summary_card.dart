import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.icon,
    this.emphasis = false,
  });

  final String label;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = emphasis
        ? theme.colorScheme.primary
        : theme.colorScheme.surface;
    final foreground = emphasis ? Colors.white : theme.colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: emphasis ? theme.colorScheme.primary : const Color(0xFFD8D8D2),
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: foreground, size: 18),
            const SizedBox(height: 18),
          ],
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: emphasis ? Colors.white70 : theme.colorScheme.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: emphasis ? Colors.white70 : theme.colorScheme.secondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
