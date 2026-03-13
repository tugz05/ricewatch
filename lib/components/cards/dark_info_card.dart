import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Dark green info card for weather, stats, sensor data (white text).
class DarkInfoCard extends StatelessWidget {
  const DarkInfoCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.header,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DefaultTextStyle(
        style: TextStyle(color: c.textOnDark),
        child: child,
      ),
    );
  }
}
