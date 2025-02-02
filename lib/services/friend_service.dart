import 'package:chatapp/user/user.dart';
import 'package:flutter/material.dart';
import 'package:chatapp/globals.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FriendService {
  FriendService._privateConstructor();
  static final FriendService instance = FriendService._privateConstructor();

  // 显示好友申请弹窗
  void showFriendRequest(FriendRequest friendRequest) {
    // 使用 global navigatorKey 获取 OverlayState
    final navigatorState = navigatorKey.currentState;
    if (navigatorState != null) {
      // 获取当前页面的 OverlayState
      OverlayState overlayState = navigatorState.overlay!;

      // 创建一个 OverlayEntry，设置弹窗的内容
      OverlayEntry overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          top: 100,
          right: 20,
          child: Material(
            color: Colors.transparent,
            child: FriendRequestDialog(friendRequest: friendRequest),
          ),
        ),
      );

      // 插入到 Overlay 上
      overlayState.insert(overlayEntry);

      // 设置弹窗关闭时间，5秒后自动消失
      Future.delayed(Duration(seconds: 5), () {
        overlayEntry.remove();
      });
    }
  }

  static Future<void> searchUser(String userId) async {
    final response =
        await http.get(Uri.parse('$serverUrl/api/searchUser?userId=$userId'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['user'] != null) {
        sendFriendRequest(data['user']['id']);
      } else {
        logger.w("User not found");
      }
    } else {
      logger.e('Failed to search user');
    }
  }

  static Future<void> sendFriendRequest(String friendId) async {
    final response = await http.post(
      Uri.parse('$serverUrl/api/sendFriendRequest'),
      body: json.encode({
        'senderId': CurrentUser.instance.userId,
        'receiverId': friendId,
      }),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      logger.i('Friend request sent');
    } else {
      logger.e('Failed to send friend request');
    }
  }

  Future<void> handleFriendRequest(int? senderId, String action) async {
    final response = await http.post(
      Uri.parse('$serverUrl/api/updateFriendRequest'),
      body: jsonEncode({
        'senderId': senderId,
        'status': action,
      }),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      logger.t(response.body);
    } else {
      logger.e(response.body);
    }
  }
}

class FriendRequest {
  int? friendId;
  String? description;
  String? nickname;
  String? avatar;
  FriendRequest({
    required this.friendId,
    this.nickname,
    this.description,
    required this.avatar,
  });
}

class FriendRequestDialog extends StatelessWidget {
  final FriendRequest friendRequest;
  FriendRequestDialog({required this.friendRequest});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
      },
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(friendRequest.avatar!),
                    radius: 30,
                  ),
                  SizedBox(width: 10),
                  Text(
                    friendRequest.nickname!,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(friendRequest.description ?? 'No description'),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      logger.t('Accepted friend request');
                      Navigator.of(context).pop();
                      FriendService.instance.handleFriendRequest(
                          friendRequest.friendId, "accepted");
                    },
                    icon: Icon(Icons.check, color: Colors.green, size: 30),
                  ),
                  SizedBox(width: 20),
                  IconButton(
                    onPressed: () {
                      logger.t('Rejected friend request');
                      Navigator.of(context).pop();

                      FriendService.instance.handleFriendRequest(
                          friendRequest.friendId, "unrelated");
                    },
                    icon: Icon(Icons.close, color: Colors.red, size: 30),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
