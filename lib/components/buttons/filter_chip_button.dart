import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Reusable filter/chip button for categories (All, Carrots, Vegetable, etc.).
class FilterChipButton extends StatelessWidget {
  const FilterChipButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryLight : AppColors.cardBackground,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primaryLight : AppColors.divider,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.textOnDark : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
