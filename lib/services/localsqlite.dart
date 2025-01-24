import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:logger/logger.dart';

var logger = Logger();

class ChatDatabase {
  static Database? _database;
  static Future<Database> getDatabase() async {
    if (_database != null) {
      logger.i("Database has been created");
      return _database!;
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'chat_app.db');
    logger.i(path);
    // 打开或创建数据库
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        db.execute('''
CREATE TABLE messages (
    message_id INTEGER PRIMARY KEY AUTOINCREMENT, 
    sender_id INTEGER NOT NULL,                   
    receiver_id INTEGER NOT NULL,  
    is_sender BOOLEAN DEFAULT TRUE,                
    content TEXT NOT NULL,                     
    message_type TEXT DEFAULT 'text',
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
);
CREATE TABLE friends (
    user_id INT NOT NULL, 
    friend_id INT NOT NULL, 
    status ENUM('pending', 'accepted', 'blocked') DEFAULT 'pending', 
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, friend_id)
);
        ''');
      },
    );

    return _database!;
  }

  // 插入聊天记录
  static Future<void> saveMessage(
      String sender, String receiver, String message) async {
    final db = await getDatabase();
    await db.insert(
      'messages',
      {
        'sender': sender,
        'receiver': receiver,
        'content': message,
        'timestamp': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 获取聊天记录
  static Future<List<Map<String, dynamic>>> getMessages(
      String sender, String receiver) async {
    final db = await getDatabase();
    return await db.query(
      'messages',
      where: '(sender = ? AND receiver = ?) OR (sender = ? AND receiver = ?)',
      whereArgs: [sender, receiver, receiver, sender],
      orderBy: 'timestamp ASC',
    );
  }
}
