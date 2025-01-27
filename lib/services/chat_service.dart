import 'package:chatapp/user/user.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import 'package:chatapp/globals.dart';
import 'dart:convert';

enum DatabaseType {
  cloud,
  local,
}

class ChatService {
  static late WebSocketChannel _channel;
  static Function(Message)? onNewMessage;
  static void setCallback(Function(Message) func) {
    onNewMessage = func;
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
      (message) {
        logger.i('Received from server: $message');
        handleMessage(message);
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
  static void sendMessage(String? message, int? receiverId) {
    final data =
        '{"type": "sendMessage","content":"$message","receiverId":$receiverId,"token":"${CurrentUser.instance.token}"}';
    _channel.sink.add(data);
  }

  void receiveMessage(String message, String senderId) {}
  void sendFriendRequest(String friendId) {
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
    final response = await http.post(
      Uri.parse('$serverUrl/api/fetchChatHistory'),
      headers: {
        'Content-Type': 'application/json', // 指定发送 JSON 格式的数据
      },
      body: jsonEncode({
        'userId': CurrentUser.instance.userId,
        'friendId': friendId,
        'messageNum': messageNum,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> decodedJson = jsonDecode(response.body);
      if (decodedJson.containsKey('messages')) {
        final List<dynamic> data = decodedJson['messages'];
        //logger.i(data);
        return data.map((json) => Message.fromJson(json)).toList();
      } else {
        throw Exception('Key "messages" not found in response');
      }
    } else {
      logger.e(response.body);
      throw Exception('Failed to fetch chat history');
    }
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

  static void handleMessage(String message) {
    Message receivedMessage = getMessage(jsonDecode(message));
    if (onNewMessage != null) {
      onNewMessage!(receivedMessage);
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
}
