import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/chat_message.dart';

class ChatDatabase {
  ChatDatabase._();

  static final ChatDatabase instance = ChatDatabase._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'chat_history.db');

    _database = await openDatabase(
      path,
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE conversations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            conversation_id INTEGER NOT NULL,
            role TEXT NOT NULL,
            content TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            FOREIGN KEY (conversation_id)
              REFERENCES conversations(id)
              ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE reminders (
            id INTEGER PRIMARY KEY,
            title TEXT NOT NULL,
            scheduled_at INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            is_completed INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS reminders (
              id INTEGER PRIMARY KEY,
              title TEXT NOT NULL,
              scheduled_at INTEGER NOT NULL,
              created_at INTEGER NOT NULL,
              is_completed INTEGER NOT NULL DEFAULT 0
            )
          ''');
        }
      },
    );

    return _database!;
  }

  // Create a new conversation.
  Future<int> createConversation(String title) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    return db.insert('conversations', {
      'title': title,
      'created_at': now,
      'updated_at': now,
    });
  }

  // Save a message into one conversation and update the timestamp.
  Future<int> saveMessage(ChatMessage message) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    return db.transaction((txn) async {
      final id = await txn.insert('messages', message.toMap());
      final updatedRows = await txn.update(
        'conversations',
        {'updated_at': now},
        where: 'id = ?',
        whereArgs: [message.conversationId],
      );

      if (updatedRows == 0) {
        throw StateError(
          'Conversation ${message.conversationId} does not exist.',
        );
      }

      return id;
    });
  }

  // Load all messages in one conversation.
  Future<List<ChatMessage>> getMessages(int conversationId) async {
    final db = await database;

    final maps = await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'created_at ASC, id ASC',
    );

    return maps.map(ChatMessage.fromMap).toList();
  }

  // Load the conversation list, newest first.
  Future<List<Map<String, dynamic>>> getConversations() async {
    final db = await database;

    return db.query('conversations', orderBy: 'updated_at DESC, id DESC');
  }

  // Delete one conversation and its messages.
  Future<void> deleteConversation(int id) async {
    final db = await database;

    await db.delete('conversations', where: 'id = ?', whereArgs: [id]);
  }

  // ------------------ Reminders Methods ------------------

  Future<void> saveReminder({
    required int id,
    required String title,
    required int scheduledAt,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert(
      'reminders',
      {
        'id': id,
        'title': title,
        'scheduled_at': scheduledAt,
        'created_at': now,
        'is_completed': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getActiveReminders() async {
    final db = await database;
    return db.query(
      'reminders',
      where: 'is_completed = 0',
      orderBy: 'scheduled_at ASC',
    );
  }

  Future<void> deleteReminder(int id) async {
    final db = await database;
    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markReminderCompleted(int id) async {
    final db = await database;
    await db.update(
      'reminders',
      {'is_completed': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
