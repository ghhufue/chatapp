import 'package:flutter/material.dart';
import 'package:chatapp/user/user.dart';
import '../services/chat_service.dart';
import 'package:chatapp/globals.dart';

class ChatPage extends StatefulWidget {
  final Friend friend;

  const ChatPage({super.key, required this.friend});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Message> _messages = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  // load messages
  void _loadMessages() {
    setState(() {
      _messages = widget.friend.historyMessage;
      _messages.sort((a, b) => a.timestamp!.compareTo(b.timestamp!)); // 按时间升序排列
    });
  }

  // send messages
  void _sendMessage(String content) {
    if (content.isEmpty) return;
    setState(() {
      ChatService.sendMessage(content, widget.friend.friendId);
      final messageId = _messages.length + 1;

      final newMessage = Message(
          messageId: messageId,
          senderId: CurrentUser.instance.userId,
          receiverId: widget.friend.friendId,
          content: content,
          messageType: "text",
          timestamp: DateTime.now().toIso8601String());
      _messages.add(newMessage);
      _controller.clear();
    });
    // 发送消息后自动滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.friend.nickname ?? 'Chat'),
      ),
      body: Column(
        children: [
          // 消息列表
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isSentByMe =
                    message.senderId == CurrentUser.instance.userId;
                logger.t(message.senderId);
                logger.t(CurrentUser.instance.userId);

                return Align(
                  alignment:
                      isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSentByMe ? Colors.blue[200] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.content ?? '',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _formatTimestamp(message.timestamp),
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 输入框和发送按钮
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _sendMessage(_controller.text),
                  child: Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 格式化时间
  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    final DateTime date = DateTime.parse(timestamp);
    final TimeOfDay time = TimeOfDay.fromDateTime(date);
    return '${date.month}-${date.day} ${time.format(context)}';
  }
}
