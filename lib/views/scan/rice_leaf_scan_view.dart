import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../core/theme/app_colors.dart';
import '../../models/scan_record_model.dart';
import '../../services/rice_leaf_analyzer_service.dart';
import '../../services/scan_database_service.dart';
import 'scan_history_view.dart';

class RiceLeafScanView extends StatefulWidget {
  const RiceLeafScanView({super.key, this.autoLaunchCamera = false});
  final bool autoLaunchCamera;

  @override
  State<RiceLeafScanView> createState() => _RiceLeafScanViewState();
}

class _RiceLeafScanViewState extends State<RiceLeafScanView>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  Uint8List? _imageBytes;
  bool _loading = false;
  String? _rawAnalysis;
  List<DiseaseEntry> _diseases = [];
  String? _error;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    if (widget.autoLaunchCamera) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pickImage(ImageSource.camera);
      });
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _error = null;
      _rawAnalysis = null;
      _diseases = [];
    });
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _image = picked;
        _imageBytes = bytes;
      });
      if (!kIsWeb) {
        await _runAnalysis();
      } else {
        setState(() {
          _error =
              'Image analysis is not supported on the web build. Please use the mobile app.';
        });
      }
    } catch (e) {
      setState(() => _error = 'Dili makakuha og litrato: $e');
    }
  }

  Future<void> _runAnalysis() async {
    if (_image == null || kIsWeb) return;
    setState(() {
      _loading = true;
      _rawAnalysis = null;
      _diseases = [];
      _error = null;
    });
    _pulseCtrl.repeat(reverse: true);
    try {
      final file = File(_image!.path);
      final result = await RiceLeafAnalyzerService.analyze(file);
      if (!mounted) return;
      if (result.isSuccess) {
        final diseases = ScanRecord.parseDiseases(result.summary!);
        setState(() {
          _rawAnalysis = result.summary;
          _diseases = diseases;
        });
        await _saveToHistory(file, result.summary!, diseases);
      } else {
        setState(() => _error = result.error ?? 'Walay klarong tubag.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Naay isyu sa pag-analyze: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _pulseCtrl.stop();
      }
    }
  }

  Future<void> _saveToHistory(
      File src, String rawAnalysis, List<DiseaseEntry> diseases) async {
    try {
      // Copy image to app documents so path persists after cache clear.
      final dir = await getApplicationDocumentsDirectory();
      final dest = p.join(dir.path, 'scans',
          '${DateTime.now().millisecondsSinceEpoch}.jpg');
      await Directory(p.dirname(dest)).create(recursive: true);
      final saved = await src.copy(dest);
      final record = ScanRecord(
        imagePath: saved.path,
        rawAnalysis: rawAnalysis,
        diseases: diseases,
        createdAt: DateTime.now(),
      );
      await ScanDatabaseService.insert(record);
    } catch (e) {
      debugPrint('[ScanHistory] Save failed: $e');
    }
  }

  void _reset() => setState(() {
        _image = null;
        _imageBytes = null;
        _rawAnalysis = null;
        _diseases = [];
        _error = null;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: _buildAppBar(context),
      body: _image == null ? _buildIdleBody() : _buildResultBody(),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final c = context.colors;
    return AppBar(
      backgroundColor: c.header,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.textPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Scan & Analyze',
        style: TextStyle(
            color: c.textPrimary, fontWeight: FontWeight.w700, fontSize: 18),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.history_rounded, color: c.textSecondary),
          tooltip: 'Scan History',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ScanHistoryView()),
          ),
        ),
      ],
    );
  }

  // ── Idle state: no image yet ─────────────────────────────────────────────

  Widget _buildIdleBody() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildScanCard(),
            const SizedBox(height: 20),
            _buildCameraButton(),
            const SizedBox(height: 12),
            _buildGalleryButton(),
            const Spacer(),
            _buildTipBanner(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final c = context.colors;
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
            'AI-Powered · OpenAI Vision',
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
          'Rice Leaf\nDisease Analyzer',
          style: TextStyle(
            color: c.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Kuha og litrato sa rice leaf aron mahibaloan ang posible nga sakit ug rekomendasyon.',
          style: TextStyle(color: c.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildScanCard() {
    final c = context.colors;
    return GestureDetector(
      onTap: () => _pickImage(ImageSource.camera),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: c.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.accent.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.document_scanner_rounded, size: 36, color: c.primary),
            ),
            const SizedBox(height: 14),
            Text(
              'Tap para mag-scan sa rice leaf',
              style: TextStyle(color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'I-point ang camera sa leaf',
              style: TextStyle(color: c.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraButton() {
    final c = context.colors;
    return ElevatedButton.icon(
      onPressed: () => _pickImage(ImageSource.camera),
      style: ElevatedButton.styleFrom(
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      icon: const Icon(Icons.camera_alt_rounded),
      label: const Text('Buksan ang Camera',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildGalleryButton() {
    final c = context.colors;
    return OutlinedButton.icon(
      onPressed: () => _pickImage(ImageSource.gallery),
      style: OutlinedButton.styleFrom(
        foregroundColor: c.textSecondary,
        side: BorderSide(color: c.divider),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: const Icon(Icons.photo_library_rounded, size: 18),
      label: const Text('O pilion gikan sa Gallery', style: TextStyle(fontSize: 14)),
    );
  }

  Widget _buildTipBanner() {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.divider),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: c.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tip: Kuha og klaro nga litrato sa usa ka dahon. Siguroha nga may igo nga suga.',
              style: TextStyle(color: c.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ── Result state: image captured + analysis ──────────────────────────────

  Widget _buildResultBody() {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildImagePreview(),
                  const SizedBox(height: 20),
                  if (_loading) _buildLoadingState(),
                  if (_error != null) _buildErrorState(),
                  if (_rawAnalysis != null && !_loading) ...[
                    _buildResultHeader(),
                    const SizedBox(height: 14),
                    if (_diseases.isNotEmpty) ...[
                      ..._diseases.asMap().entries.map(
                            (e) => _DiseaseCard(
                              rank: e.key + 1,
                              disease: e.value,
                            ),
                          ),
                      const SizedBox(height: 20),
                    ],
                    _buildFullAnalysisCard(),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: kIsWeb
            ? Image.memory(_imageBytes!, fit: BoxFit.cover)
            : Image.file(File(_image!.path), fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildLoadingState() {
    final c = context.colors;
    return Column(
      children: [
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) => Opacity(
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
                          'Gi-analyze sa AI...',
                          style: TextStyle(
                            color: c.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Palihug paghulat. Kini medyo dugay.',
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
        const SizedBox(height: 10),
        LinearProgressIndicator(
          backgroundColor: c.surfaceVariant,
          color: c.primary,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildErrorState() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade900),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded,
              color: Colors.red.shade400, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: Colors.red.shade300, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultHeader() {
    final c = context.colors;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: c.accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.biotech_rounded, color: c.primary, size: 20),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Resulta sa Analysis',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: c.accentLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: c.primary, size: 14),
              const SizedBox(width: 4),
              Text(
                'Naluwas',
                style: TextStyle(
                    color: c.primary, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFullAnalysisCard() {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(Icons.description_rounded, color: c.textMuted, size: 16),
                const SizedBox(width: 6),
                Text('Detalyadong Analisis',
                    style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: MarkdownBody(
              data: _rawAnalysis!,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.6),
                strong: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w700),
                listBullet: TextStyle(color: c.accent),
                h3: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    final c = context.colors;
    return Container(
      color: c.background,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _loading ? null : _reset,
              style: OutlinedButton.styleFrom(
                foregroundColor: c.textSecondary,
                side: BorderSide(color: c.divider),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Bag-o nga Scan'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _loading ? null : () => _pickImage(ImageSource.camera),
              style: ElevatedButton.styleFrom(
                backgroundColor: c.primary,
                foregroundColor: c.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.camera_alt_rounded, size: 18),
              label: const Text('Rescan',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Disease Rank Card ────────────────────────────────────────────────────────

class _DiseaseCard extends StatelessWidget {
  const _DiseaseCard({required this.rank, required this.disease});
  final int rank;
  final DiseaseEntry disease;

  @override
  Widget build(BuildContext context) {
    final color = disease.riskColor;
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Rank badge
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      disease.name,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        disease.riskLabel,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                disease.percentageLabel,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          if (disease.percentage > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: disease.percentage / 100,
                minHeight: 8,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
