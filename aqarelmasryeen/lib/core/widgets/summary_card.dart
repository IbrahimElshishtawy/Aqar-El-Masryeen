import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.icon,
    this.emphasis = false,
    this.splitLayout = false,
  });

  final String label;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final bool emphasis;
  final bool splitLayout;

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
      padding: const EdgeInsets.all(17),
      child: splitLayout
          ? _SplitSummaryContent(
              label: label,
              value: value,
              subtitle: subtitle,
              icon: icon,
              foreground: foreground,
              emphasis: emphasis,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: foreground, size: 18),
                  const SizedBox(height: 8),
                ],
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: emphasis
                        ? Colors.white70
                        : theme.colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: emphasis
                          ? Colors.white70
                          : theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _SplitSummaryContent extends StatelessWidget {
  const _SplitSummaryContent({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.foreground,
    required this.emphasis,
  });

  final String label;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color foreground;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryColor = emphasis
        ? Colors.white70
        : theme.colorScheme.secondary;
    final dividerColor = emphasis
        ? Colors.white.withValues(alpha: 0.18)
        : const Color(0xFFD8D8D2);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 280;

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: foreground, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: secondaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: secondaryColor,
                  ),
                ),
              ],
            ],
          );
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: secondaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                color: dividerColor,
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) Icon(icon, color: foreground, size: 18),
                    if (icon != null) const SizedBox(height: 12),
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: secondaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
