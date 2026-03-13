import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Shimmering loading effect — wraps any child with an animated gradient sweep.
class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
    _animation = Tween<double>(begin: 0.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.baseColor ?? AppColors.primaryLight.withValues(alpha: 0.6);
    final highlight = widget.highlightColor ?? Colors.white.withValues(alpha: 0.95);
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(_animation.value - 1.0, 0),
              end: Alignment(_animation.value, 0),
              colors: [base, highlight, base],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Shimmer placeholder box — use for card/skeleton placeholders.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.7),
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// Full-screen shimmer loading — replaces CircularProgressIndicator + text.
class ShimmerLoadingScreen extends StatelessWidget {
  const ShimmerLoadingScreen({
    super.key,
    this.message = 'Loading...',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShimmerLoading(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ShimmerLoading(
            child: Container(
              width: 120,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
