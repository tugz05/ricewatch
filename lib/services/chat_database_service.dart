import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/chat_message_model.dart';

/// Local SQLite storage for AI Assistant chat history.
/// On web (Chrome, etc.) sqflite is not supported, so we use in-memory storage.
class ChatDatabaseService {
  static Database? _db;
  static const String _table = 'chat_messages';

  /// In-memory fallback when running on web (sqflite has no web support).
  static final List<ChatMessageModel> _webMessages = [];

  static Future<Database> _getDb() async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ricewatch_chat.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            role TEXT NOT NULL,
            content TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  static Future<void> insertMessage(ChatMessageModel message) async {
    if (kIsWeb) {
      _webMessages.add(ChatMessageModel(
        id: _webMessages.length + 1,
        role: message.role,
        content: message.content,
        createdAt: message.createdAt,
        isFreshResponse: false,
      ));
      return;
    }
    final db = await _getDb();
    await db.insert(
      _table,
      {
        'role': message.role,
        'content': message.content,
        'created_at': message.createdAt.millisecondsSinceEpoch,
      },
    );
  }

  static Future<void> insertMessages(List<ChatMessageModel> messages) async {
    if (kIsWeb) {
      for (final m in messages) {
        _webMessages.add(ChatMessageModel(
          id: _webMessages.length + 1,
          role: m.role,
          content: m.content,
          createdAt: m.createdAt,
          isFreshResponse: false,
        ));
      }
      return;
    }
    final db = await _getDb();
    final batch = db.batch();
    for (final m in messages) {
      batch.insert(
        _table,
        {
          'role': m.role,
          'content': m.content,
          'created_at': m.createdAt.millisecondsSinceEpoch,
        },
      );
    }
    await batch.commit(noResult: true);
  }

  static Future<List<ChatMessageModel>> getAllMessages() async {
    if (kIsWeb) return List<ChatMessageModel>.from(_webMessages);
    final db = await _getDb();
    final rows = await db.query(_table, orderBy: 'created_at ASC');
    return rows.map((r) => ChatMessageModel(
      id: r['id'] as int?,
      role: r['role'] as String,
      content: r['content'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
      isFreshResponse: false, // From DB → no typewriter
    )).toList();
  }

  static Future<void> clearAll() async {
    if (kIsWeb) {
      _webMessages.clear();
      return;
    }
    final db = await _getDb();
    await db.delete(_table);
  }

  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
