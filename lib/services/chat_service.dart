import 'dart:typed_data';
import 'package:chatapp/user/user.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:mime_type/mime_type.dart';
import 'package:http/http.dart' as http;
import 'package:chatapp/globals.dart';
import 'package:chatapp/services/localsqlite.dart';
import './friend_service.dart';
import 'dart:convert';

enum DatabaseType {
  cloud,
  local,
}

enum ResponseType {
  newMessage('newMessage'),
  newFriendRequest('newFriendRequest');

  final String string;
  const ResponseType(this.string);
}

class ChatService {
  static late WebSocketChannel _channel;
  static final Map<String, Function(dynamic)> _callbacks = {};
  static final bucketName = 'aichatapp-image.oss-cn-nanjing.aliyuncs.com';

  static void addCallback<T>(String callbackId, void Function(T) func) {
    _callbacks[callbackId] = (dynamic args) {
      if (args is T) {
        func(args);
      } else {
        logger.e('Callback for $callbackId received an invalid type.');
      }
    };
  }

  static void removeCallback(String callbackId) {
    _callbacks.remove(callbackId);
  }

  static void _invokeCallbacks(dynamic args, String? callbackId) {
    final callback = _callbacks[callbackId];
    if (callback != null) {
      callback(args);
    } else {
      logger.w('Callback with id $callbackId not found.');
    }
  }

  static void connect() {
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    logger.i('Connected to WebSocket server at $wsUrl');
    final config =
        '{"type": "connect", "token": "${CurrentUser.instance.token}"}';
    try {
      _channel.sink.add(config);
    } catch (e) {
      logger.e(e);
    }

    _channel.stream.listen(
      (response) {
        logger.i('Received from server: $response');
        handleResponse(response);
      },
      onDone: () {
        logger.w('WebSocket connection closed.');
      },
      onError: (error, stackTrace) {
        logger.e('WebSocket error: $error');
        logger.e('Stack trace: $stackTrace');
      },
    );
  }

  // 发送消息
  static void sendMessage(
      String? message, String? messageType, int? receiverId) {
    final data =
        '{"type": "sendMessage","content":"$message","message_type":"$messageType","receiverId":$receiverId,"token":"${CurrentUser.instance.token}"}';
    _channel.sink.add(data);
  }

  static void readMessage(int? senderId) {
    final data =
        '{"type": "readMessage","senderId":$senderId,"token":"${CurrentUser.instance.token}"}';
    _channel.sink.add(data);
  }

  void sendFriendRequest(int? friendId) {
    final data = '{"type":"sendFriendRequest","receiverId":$friendId}';
    _channel.sink.add(data);
  }

  // 关闭连接
  static void disconnect() {
    _channel.sink.close();
    logger.i('Disconnected from WebSocket server.');
  }

  static Future<List<Message>> fetchChatHistory(
      int friendId, int messageNum) async {
    // 从node server获取未接收的聊天记录，并写入本地数据库
    final response = await http.post(
      Uri.parse('$serverUrl/api/fetchChatHistory'),
      headers: {
        'Content-Type': 'application/json', // 指定发送 JSON 格式的数据
      },
      body: jsonEncode({
        'userId': CurrentUser.instance.userId,
        'friendId': friendId,
      }),
    );

    if (response.statusCode != 200) {
      // fetchChatHistory失败
      logger.e(response.body);
      throw Exception('Failed to fetch chat history');
    }

    final Map<String, dynamic> decodedJson = jsonDecode(response.body);
    if (!decodedJson.containsKey('messages')) {
      // 结果中不含有messages字段
      throw Exception('Key "messages" not found in response');
    }

    final List<dynamic> data = decodedJson['messages'];
    final List<Message> messages =
        data.map((json) => Message.fromJson(json)).toList();
    await ChatDatabase.saveMessages(messages);

    // 从本地数据库获取最新的messageNum条聊天记录
    final List<Map<String, dynamic>> localMessages =
        await ChatDatabase.getMessages(
            CurrentUser.instance.userId, friendId, messageNum);
    final List<Message> messagesFromLocal =
        localMessages.map((json) => Message.fromJson(json)).toList();

    // 将获取的消息设置为已读
    readMessage(friendId);

    return messagesFromLocal;
  }

  static void sortMessages(List<Message> messages, {bool ascending = false}) {
    messages.sort((a, b) {
      if (ascending) {
        return a.messageId!.compareTo(b.messageId!); // ascending
      } else {
        return b.messageId!.compareTo(a.messageId!); // descending
      }
    });
  }

  static Future<void> sendMessageToBot(
      List<Message> messages, int? receiverId) async {
    final List<Map<String, dynamic>> messagesJson =
        messages.map((message) => message.toJson()).toList();
    final Map<String, dynamic> data = {
      "type": "sendMessage",
      "token": "${CurrentUser.instance.token}",
      "receiverId": receiverId,
      "historyMessages": messagesJson,
    };
    final String jsonData = jsonEncode(data);
    try {
      _channel.sink.add(jsonData);
    } catch (error) {
      logger.e('Error sending messages to bots: $error');
    }
  }

  static void handleResponse(String serverResponse) {
    final Map<String, dynamic> response = jsonDecode(serverResponse);
    logger.i(response);
    final String type = response["type"];
    if (type == ResponseType.newMessage.string) {
      Message receivedMessage = getMessage(response);
      _invokeCallbacks(receivedMessage, type);
    } else if (type == ResponseType.newFriendRequest.string) {
      FriendRequest request = FriendRequest.fromMap(response);
      FriendService.instance.showFriendRequest(request);
    }
  }

  static Message getMessage(Map<String, dynamic> response) {
    return Message(
        messageId: null,
        senderId: response["receiver_id"],
        receiverId: CurrentUser.instance.userId,
        content: response["response"],
        messageType: "text",
        timestamp: response["timestamp"]);
  }

  // 从node server获取带authorization的url
  static Future<String> getUrl(
      {required String objectKey, required String method}) async {
    final response = await http.post(
      Uri.parse('$serverUrl/api/fetchUrl'),
      headers: {
        'Content-Type':
            '${mimeFromExtension(objectKey.split('.').last)}; charset=utf-8',
        'Method': method,
        'Object-Key': objectKey,
      },
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      logger.e(response.body);
      throw Exception('Failed to fetch url');
    }
  }

  // 上传图片
  static Future<void> uploadImage(
      {required String objectKey, required Uint8List fileBytes}) async {
    final response = await http.put(
        Uri.parse(await getUrl(objectKey: objectKey, method: 'PUT')),
        body: fileBytes.toList(
            growable:
                false), // String.fromCharCodes(fileBytes.toList(growable: false)),
        headers: {
          'content-type':
              '${mimeFromExtension(objectKey.split('.').last)}; charset=utf-8',
        });

    if (response.statusCode != 200) {
      logger.e(response.body);
      throw Exception('Failed to upload image');
    }
  }

  // 下载图片
  static Future<Uint8List> downloadImage({required String objectKey}) async {
    final response = await http.get(
      Uri.parse(await getUrl(objectKey: objectKey, method: 'GET')),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      logger.e(response.body);
      throw Exception('Failed to download image');
    }
  }
}
