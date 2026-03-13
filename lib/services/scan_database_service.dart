import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/scan_record_model.dart';

/// Local SQLite storage for rice leaf scan history.
/// Falls back to an in-memory list on web (sqflite has no web support).
class ScanDatabaseService {
  static Database? _db;
  static const String _table = 'scan_records';

  static final List<ScanRecord> _webRecords = [];

  static Future<Database> _getDb() async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ricewatch_scans.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            image_path  TEXT NOT NULL,
            raw_analysis TEXT NOT NULL,
            diseases_json TEXT NOT NULL,
            created_at  INTEGER NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  /// Insert a new scan record and return it with the assigned id.
  static Future<ScanRecord> insert(ScanRecord record) async {
    if (kIsWeb) {
      final saved = ScanRecord(
        id: _webRecords.length + 1,
        imagePath: record.imagePath,
        rawAnalysis: record.rawAnalysis,
        diseases: record.diseases,
        createdAt: record.createdAt,
      );
      _webRecords.add(saved);
      return saved;
    }
    final db = await _getDb();
    final id = await db.insert(_table, record.toMap());
    return ScanRecord(
      id: id,
      imagePath: record.imagePath,
      rawAnalysis: record.rawAnalysis,
      diseases: record.diseases,
      createdAt: record.createdAt,
    );
  }

  /// Returns all scan records, newest first.
  static Future<List<ScanRecord>> getAll() async {
    if (kIsWeb) {
      return List<ScanRecord>.from(_webRecords.reversed);
    }
    final db = await _getDb();
    final rows = await db.query(_table, orderBy: 'created_at DESC');
    return rows.map(ScanRecord.fromMap).toList();
  }

  /// Delete a single record by id.
  static Future<void> delete(int id) async {
    if (kIsWeb) {
      _webRecords.removeWhere((r) => r.id == id);
      return;
    }
    final db = await _getDb();
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> clearAll() async {
    if (kIsWeb) {
      _webRecords.clear();
      return;
    }
    final db = await _getDb();
    await db.delete(_table);
  }
}
