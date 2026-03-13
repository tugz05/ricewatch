import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Reusable rounded card with optional padding and shadow.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderRadius,
    this.elevation = 2,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final BorderRadius? borderRadius;
  final double elevation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(16);
    final content = Padding(
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: color ?? AppColors.cardBackground,
        borderRadius: radius,
        elevation: elevation,
        shadowColor: Colors.black26,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: content,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: color ?? AppColors.cardBackground,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: elevation * 4,
            offset: Offset(0, elevation * 2),
          ),
        ],
      ),
      child: content,
    );
  }
}
