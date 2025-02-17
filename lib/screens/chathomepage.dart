import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../user/user.dart';
import 'package:chatapp/services/chat_service.dart';
import 'package:chatapp/globals.dart';
import 'package:intl/intl.dart';
import 'chat_screen.dart';
import 'friendlist_screen.dart';

class ChatHomePage extends StatefulWidget {
  const ChatHomePage({super.key});

  @override
  _ChatHomePageState createState() => _ChatHomePageState();
}

class _ChatHomePageState extends State<ChatHomePage> {
  bool _isLoading = false; // 加载状态
  List<Friend> _friendList = []; // 用于存储好友列表

  @override
  void initState() {
    super.initState();
    _loadData(); // 页面初始化时加载好友列表
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true; // 开始加载
    });

    try {
      // 调用 CurrentUser 实例的 loadFriends 方法
      await CurrentUser.instance.loadFriends(serverUrl);
      await CurrentUser.instance.loadMessages(serverUrl, maxMessageNum);
      setState(() {
        _friendList = CurrentUser.instance.friendList; // 更新好友列表
      });
    } catch (e) {
      logger.e("Error loading friends: $e");
    } finally {
      setState(() {
        _isLoading = false; // 加载完成
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Friends List'),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(), // 显示加载动画
            )
          : _friendList.isEmpty
              ? Center(
                  child: Text('No friends found!'), // 如果没有好友
                )
              : ListView.builder(
                  itemCount: _friendList.length,
                  itemBuilder: (context, index) {
                    final friend = _friendList[index];
                    return FriendTile(friend: friend); // 自定义好友组件
                  },
                ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.chat),
              onPressed: () {
                logger.t("You are already in the chat screen.");
              },
            ),
            IconButton(
              icon: Icon(Icons.people),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FriendListScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class FriendTile extends StatelessWidget {
  final Friend friend;
  const FriendTile({super.key, required this.friend});

  @override
  Widget build(BuildContext context) {
    // 获取最后一条消息
    final lastMessage = friend.historyMessage.isNotEmpty
        ? friend.historyMessage.first // 消息已按降序排列，首条即最新消息
        : null;

    // 格式化时间，仅显示 "MM-dd HH:mm" 的格式
    String? formattedTime;
    if (lastMessage != null && lastMessage.timestamp != null) {
      final DateTime messageTime =
          DateTime.parse(lastMessage.timestamp!).toLocal();
      formattedTime = DateFormat('MM-dd HH:mm').format(messageTime);
    }

    return ListTile(
      leading: CircleAvatar(
        radius: 25,
        child: (friend.avatar != null && friend.avatar! != "")
            ? ClipOval(
                child: FutureBuilder<Uint8List>(
                  future: ChatService.downloadImage(objectKey: friend.avatar!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
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
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            friend.nickname ?? 'Unknown',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (formattedTime != null) // 如果时间存在，则显示
            Text(
              formattedTime,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
        ],
      ),
      subtitle: lastMessage != null
          ? lastMessage.messageType == "text"
              ? Text(
                  lastMessage.content ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : lastMessage.messageType == "image"
                  ? Text('[Image]') // 如果是图片就显示图片
                  : Text('[Unsupported Message]') // 如果是其他的，那就是暂不支持
          : Text('No messages yet'), // 如果没有消息
      onTap: () {
        // 点击好友项时的操作，比如进入聊天详情页
        logger.t('Tapped on ${friend.nickname}');
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(friend: friend),
            )); // 传递好友对象
      },
    );
  }
}
