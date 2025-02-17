import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:chatapp/globals.dart';
import 'package:chatapp/user/user.dart';
import 'package:chatapp/screens/chat_screen.dart';
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
      body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(children: [
            Expanded(
              child: Column(
                children: [
                  Center(
                      child: CircleAvatar(
                    radius: 50,
                    child: (widget.friend.avatar != null &&
                            widget.friend.avatar! != "")
                        ? ClipOval(
                            child: FutureBuilder<Uint8List>(
                              future: ChatService.downloadImage(
                                  objectKey: widget.friend.avatar!),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Container(
                                    width: 100,
                                    height: 100,
                                    alignment: Alignment.center,
                                    child: Icon(Icons.person, size: 40),
                                  );
                                } else if (snapshot.hasError) {
                                  return Icon(Icons.error);
                                }
                                final Uint8List imageBytes = snapshot.data!;
                                return Image.memory(imageBytes, width: 100,
                                    errorBuilder: (context, error, stackTrace) {
                                  return Icon(Icons.error);
                                });
                              },
                            ),
                          )
                        : Container(
                            width: 100,
                            height: 100,
                            alignment: Alignment.center,
                            child: Icon(Icons.person, size: 40),
                          ),
                  )),
                  SizedBox(height: 10),
                  Divider(color: Colors.grey),
                  SizedBox(height: 10),
                  Center(
                      child: Text(
                    widget.friend.friendId == CurrentUser.instance.userId
                        ? "${widget.friend.nickname!} (me)"
                        : widget.friend.nickname!,
                    style: TextStyle(fontSize: 50),
                  )),
                  SizedBox(height: 10),
                  Center(
                      child: Text(
                    "${widget.friend.friendId}",
                    style: TextStyle(fontSize: 30, color: Colors.grey),
                  )),
                ],
              ),
            ),
            SizedBox(width: 10),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 60,
                    child: CurrentUser.instance.userId ==
                            widget.friend.friendId // 是否是自己
                        ? Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () => () // TODO: 编辑个人资料界面
                                    /*Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) => ChatPage(
                                                    friend: widget.friend)))*/
                                    ,
                                    child: Center(
                                        child: Text('Edit profile',
                                            style: TextStyle(fontSize: 20)))),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => ChatPage(
                                                friend: widget.friend))),
                                    child: Center(
                                        child: Text('Go to chat',
                                            style: TextStyle(fontSize: 20)))),
                              )
                            ],
                          )
                        : CurrentUser.instance.friendList
                                .contains(widget.friend) // 是否是好友
                            ? Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) => ChatPage(
                                                    friend: widget.friend))),
                                        child: Center(
                                            child: Text('Go to chat',
                                                style:
                                                    TextStyle(fontSize: 20)))),
                                  )
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        onPressed: () => () // TODO: 加好友界面
                                        /*Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) => ChatPage(
                                                    friend: widget.friend)))*/
                                        ,
                                        child: Center(
                                            child: Text('Add friend',
                                                style:
                                                    TextStyle(fontSize: 20)))),
                                  )
                                ],
                              ),
                  ),
                )
              ],
            ),
          ])),
    );
  }
}
