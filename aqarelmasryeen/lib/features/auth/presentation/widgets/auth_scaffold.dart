import 'package:flutter/material.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.leading,
    this.footer,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? leading;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.12),
              theme.scaffoldBackgroundColor,
              theme.colorScheme.secondary.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: -80,
                  right: -30,
                  child: _GlowBubble(
                    size: 180,
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  ),
                ),
                Positioned(
                  bottom: -40,
                  left: -20,
                  child: _GlowBubble(
                    size: 140,
                    color: theme.colorScheme.secondary.withValues(alpha: 0.08),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final height = constraints.maxHeight;
                    final isCompact = height < 720;
                    final isVeryCompact = height < 640;
                    final horizontalPadding = isVeryCompact ? 16.0 : 20.0;
                    final verticalPadding = isVeryCompact ? 16.0 : 20.0;
                    final bottomPadding = isVeryCompact ? 20.0 : 28.0;
                    final cardPadding = isVeryCompact ? 18.0 : 24.0;
                    final leadingSpacing = isVeryCompact ? 12.0 : 18.0;
                    final subtitleSpacing = isVeryCompact ? 8.0 : 10.0;
                    final sectionSpacing = isCompact ? 18.0 : 24.0;
                    final footerSpacing = isCompact ? 14.0 : 20.0;
                    final titleStyle =
                        (isCompact
                                ? theme.textTheme.headlineSmall
                                : theme.textTheme.headlineMedium)
                            ?.copyWith(fontWeight: FontWeight.w800);
                    final subtitleStyle =
                        (isCompact
                                ? theme.textTheme.bodyMedium
                                : theme.textTheme.bodyLarge)
                            ?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.78,
                              ),
                              height: 1.4,
                            );

                    return SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        verticalPadding,
                        horizontalPadding,
                        bottomPadding,
                      ),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: Card(
                            child: Padding(
                              padding: EdgeInsets.all(cardPadding),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (leading != null) ...[
                                    leading!,
                                    SizedBox(height: leadingSpacing),
                                  ],
                                  Text(title, style: titleStyle),
                                  SizedBox(height: subtitleSpacing),
                                  Text(subtitle, style: subtitleStyle),
                                  SizedBox(height: sectionSpacing),
                                  child,
                                  if (footer != null) ...[
                                    SizedBox(height: footerSpacing),
                                    footer!,
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowBubble extends StatelessWidget {
  const _GlowBubble({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
