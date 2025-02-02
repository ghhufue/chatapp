import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/chat_service.dart';
import 'package:chatapp/globals.dart';

class CurrentUser {
  int? userId;
  String? nickname;
  String? token;
  List<Friend> friendList = [];
  CurrentUser._privateConstructor();
  static final CurrentUser instance = CurrentUser._privateConstructor();
  void clear() {
    userId = null;
    nickname = null;
    token = null;
  }

  Future<void> loadFriends(String serverUrl) async {
    if (token == null) {
      logger.e('User is not authenticated. Token is missing.');
      return;
    }

    final response = await http.get(
      Uri.parse('$serverUrl/api/getfriends?token=$token'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      logger.t(response.body);
      friendList = data.map((json) => Friend.fromJson(json)).toList();
      for (var friend in friendList) {
        logger.t(
            "Friend ID: ${friend.friendId}, Nickname: ${friend.nickname}, Avatar: ${friend.avatar}");
      }
    } else {
      logger.e(
          'Failed to load friends: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> loadMessages(String serverUrl, int messageNum) async {
    try {
      List<Future<void>> tasks = friendList.map((friend) async {
        try {
          List<Message> messages = await ChatService.fetchChatHistory(
            friend.friendId!,
            messageNum,
          );
          friend.historyMessage = messages;
          logger.t(
              'Loaded ${messages.length} messages for friendId ${friend.friendId}');
        } catch (e) {
          logger
              .e('Failed to load messages for friendId ${friend.friendId}: $e');
        }
      }).toList();
      await Future.wait(tasks);

      logger.i("All friends' messages loaded successfully.");
    } catch (e) {
      logger.e('Failed to load messages concurrently: $e');
    }
  }
}

class Friend {
  int? friendId;
  String? nickname;
  String? avatar;
  int? isbot;
  List<Message> historyMessage;

  Friend({
    required this.friendId,
    required this.nickname,
    required this.avatar,
    required this.isbot,
    this.historyMessage = const [], // 默认值为空列表
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      friendId: json['friend_id'] as int?,
      nickname: json['nickname'] as String?,
      avatar: json['avatar'] as String?,
      isbot: json['isbot'] as int?,
      historyMessage: (json['historyMessage'] as List<dynamic>?)
              ?.map((messageJson) => Message.fromJson(messageJson))
              .toList() ??
          [],
    );
  }
}

class Message {
  int? messageId;
  int? senderId;
  int? receiverId;
  String? content;
  String? messageType;
  String? timestamp;
  Message({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.messageType,
    required this.timestamp,
  });
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
        messageId: json["message_id"],
        senderId: json["sender_id"],
        receiverId: json["receiver_id"],
        content: json["content"],
        messageType: json["message_type"],
        timestamp: json["timestamp"]);
  }
  Map<String, dynamic> toJson() {
    return {
      "id": messageId,
      "sender_id": senderId,
      "receiver_id": receiverId,
      "content": content,
      "messageType": messageType,
      "timestamp": timestamp,
    };
  }
}

class ChatImage {
  String? key;
  String? mime;
  Uint8List? data;

  ChatImage({
    required this.key,
    required this.mime,
    required this.data,
  });

  factory ChatImage.fromJson(Map<String, dynamic> json) {
    return ChatImage(key: json['key'], mime: json['mime'], data: json['data']);
  }

  Map<String, dynamic> toJson() {
    return {'key': key, 'mime': mime, 'data': data};
  }
}
