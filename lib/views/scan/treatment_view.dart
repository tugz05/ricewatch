import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../services/treatment_recommendation_service.dart';

/// Page showing AI-generated treatment recommendations for a rice disease.
class TreatmentView extends StatefulWidget {
  const TreatmentView({
    super.key,
    required this.diseaseName,
  });

  final String diseaseName;

  @override
  State<TreatmentView> createState() => _TreatmentViewState();
}

class _TreatmentViewState extends State<TreatmentView>
    with SingleTickerProviderStateMixin {
  TreatmentRecommendation? _recommendation;
  bool _loading = true;
  String? _error;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _load();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rec = await TreatmentRecommendationService.getRecommendations(
        widget.diseaseName,
      );
      if (!mounted) return;
      setState(() {
        _recommendation = rec;
        _loading = false;
        _pulseCtrl.stop();
        if (rec == null) {
          _error = 'Dili ma-fetch ang rekomendasyon. Susihi ang internet.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _pulseCtrl.stop();
        _error = 'Naay error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final padding = Responsive.horizontalPadding(context);
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.header,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Rekomendasyon sa Pagtambal',
          style: TextStyle(
            color: c.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _loading
            ? _buildLoading(c, padding)
            : _error != null
                ? _buildError(c, padding)
                : _buildContent(c, padding),
      ),
    );
  }

  Widget _buildLoading(AppColorSet c, double padding) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          _buildHeader(c),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, child) => Opacity(
              opacity: 0.5 + 0.5 * _pulseCtrl.value,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: c.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: c.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gi-generate ang rekomendasyon...',
                            style: TextStyle(
                              color: c.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Palihug paghulat. AI ang mohatag og treatment tips.',
                            style: TextStyle(color: c.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              backgroundColor: c.surfaceVariant,
              color: c.primary,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(AppColorSet c, double padding) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          _buildHeader(c),
          const SizedBox(height: 32),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: c.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: c.error.withValues(alpha: 0.4)),
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: c.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: c.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Sulayi usab'),
                    style: FilledButton.styleFrom(
                      backgroundColor: c.primary,
                      foregroundColor: c.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppColorSet c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: c.accent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'AI-Powered · Cebuano',
            style: TextStyle(
              color: c.accent,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Treatment Recommendations',
          style: TextStyle(
            color: c.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Organiko ug kemikal nga pagtambal para sa ${widget.diseaseName}',
          style: TextStyle(color: c.textSecondary, fontSize: 13),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildContent(AppColorSet c, double padding) {
    final rec = _recommendation!;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(padding, 16, padding, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Responsive.constrainMaxWidth(
        context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(c),
            const SizedBox(height: 20),
            // Disease card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.primary.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: c.accentLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.medical_services_rounded,
                        color: c.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rec.diseaseName,
                          style: TextStyle(
                            color: c.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Organiko · Kemikal · Produkto',
                          style: TextStyle(
                            color: c.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Section title
            Row(
              children: [
                Icon(Icons.description_rounded, color: c.textMuted, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Detalyadong Rekomendasyon',
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Content card (matches scan detail analysis card)
            Container(
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.divider),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: MarkdownBody(
                  data: rec.rawMarkdown ?? '',
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      color: c.textSecondary,
                      fontSize: 14,
                      height: 1.6,
                    ),
                    strong: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    listBullet: TextStyle(color: c.accent),
                    h3: TextStyle(
                      color: c.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    h4: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Tip banner (matches scan view)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.divider),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded,
                      color: c.warning, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Konsulta sa inyong local agriculturist o DA office para sa mas tukma nga dosis ug produkto.',
                      style: TextStyle(color: c.textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
