import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';
import 'package:chatapp/user/user.dart';
import 'package:chatapp/globals.dart';

class ChatDatabase {
  static Database? _database;
  static Future<Database> getDatabase() async {
    if (_database != null) {
      logger.i("Database has been created");
      return _database!;
    }

    // 获取数据库路径
    var factory = databaseFactoryFfiWeb;
    _database = await factory.openDatabase(
      'aichatapp.db',
      options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) {
            db.execute('''
CREATE TABLE messages (
    message_id INTEGER PRIMARY KEY, 
    sender_id INTEGER NOT NULL,                   
    receiver_id INTEGER NOT NULL,                
    content TEXT NOT NULL,                     
    message_type TEXT DEFAULT 'text',
    timestamp VARCHAR(63)
);
CREATE TABLE friends (
    user_id INT NOT NULL, 
    friend_id INT NOT NULL, 
    status TEXT NOT NULL DEFAULT 'pending', 
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, friend_id)
);
        ''');
          }),
    );

    return _database!;
  }

  // 插入聊天记录
  static Future<void> saveMessages(List<Message> messages) async {
    final db = await getDatabase();
    for (final message in messages) {
      logger.i(
          'Saving message to local database, id: ${message.messageId}, type: ${message.messageType}, timestamp: ${message.timestamp}, sender_id: ${message.senderId}, receiver_id: ${message.receiverId}');
      await db.insert(
        'messages',
        {
          'message_id': message.messageId,
          'sender_id': message.senderId,
          'receiver_id': message.receiverId,
          'content': message.content,
          'message_type': message.messageType,
          'timestamp': message.timestamp,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // 获取聊天记录
  static Future<List<Map<String, dynamic>>> getMessages(
      int? senderId, int? receiverId, int messageNum) async {
    final db = await getDatabase();
    return await db.query(
      'messages',
      where:
          '(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)',
      whereArgs: [senderId, receiverId, receiverId, senderId],
      orderBy: 'timestamp DESC',
      limit: messageNum,
    );
  }

  // 获取本地数据库中最新消息的id
  static Future<int> getLatestMessageId(int? senderId, int? receiverId) async {
    final db = await getDatabase();
    final result = await db.query(
      'messages',
      columns: ['message_id'],
      where:
          '(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)',
      whereArgs: [senderId, receiverId, receiverId, senderId],
      orderBy: 'message_id DESC',
      limit: 1,
    );
    if (result.isEmpty) {
      return 0;
    }
    return result.first['message_id'] as int;
  }
}
