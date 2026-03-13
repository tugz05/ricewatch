import 'dart:convert';
import 'package:flutter/material.dart' show Color;

/// A single detected disease entry parsed from the AI response.
class DiseaseEntry {
  const DiseaseEntry({
    required this.name,
    required this.percentage,
    this.symptoms = '',
  });

  final String name;
  final int percentage;
  final String symptoms;

  Map<String, dynamic> toMap() => {
        'name': name,
        'percentage': percentage,
        'symptoms': symptoms,
      };

  factory DiseaseEntry.fromMap(Map<String, dynamic> m) => DiseaseEntry(
        name: m['name'] as String? ?? '',
        percentage: (m['percentage'] as num?)?.toInt() ?? 0,
        symptoms: m['symptoms'] as String? ?? '',
      );

  /// True when the entry represents a healthy leaf (no disease).
  bool get isHealthy {
    final n = name.toLowerCase();
    return n.contains('healthy') ||
        n.contains('himsog') ||
        n.contains('wala') && (n.contains('sakit') || n.contains('disease')) ||
        n.contains('no disease') ||
        n.contains('walay sakit');
  }

  Color get riskColor {
    if (isHealthy) return const Color(0xFF388E3C); // Healthy — green
    if (percentage == 0) return const Color(0xFF607D8B); // unknown — grey-blue
    if (percentage >= 70) return const Color(0xFFD32F2F);
    if (percentage >= 40) return const Color(0xFFF57C00);
    return const Color(0xFF388E3C);
  }

  String get riskLabel {
    if (isHealthy) return 'Himsog (Healthy)';
    if (percentage == 0) return 'Nakit-an';
    if (percentage >= 70) return 'Grabe (High)';
    if (percentage >= 40) return 'Kababaw (Moderate)';
    return 'Gamay (Low)';
  }

  /// Display string shown in the card badge ("75%" or "–" when unknown).
  String get percentageLabel =>
      isHealthy ? '✓' : (percentage > 0 ? '$percentage%' : '–');
}

/// One full scan record stored in the local database.
class ScanRecord {
  const ScanRecord({
    this.id,
    required this.imagePath,
    required this.rawAnalysis,
    required this.diseases,
    required this.createdAt,
  });

  final int? id;
  final String imagePath;
  final String rawAnalysis;
  final List<DiseaseEntry> diseases;
  final DateTime createdAt;

  String get topDisease =>
      diseases.isNotEmpty ? diseases.first.name : 'Wala nakit-an';

  int get topPercentage =>
      diseases.isNotEmpty ? diseases.first.percentage : 0;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'image_path': imagePath,
        'raw_analysis': rawAnalysis,
        'diseases_json': jsonEncode(diseases.map((d) => d.toMap()).toList()),
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory ScanRecord.fromMap(Map<String, dynamic> m) {
    final raw = m['diseases_json'] as String? ?? '[]';
    final list = (jsonDecode(raw) as List<dynamic>)
        .map((e) => DiseaseEntry.fromMap(e as Map<String, dynamic>))
        .toList();
    return ScanRecord(
      id: m['id'] as int?,
      imagePath: m['image_path'] as String? ?? '',
      rawAnalysis: m['raw_analysis'] as String? ?? '',
      diseases: list,
      createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
    );
  }

  /// Parses disease entries from a Cebuano/Bisaya markdown AI response.
  ///
  /// Multi-pass strategy so disease cards always appear:
  ///   Pass 1 – extract "Name – XX%" / "Name: XX%" / "Name (XX%)" patterns.
  ///   Pass 2 – extract **bold** or listed names without a percentage.
  ///   Pass 3 – scan for any known rice disease keyword as last resort.
  static List<DiseaseEntry> parseDiseases(String markdown) {
    final seen = <String>{};
    final entries = <DiseaseEntry>[];

    void add(String name, int pct) {
      final key = name.toLowerCase().trim();
      if (key.isEmpty || seen.contains(key)) return;
      // Skip lines that are clearly not disease names.
      if (key.length < 3 || key.split(' ').length > 8) return;
      seen.add(key);
      entries.add(DiseaseEntry(name: name.trim(), percentage: pct));
    }

    // ── Pass 1: Name + percentage ──────────────────────────────────────────
    // Matches: **Rice Blast** – 75%  |  Rice Blast: 75%  |  Rice Blast (75%)
    final reWithPct = RegExp(
      r'\*{0,2}([\w][\w\s\(\)/\-]{2,40}?)\*{0,2}'
      r'\s*(?:[:\-–—]+|[(])\s*(\d{1,3})\s*%',
      caseSensitive: false,
    );
    for (final m in reWithPct.allMatches(markdown)) {
      final name = m.group(1)?.trim() ?? '';
      final pct = int.tryParse(m.group(2) ?? '') ?? 0;
      if (name.isNotEmpty && pct > 0) add(name, pct);
    }

    // ── Pass 2: Bold / listed names (no percentage) ────────────────────────
    if (entries.isEmpty) {
      // **Disease Name** anywhere in the text
      final reBold = RegExp(r'\*{1,2}([\w][\w\s\(\)/\-]{2,40}?)\*{1,2}');
      for (final m in reBold.allMatches(markdown)) {
        final name = m.group(1)?.trim() ?? '';
        if (name.isNotEmpty) add(name, 0);
      }
      // Bullet / numbered list items at start of line
      if (entries.isEmpty) {
        final reList = RegExp(
          r'^[ \t]*(?:[-*•]|\d+[.)]) *\*{0,2}([\w][\w\s\(\)/\-]{2,40}?)\*{0,2}[ \t]*$',
          multiLine: true,
        );
        for (final m in reList.allMatches(markdown)) {
          final name = m.group(1)?.trim() ?? '';
          if (name.isNotEmpty) add(name, 0);
        }
      }
    }

    // ── Pass 3: Healthy / no disease check (only when no diseases found) ──
    final lowerText = markdown.toLowerCase();
    final isHealthyMentioned = lowerText.contains('healthy') ||
        lowerText.contains('himsog') ||
        (lowerText.contains('wala') && (lowerText.contains('sakit') || lowerText.contains('disease')));
    if (entries.isEmpty && isHealthyMentioned) {
      add('Healthy (Himsog)', 100); // 100% = healthy
    }

    // ── Pass 4: Known rice disease keyword scan ────────────────────────────
    if (entries.isEmpty) {
      const knownDiseases = [
        'Rice Blast', 'Brown Spot', 'Bacterial Leaf Blight',
        'Sheath Blight', 'Tungro', 'Leaf Scald', 'Stem Rot',
        'False Smut', 'Narrow Brown Leaf Spot', 'Bakanae',
        'Downy Mildew', 'White Tip Nematode', 'Grassy Stunt',
        'Ragged Stunt', 'Sheath Rot', 'Grain Discoloration',
      ];
      for (final d in knownDiseases) {
        if (markdown.toLowerCase().contains(d.toLowerCase())) {
          add(d, 0);
        }
      }
    }

    entries.sort((a, b) => b.percentage.compareTo(a.percentage));
    return entries;
  }
}
