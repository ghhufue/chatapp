import 'package:flutter/material.dart';
import 'dart:html';
import 'package:file_picker/file_picker.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'package:mime_type/mime_type.dart' as mime;
import '../user/user.dart';
import '../services/chat_service.dart';
import '../globals.dart';
import '../services/image_service.dart';

class ChatImagePage extends StatefulWidget {
  final Friend friend;
  ChatImagePage({super.key, required this.friend});

  @override
  _ChatImagePageState createState() => _ChatImagePageState();
}

class _ChatImagePageState extends State<ChatImagePage> {
  final TextEditingController _controller = TextEditingController();
  PlatformFile? _selectedFile;
  final logger = Logger();
  var fileEmpty = true;
  List<Message> messages = [];
  String? suffix = "";

  @override
  void initState() {
    super.initState();
  }

  Future<void> _selectFile() async {
    // 选择文件
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image, // 只支持图片类型
        allowMultiple: false, // 单文件选择
      );

      if (result != null) {
        setState(() => _selectedFile = result.files.first);
        fileEmpty = false;
        suffix = _selectedFile!.name.split('.').last.toLowerCase();
      }
    } catch (e) {
      logger.e("Failed to select local file: $e");
    }
  }

  void _sendImage() {
    if (fileEmpty) {
      logger.e('Cannot upload nothing.');
      return;
    }

    final timestamp = DateTime.now().toUtc().toIso8601String();
    final imageUrl = Uri.parse(
        'https://aichatapp-image.su.bcebos.com/chat/${CurrentUser.instance.userId}s${widget.friend.friendId}r$timestamp.$suffix');
    final comment = _controller.text;

    logger.i('Uploading file to $imageUrl');

    try {
      // 发送图片
      BOSUploader.upload(
          accessKey: '5d6fc519e7fa4b9b8d8b590070228e62',
          secretKey: '3908166070914370b15a412792143903',
          bucketName: 'aichatapp-image',
          region: 'su',
          objectKey:
              'chat/${CurrentUser.instance.userId}s${widget.friend.friendId}r$timestamp.$suffix',
          fileBytes: _selectedFile!.bytes!);

      // 插入一条图片消息
      setState(() {
        final messageId = messages.length + 1;
        final newMessage = Message(
            messageId: messageId,
            senderId: CurrentUser.instance.userId,
            receiverId: widget.friend.friendId,
            content: imageUrl.toString(),
            messageType: "image",
            timestamp: timestamp.toString());
        messages.add(newMessage);
        if (widget.friend.isbot == 0) {
          ChatService.sendMessage(
              imageUrl.toString(), "image", widget.friend.friendId);
        } else if (comment.isEmpty) {
          ChatService.sendMessageToBot(messages, widget.friend.friendId);
        }
      });

      // 插入comment（如果有）
      if (comment.isNotEmpty) {
        final messageId = messages.length + 1;
        final newMessage = Message(
            messageId: messageId,
            senderId: CurrentUser.instance.userId,
            receiverId: widget.friend.friendId,
            content: comment,
            messageType: "text",
            timestamp: timestamp.toString());
        messages.add(newMessage);
        if (widget.friend.isbot == 0) {
          ChatService.sendMessage(comment, "text", widget.friend.friendId);
        } else {
          ChatService.sendMessageToBot(messages, widget.friend.friendId);
        }
      }
    } catch (e) {
      logger.e('Upload failed: ${e.toString()}');
    }
    Navigator.pop(context); // 返回聊天界面
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Send image to: ${widget.friend.nickname}'),
      ),
      body: Column(children: [
        Expanded(
            child: Center(
                child: _selectedFile != null
                    ? Image.memory(
                        _selectedFile!.bytes!,
                        width: 500,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.broken_image, size: 50);
                        },
                      )
                    : Icon(Icons.image, size: 50))),
        SizedBox(height: 10),
        Center(
            child: ElevatedButton(
          onPressed: () => _selectFile(),
          child: Text('Select Image'),
        )),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              SizedBox(
                  width: 50,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => {_sendImage()},
                    child: Center(child: Icon(Icons.send)),
                  )),
            ],
          ),
        ),
      ]),
    );
  }
}
