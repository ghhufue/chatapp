import 'dart:typed_data';
import 'package:chatapp/services/friend_service.dart';
import 'package:flutter/material.dart';
import '../user/user.dart';
import '../globals.dart';
import './chathomepage.dart';
import '../services/chat_service.dart';
import 'package:chatapp/screens/profile_screen.dart';

class FriendInfoWidget extends StatelessWidget {
  final FriendInfo friendInfo;

  FriendInfoWidget({required this.friendInfo});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: (friendInfo.avatar != null && friendInfo.avatar! != "")
            ? ClipOval(
                child: FutureBuilder<Uint8List>(
                  future:
                      ChatService.downloadImage(objectKey: friendInfo.avatar!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        width: 50,
                        height: 50,
                        alignment: Alignment.center,
                        child: Icon(Icons.person, size: 20),
                      );
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
      title: Text(
        friendInfo.friendId ==
                CurrentUser
                    .instance.userId // Replace with current user ID check
            ? "${friendInfo.nickname} (me)"
            : friendInfo.nickname ?? '',
      ),
      onTap: () {
        // Handle the tap event for navigating to a detailed profile screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(friendinfo: friendInfo),
          ),
        );
      },
    );
  }
}

class FriendRequestWidget extends StatelessWidget {
  final FriendRequest friendRequest;
  final Function(FriendRequest) onRemove;
  FriendRequestWidget({required this.friendRequest, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return ListTile(
        leading: CircleAvatar(
          child: (friendRequest.avatar != null && friendRequest.avatar! != "")
              ? ClipOval(
                  child: FutureBuilder<Uint8List>(
                    future: ChatService.downloadImage(
                        objectKey: friendRequest.avatar!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          width: 50,
                          height: 50,
                          alignment: Alignment.center,
                          child: Icon(Icons.person, size: 20),
                        );
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
        title: Text(
          friendRequest.nickname ?? '',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {
                logger.t('Accepted friend request');
                FriendService.instance
                    .handleFriendRequest(friendRequest.friendId, "accepted");
                onRemove(friendRequest);
              },
              icon: Icon(Icons.check, color: Colors.green, size: 30),
            ),
            SizedBox(width: 20),
            IconButton(
              onPressed: () {
                logger.t('Rejected friend request');
                FriendService.instance
                    .handleFriendRequest(friendRequest.friendId, "unrelated");
                onRemove(friendRequest);
              },
              icon: Icon(Icons.close, color: Colors.red, size: 30),
            ),
          ],
        ));
  }
}

class FriendRequestListWidget extends StatefulWidget {
  @override
  _FriendRequestListWidgetState createState() =>
      _FriendRequestListWidgetState();
}

class _FriendRequestListWidgetState extends State<FriendRequestListWidget> {
  void initState() {
    super.initState();
    ChatService.addCallback('newFriendRequest', _receiveFriendRequest);
  }

  void removeFriendRequest(FriendRequest friendRequest) {
    setState(() {
      friendRequestList.remove(friendRequest); // 从列表中移除
    });
  }

  void _receiveFriendRequest(FriendRequest request) {
    setState(() {
      friendRequestList.add(request);
    });
  }

  @override
  Widget build(BuildContext context) {
    return friendRequestList.isEmpty
        ? Center(
            child: Container(
              height: 100,
              width: double.infinity,
              alignment: Alignment.center,
              child: Text(
                'No new friend request',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
          )
        : Container(
            child: Column(
              children: List.generate(friendRequestList.length, (index) {
                return FriendRequestWidget(
                    friendRequest: friendRequestList[index],
                    onRemove: removeFriendRequest);
              }),
            ),
          );
  }
}

class FriendListScreen extends StatefulWidget {
  @override
  _FriendListScreenState createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  List<Friend> friendlist = CurrentUser.instance.friendList;
  List<FriendInfo> friendinfolist = CurrentUser.instance.friendInfoList;
  List<FriendInfo> filteredFriends =
      List.from(CurrentUser.instance.friendInfoList);
  @override
  void initState() {
    super.initState();
  }

  // 搜索函数，过滤好友列表
  void _filterFriends(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredFriends = friendinfolist;
      }
      filteredFriends = friendinfolist
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
            child: ListView(
              children: [
                Container(
                  color: Colors.grey[600],
                  padding:
                      EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Row(
                    children: [
                      Text(
                        "Friend Request",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                FriendRequestListWidget(),
                Container(
                  color: Colors.grey[600],
                  padding:
                      EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Row(
                    children: [
                      Text(
                        "Friend list",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Container(
                  child: Column(
                    children: List.generate(filteredFriends.length, (index) {
                      return FriendInfoWidget(
                          friendInfo: filteredFriends[index]);
                    }),
                  ),
                ),
              ],
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
