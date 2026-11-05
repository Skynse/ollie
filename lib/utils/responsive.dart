import 'package:flutter/material.dart';

/// Responsive breakpoints for the app
class Breakpoints {
  // Mobile: < 640px
  static const double mobile = 640;

  // Desktop: > 1024px
  static const double desktop = 1024;
}

/// Extension on BuildContext for responsive utilities
extension ResponsiveContext on BuildContext {
  /// Get screen width safely
  double get width {
    final mediaQuery = MediaQuery.maybeOf(this);
    return mediaQuery?.size.width ?? 1024; // Default to desktop width
  }

  /// Get screen height safely
  double get height {
    final mediaQuery = MediaQuery.maybeOf(this);
    return mediaQuery?.size.height ?? 768; // Default to desktop height
  }

  /// Check if mobile
  bool get isMobile => width < Breakpoints.mobile;

  /// Check if tablet
  bool get isTablet =>
      width >= Breakpoints.mobile && width < Breakpoints.desktop;

  /// Check if desktop
  bool get isDesktop => width >= Breakpoints.desktop;

  /// Check if mobile or tablet (for grouping)
  bool get isMobileOrTablet => width < Breakpoints.desktop;

  /// Responsive value - returns different values based on screen size
  T responsive<T>({required T mobile, T? tablet, T? desktop}) {
    if (isDesktop) return desktop ?? tablet ?? mobile;
    if (isTablet) return tablet ?? mobile;
    return mobile;
  }
}

/// Responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Breakpoints.desktop) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= Breakpoints.mobile) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}
