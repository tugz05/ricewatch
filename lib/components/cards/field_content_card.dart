import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'app_card.dart';

/// Content card for "My Fields" list: image, title, description, optional bookmark.
class FieldContentCard extends StatelessWidget {
  const FieldContentCard({
    super.key,
    required this.title,
    required this.description,
    this.imageUrl,
    this.imageWidget,
    this.isBookmarked = false,
    this.onTap,
    this.onBookmarkTap,
  });

  final String title;
  final String description;
  final String? imageUrl;
  final Widget? imageWidget;
  final bool isBookmarked;
  final VoidCallback? onTap;
  final VoidCallback? onBookmarkTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: SizedBox(
              height: 120,
              width: double.infinity,
              child: imageWidget ??
                  (imageUrl != null
                      ? Image.network(imageUrl!, fit: BoxFit.cover)
                      : _placeholderImage()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onBookmarkTap != null)
                      GestureDetector(
                        onTap: onBookmarkTap,
                        child: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          size: 22,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: AppColors.surfaceLight,
      child: const Center(
        child: Icon(Icons.agriculture, size: 48, color: AppColors.primary),
      ),
    );
  }
}
