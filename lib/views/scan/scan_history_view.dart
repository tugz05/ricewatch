import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../core/theme/app_colors.dart';
import '../../models/scan_record_model.dart';
import '../../services/scan_database_service.dart';
import '../../components/navigation/app_bottom_nav_bar.dart';
import 'treatment_view.dart';

class ScanHistoryView extends StatefulWidget {
  const ScanHistoryView({super.key});

  @override
  State<ScanHistoryView> createState() => _ScanHistoryViewState();
}

class _ScanHistoryViewState extends State<ScanHistoryView> {
  List<ScanRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final records = await ScanDatabaseService.getAll();
    if (!mounted) return;
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  Future<void> _delete(ScanRecord r) async {
    if (r.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF152110),
        title: const Text('Tangtangon?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: const Text(
          'Gusto ba nimo tangtangon kini nga scan record?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Dili',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Oo, Tangtangon',
                style: TextStyle(color: Color(0xFFD32F2F))),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ScanDatabaseService.delete(r.id!);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.header,
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text('Scan History',
            style: TextStyle(
                color: c.textPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
        actions: [
          if (_records.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep_rounded, color: c.textMuted),
              tooltip: 'I-clear tanan',
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: c.card,
                    title: Text('I-clear ang History?',
                        style: TextStyle(
                            color: c.textPrimary, fontWeight: FontWeight.w700)),
                    content: Text('Tanan nga scan records mapapas. Dili na makuha.',
                        style: TextStyle(color: c.textSecondary)),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text('Dili', style: TextStyle(color: c.textMuted))),
                      TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text('I-clear', style: TextStyle(color: c.error))),
                    ],
                  ),
                );
                if (ok == true) {
                  await ScanDatabaseService.clearAll();
                  await _load();
                }
              },
            ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: c.primary))
          : _records.isEmpty
              ? _buildEmpty(c)
              : _buildList(),
      bottomNavigationBar: Navigator.of(context).canPop()
          ? null
          : const AppBottomNavBarWrapper(),
    );
  }

  Widget _buildEmpty(AppColorSet c) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded, size: 64, color: c.textMuted.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('Wala pay scan history',
              style: TextStyle(
                  color: c.textSecondary, fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text('Ang imong mga scan results\nmakit-an dinhi.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textMuted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      itemCount: _records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _HistoryCard(
        record: _records[i],
        onDelete: () => _delete(_records[i]),
      ),
    );
  }
}

// ── History Card ─────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.record, required this.onDelete});
  final ScanRecord record;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final top = record.diseases.isNotEmpty ? record.diseases.first : null;
    final color = top?.riskColor ?? c.accent;

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16)),
              child: SizedBox(
                width: 90,
                height: 90,
                child: _buildThumb(),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.topDisease,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (top != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          top.percentage > 0
                              ? '${top.percentageLabel} · ${top.riskLabel}'
                              : top.riskLabel,
                          style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(record.createdAt),
                      style: TextStyle(color: c.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            // Delete button
            IconButton(
              icon: Icon(Icons.delete_outline_rounded,
                  color: Colors.white.withValues(alpha: 0.3), size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumb() {
    if (record.imagePath.isEmpty) {
      return Container(
        color: const Color(0xFF1A2E1D),
        child: const Icon(Icons.image_not_supported_rounded,
            color: Colors.white24, size: 28),
      );
    }
    if (kIsWeb) {
      return Container(
        color: const Color(0xFF1A2E1D),
        child: const Icon(Icons.photo_rounded, color: Colors.white24, size: 28),
      );
    }
    final file = File(record.imagePath);
    if (!file.existsSync()) {
      return Container(
        color: const Color(0xFF1A2E1D),
        child: const Icon(Icons.broken_image_rounded,
            color: Colors.white24, size: 28),
      );
    }
    return Image.file(file, fit: BoxFit.cover);
  }

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => _ScanDetailView(record: record)),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Karon';
    if (diff.inDays == 1) return 'Gahapon';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ── Detail View ───────────────────────────────────────────────────────────────

class _ScanDetailView extends StatelessWidget {
  const _ScanDetailView({required this.record});
  final ScanRecord record;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.header,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Scan Detail',
            style: TextStyle(
                color: c.textPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: _buildImage(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(record.createdAt),
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 20),
            if (record.diseases.isNotEmpty) ...[
              Text('Mga Nakit-an nga Sakit',
                  style: TextStyle(
                      color: c.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              ...record.diseases.asMap().entries.map(
                    (e) => _DetailDiseaseCard(
                      rank: e.key + 1,
                      disease: e.value,
                      onTreatmentTap: e.value.isHealthy
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => TreatmentView(
                                    diseaseName: e.value.name,
                                  ),
                                ),
                              ),
                    ),
                  ),
              const SizedBox(height: 20),
            ],
            Text('Detalyadong Analisis',
                style: TextStyle(
                    color: c.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.divider),
              ),
              child: MarkdownBody(
                data: record.rawAnalysis,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.6),
                  strong: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w700),
                  listBullet: TextStyle(color: c.accent),
                  h3: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (record.imagePath.isEmpty || kIsWeb) {
      return Container(
        color: const Color(0xFF1A2E1D),
        child: const Icon(Icons.image_rounded, color: Colors.white24, size: 48),
      );
    }
    final f = File(record.imagePath);
    if (!f.existsSync()) {
      return Container(
        color: const Color(0xFF1A2E1D),
        child: const Icon(Icons.broken_image_rounded,
            color: Colors.white24, size: 48),
      );
    }
    return Image.file(f, fit: BoxFit.cover);
  }

  String _formatDate(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month]} ${dt.day}, ${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _DetailDiseaseCard extends StatelessWidget {
  const _DetailDiseaseCard({
    required this.rank,
    required this.disease,
    this.onTreatmentTap,
  });
  final int rank;
  final DiseaseEntry disease;
  final VoidCallback? onTreatmentTap;

  @override
  Widget build(BuildContext context) {
    final color = disease.riskColor;
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: disease.isHealthy
                    ? Icon(Icons.check_circle_rounded, color: color, size: 18)
                    : Text('#$rank',
                        style: TextStyle(
                            color: color, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(disease.name,
                    style: TextStyle(
                        color: c.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
              ),
              Text(disease.percentageLabel,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 20)),
            ],
          ),
          if (disease.percentage > 0 && !disease.isHealthy) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: disease.percentage / 100,
                minHeight: 7,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
          if (onTreatmentTap != null) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onTreatmentTap,
              icon: Icon(Icons.medical_services_rounded, size: 16, color: c.primary),
              label: Text(
                'Tan-aw ug Rekomendasyon',
                style: TextStyle(
                  color: c.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 6),
                alignment: Alignment.centerLeft,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
