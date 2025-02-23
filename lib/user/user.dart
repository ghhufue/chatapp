import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/chat_service.dart';
import 'package:chatapp/globals.dart';
import '../services/friend_service.dart';

class CurrentUser {
  int? userId;
  String? nickname;
  String? token;
  List<Friend> friendList = [];
  List<FriendInfo> friendInfoList = [];
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
      friendInfoList =
          friendList.map((friend) => FriendInfo.fromFriend(friend)).toList();
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
  factory Friend.fromFriendRequest(FriendRequest request) {
    // 假设 isbot 默认为 0（不是机器人），可以根据实际情况调整
    return Friend(
      friendId: request.friendId,
      nickname: request.nickname,
      avatar: request.avatar,
      isbot: 0, // 假设好友都不是机器人，你可以根据实际情况修改
      historyMessage: [
        Message(
            messageId: 0,
            senderId: request.friendId,
            receiverId: CurrentUser.instance.userId,
            content: request.description ?? '',
            messageType: 'text',
            timestamp: DateTime.now().toIso8601String())
      ], // 使用 description 创建一条 Message
    );
  }
}

// 只储存朋友的信息，不包括聊天信息
class FriendInfo {
  int? friendId;
  String? nickname;
  String? avatar;
  int? isbot;

  FriendInfo({
    required this.friendId,
    required this.nickname,
    required this.avatar,
    required this.isbot,
  });

  factory FriendInfo.fromFriend(Friend friend) {
    return FriendInfo(
      friendId: friend.friendId,
      nickname: friend.nickname,
      avatar: friend.avatar,
      isbot: friend.isbot,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'friend_id': friendId,
      'nickname': nickname,
      'avatar': avatar,
      'isbot': isbot,
    };
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
