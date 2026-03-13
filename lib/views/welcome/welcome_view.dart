import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/asset_paths.dart';
import '../../core/utils/responsive.dart';
import '../../controllers/navigation_controller.dart';

/// Welcome/onboarding screen: animated rice-field background, title, CTA.
class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeInOut),
    );
    _offsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.02, -0.02),
    ).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeInOut),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _bgController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackground(context),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            const Spacer(flex: 2),
                            _buildContent(context),
                            const SizedBox(height: 32),
                            _buildButton(context),
                            SizedBox(height: 24 + MediaQuery.paddingOf(context).bottom),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(BuildContext context) {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          alignment: Alignment.center,
          child: Transform.translate(
            offset: Offset(
              _offsetAnimation.value.dx * MediaQuery.sizeOf(context).width,
              _offsetAnimation.value.dy * MediaQuery.sizeOf(context).height,
            ),
            child: child,
          ),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AssetPaths.welcomeBackground,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallbackBackground(),
          ),
          SizedBox.expand(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.55),
                    AppColors.backgroundDark.withValues(alpha: 0.9),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryLight.withValues(alpha: 0.4),
            AppColors.primary.withValues(alpha: 0.6),
            AppColors.backgroundDark,
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final padding = Responsive.horizontalPadding(context);
    final scale = Responsive.fontScale(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding + 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            AssetPaths.logo,
            height: 72 * scale,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
          SizedBox(height: 16 + (8 * scale).roundToDouble()),
          Text(
            'YOUR FARM, SMARTER.',
            style: TextStyle(
              color: Colors.white,
              fontSize: (24 * scale).clamp(20.0, 32.0),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Text(
            'Monitor crop health, optimize resources, and increase yield with data driven insights.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: (14 * scale).clamp(12.0, 16.0),
              height: 1.4,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    final nav = context.read<NavigationController>();
    final padding = Responsive.horizontalPadding(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding + 8),
      child: _GetStartedButton(
        onPressed: () => nav.completeOnboarding(),
      ),
    );
  }
}

/// Modern pill-shaped CTA with gradient, scale animation, and clean icon.
class _GetStartedButton extends StatefulWidget {
  const _GetStartedButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_GetStartedButton> createState() => _GetStartedButtonState();
}

class _GetStartedButtonState extends State<_GetStartedButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accent,
                AppColors.accent.withValues(alpha: 0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Get Started',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
