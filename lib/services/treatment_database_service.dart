import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Local SQLite storage for AI-generated treatment recommendations.
/// Caches treatments by disease name to save API tokens and avoid redundant calls.
/// Falls back to in-memory map on web (sqflite has no web support).
class TreatmentDatabaseService {
  static Database? _db;
  static const String _table = 'treatment_cache';

  /// In-memory fallback when running on web.
  static final Map<String, CachedTreatment> _webCache = {};

  static String _normalizeKey(String diseaseName) =>
      diseaseName.trim().toLowerCase();

  static Future<Database> _getDb() async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ricewatch_treatments.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            disease_key TEXT PRIMARY KEY,
            disease_name TEXT NOT NULL,
            raw_markdown TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  /// Returns cached treatment for the disease, or null if not found.
  static Future<CachedTreatment?> getByDisease(String diseaseName) async {
    final key = _normalizeKey(diseaseName);
    if (kIsWeb) {
      return _webCache[key];
    }
    final db = await _getDb();
    final rows = await db.query(
      _table,
      where: 'disease_key = ?',
      whereArgs: [key],
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return CachedTreatment(
      diseaseName: r['disease_name'] as String,
      rawMarkdown: r['raw_markdown'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
    );
  }

  /// Stores a treatment for the disease. Overwrites if already exists.
  static Future<void> save(String diseaseName, String rawMarkdown) async {
    final key = _normalizeKey(diseaseName);
    final now = DateTime.now();
    if (kIsWeb) {
      _webCache[key] = CachedTreatment(
        diseaseName: diseaseName,
        rawMarkdown: rawMarkdown,
        createdAt: now,
      );
      return;
    }
    final db = await _getDb();
    await db.insert(
      _table,
      {
        'disease_key': key,
        'disease_name': diseaseName,
        'raw_markdown': rawMarkdown,
        'created_at': now.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Clears all cached treatments (e.g. for settings).
  static Future<void> clearAll() async {
    if (kIsWeb) {
      _webCache.clear();
      return;
    }
    final db = await _getDb();
    await db.delete(_table);
  }
}

/// Cached treatment record returned from the database.
class CachedTreatment {
  const CachedTreatment({
    required this.diseaseName,
    required this.rawMarkdown,
    required this.createdAt,
  });
  final String diseaseName;
  final String rawMarkdown;
  final DateTime createdAt;
}
