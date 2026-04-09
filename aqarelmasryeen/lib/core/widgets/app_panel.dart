import 'package:flutter/material.dart';

class AppPanel extends StatelessWidget {
  const AppPanel({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD8D8D2)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final hasHeader =
              title != null || subtitle != null || trailing != null;
          final useStackedHeader =
              trailing != null && constraints.maxWidth < 560;

          Widget buildHeaderText() {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ],
            );
          }

          return Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasHeader) ...[
                  if (useStackedHeader) ...[
                    buildHeaderText(),
                    if (trailing != null) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: trailing!,
                      ),
                    ],
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: buildHeaderText()),
                        if (trailing != null) ...[
                          const SizedBox(width: 12),
                          trailing!,
                        ],
                      ],
                    ),
                  const SizedBox(height: 16),
                ],
                child,
              ],
            ),
          );
        },
      ),
    );
  }
}
