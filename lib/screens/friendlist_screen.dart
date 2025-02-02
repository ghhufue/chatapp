import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../user/user.dart';
import '../globals.dart';
import './chathomepage.dart';
import '../services/chat_service.dart';

class FriendListScreen extends StatefulWidget {
  @override
  _FriendListScreenState createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  List<Friend> friendlist = CurrentUser.instance.friendList;
  List<Friend> filteredFriends = [];
  @override
  void initState() {
    super.initState();
  }

  // 搜索函数，过滤好友列表
  void _filterFriends(String query) {
    setState(() {
      filteredFriends = friendlist
          .where((friend) => (friend.nickname?.toLowerCase() ?? '')
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Friend List"),
      ),
      body: Column(
        children: [
          // 搜索框
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: "Search friends",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterFriends, // 当搜索框内容变化时进行过滤
            ),
          ),
          // 显示好友列表
          Expanded(
            child: ListView.builder(
              itemCount: filteredFriends.length,
              itemBuilder: (context, index) {
                final friend = filteredFriends[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: (friend.avatar != null && friend.avatar! != "")
                        ? ClipOval(
                            child: FutureBuilder<Uint8List>(
                              future: ChatService.downloadImage(
                                  objectKey: friend.avatar!),
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
                            child: Icon(Icons.warning, size: 20),
                          ),
                  ),
                  title: Text(friend.nickname ?? ''),
                  onTap: () {
                    // 点击好友项时触发的操作，例如查看好友详情
                    logger.i("Tapped on ${friend.nickname}");
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.chat),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatHomePage()),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.people),
              onPressed: () {
                logger.t("You are already in the chat screen.");
              },
            ),
          ],
        ),
      ),
    );
  }
}
