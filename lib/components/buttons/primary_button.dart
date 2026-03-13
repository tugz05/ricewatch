import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Reusable primary CTA button with optional gradient and trailing icon.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcons,
    this.useGradient = true,
    this.isExpanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final Widget? trailingIcons;
  final bool useGradient;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[icon!, const SizedBox(width: 8)],
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textOnDark,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        if (trailingIcons != null) ...[const SizedBox(width: 8), trailingIcons!],
      ],
    );

    if (useGradient) {
      return Container(
        width: isExpanded ? double.infinity : null,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primaryLight],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: child,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: isExpanded ? double.infinity : null,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: child,
      ),
    );
  }
}
