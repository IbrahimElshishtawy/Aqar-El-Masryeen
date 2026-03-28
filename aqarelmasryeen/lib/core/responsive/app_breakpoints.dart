import 'package:flutter/widgets.dart';

abstract final class AppBreakpoints {
  static const compact = 640.0;
  static const medium = 960.0;
  static const expanded = 1280.0;
}

enum AppViewport { mobile, tablet, desktop }

extension ResponsiveContext on BuildContext {
  AppViewport get viewport {
    final width = MediaQuery.sizeOf(this).width;
    if (width >= AppBreakpoints.expanded) {
      return AppViewport.desktop;
    }
    if (width >= AppBreakpoints.compact) {
      return AppViewport.tablet;
    }
    return AppViewport.mobile;
  }

  bool get isDesktop => viewport == AppViewport.desktop;
  bool get isTablet => viewport == AppViewport.tablet;
  bool get isMobile => viewport == AppViewport.mobile;
}
