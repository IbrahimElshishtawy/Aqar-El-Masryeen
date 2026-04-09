import 'package:flutter/material.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.leading,
    this.footer,
    this.maxWidth = 480,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? leading;
  final Widget? footer;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.08),
              const Color(0xFFF3F1EC),
              theme.colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: -70,
                  right: -16,
                  child: _GlowBubble(
                    size: 210,
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  ),
                ),
                Positioned(
                  top: 120,
                  left: -48,
                  child: _GlowBubble(
                    size: 150,
                    color: theme.colorScheme.secondary.withValues(alpha: 0.06),
                  ),
                ),
                Positioned(
                  bottom: -56,
                  right: 24,
                  child: _GlowBubble(
                    size: 170,
                    color: theme.colorScheme.primary.withValues(alpha: 0.05),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxHeight < 720;
                    final horizontalPadding = isCompact ? 18.0 : 24.0;
                    final verticalPadding = isCompact ? 18.0 : 26.0;
                    final minHeight =
                        constraints.maxHeight - (verticalPadding * 2);

                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: verticalPadding,
                      ),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: minHeight),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxWidth),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface.withValues(
                                  alpha: 0.96,
                                ),
                                borderRadius: BorderRadius.circular(
                                  isCompact ? 30 : 36,
                                ),
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant
                                      .withValues(alpha: 0.55),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 28,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  isCompact ? 18 : 24,
                                  isCompact ? 18 : 24,
                                  isCompact ? 18 : 24,
                                  isCompact ? 16 : 22,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (leading != null)
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: leading!,
                                      ),
                                    SizedBox(height: isCompact ? 14 : 18),
                                    Text(
                                      title,
                                      textAlign: TextAlign.right,
                                      style:
                                          (isCompact
                                                  ? theme
                                                        .textTheme
                                                        .headlineMedium
                                                  : theme
                                                        .textTheme
                                                        .headlineLarge)
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                height: 1.05,
                                              ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      subtitle,
                                      textAlign: TextAlign.right,
                                      style:
                                          (isCompact
                                                  ? theme.textTheme.bodyMedium
                                                  : theme.textTheme.bodyLarge)
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.70),
                                                height: 1.5,
                                              ),
                                    ),
                                    SizedBox(height: isCompact ? 20 : 26),
                                    child,
                                    if (footer != null) ...[
                                      SizedBox(height: isCompact ? 16 : 20),
                                      footer!,
                                    ],
                                  ],
                                ),
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
