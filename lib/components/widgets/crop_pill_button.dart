import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Pill-shaped crop selector (e.g. Carrot with icon).
class CropPillButton extends StatelessWidget {
  const CropPillButton({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    required this.onTap,
  });

  final String label;
  final Widget? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
              width: selected ? 2 : 1,
            ),
            color: AppColors.surfaceLight,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: 8)],
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
