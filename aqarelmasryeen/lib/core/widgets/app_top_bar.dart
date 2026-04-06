import 'package:flutter/material.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.titleActions,
    this.automaticallyImplyLeading = true,
    this.bottom,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final List<Widget>? titleActions;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize {
    final baseHeight = subtitle == null ? 84.0 : 104.0;
    return Size.fromHeight(baseHeight + (bottom?.preferredSize.height ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = Navigator.of(context).canPop();

    return AppBar(
      automaticallyImplyLeading: automaticallyImplyLeading,
      toolbarHeight: subtitle == null ? 76 : 94,
      titleSpacing: canPop ? 8 : 20,
      actionsPadding: const EdgeInsetsDirectional.only(end: 12),
      backgroundColor: Colors.transparent,
      foregroundColor: theme.colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFFFFFFFF), Color(0xFFF7F5EE), Color(0xFFEFEBE0)],
          ),
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
      ),
      title: Padding(
        padding: EdgeInsetsDirectional.only(
          top: subtitle == null ? 12 : 14,
          bottom: 6,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (titleActions != null && titleActions!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Wrap(spacing: 4, children: titleActions!),
              ),
            ],
          ],
        ),
      ),
      actions: actions,
      bottom: bottom,
    );
  }
}
