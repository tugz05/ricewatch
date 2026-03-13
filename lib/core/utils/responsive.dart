import 'package:flutter/material.dart';

/// Breakpoints and helpers for responsive layout (phone vs tablet).
class Responsive {
  Responsive._();

  /// Typically tablet or landscape: use grid, larger padding, max content width.
  static const double breakpointTablet = 600;
  static const double breakpointDesktop = 900;

  /// Max width for main content on large screens (keeps layout readable).
  static const double maxContentWidth = 600;

  static bool isPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width < breakpointTablet;
  static bool isTabletOrLarger(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= breakpointTablet;
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= breakpointDesktop;

  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;
  static double height(BuildContext context) => MediaQuery.sizeOf(context).height;

  /// Horizontal padding that scales with screen (larger on tablet).
  static double horizontalPadding(BuildContext context) {
    final w = width(context);
    if (w >= breakpointDesktop) return 32;
    if (w >= breakpointTablet) return 24;
    return 16;
  }

  /// Scale factor for fonts (slightly larger on tablet).
  static double fontScale(BuildContext context) {
    final w = width(context);
    if (w >= breakpointDesktop) return 1.15;
    if (w >= breakpointTablet) return 1.05;
    return 1.0;
  }

  /// Constrains child to [maxContentWidth] when on large screens; centers it.
  static Widget constrainMaxWidth(BuildContext context, {required Widget child}) {
    final w = width(context);
    if (w <= maxContentWidth) return child;
    return Center(
      child: SizedBox(
        width: maxContentWidth,
        child: child,
      ),
    );
  }
}
