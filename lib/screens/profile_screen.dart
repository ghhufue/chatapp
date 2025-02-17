import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:chatapp/globals.dart';
import 'package:chatapp/user/user.dart';
import 'package:chatapp/services/chat_service.dart';

class ProfileScreen extends StatefulWidget {
  final Friend friend;
  ProfileScreen({super.key, required this.friend});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          // title: Text("${widget.friend.friendId}'s Profile"),
          ),
      body: Column(
        children: [
          // 显示用户信息
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 25,
                  child: (widget.friend.avatar != null &&
                          widget.friend.avatar! != "")
                      ? ClipOval(
                          child: FutureBuilder<Uint8List>(
                            future: ChatService.downloadImage(
                                objectKey: widget.friend.avatar!),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return CircularProgressIndicator();
                              } else if (snapshot.hasError) {
                                return Icon(Icons.error);
                              }
                              final Uint8List imageBytes = snapshot.data!;
                              return Image.memory(imageBytes, width: 50,
                                  errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.error);
                              });
                            },
                          ),
                        )
                      : Container(
                          width: 50,
                          height: 50,
                          alignment: Alignment.center,
                          child: Icon(Icons.person, size: 20),
                        ),
                ),
                SizedBox(height: 10),
                Text(
                  widget.friend.nickname ?? "Unknown",
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(height: 10),
                Text(
                  "${CurrentUser.instance.userId}",
                  style: TextStyle(fontSize: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
