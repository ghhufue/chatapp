# 主动交互式聊天平台应用程序

## 项目结构

```
lib/
├── globals.dart          # 全局变量和配置
├── main.dart             # 程序入口
├── screens/              # 界面组件
│   ├── chathomepage.dart      # 聊天首页（显示好友列表）
│   ├── chat_screen.dart       # 聊天界面
│   ├── chat_screen_image.dart # 上传图片界面
│   ├── login_screen.dart      # 登录界面
│   ├── register_screen.dart   # 注册界面
│   ├── friendlist_screen.dart # 好友管理界面
├── services/             # 服务层（处理逻辑）
│   ├── auth_service.dart      # 认证服务（登录、注册）
│   ├── chat_service.dart      # 聊天服务（聊天相关功能，包括文字信息和图片的接收与传输）
│   ├── friend_service.dart    # 好友相关服务
│   ├── localsqlite.dart       # 本地数据库服务，使用 SQLite 存储数据（暂未实现）
└── user/                 # 用户相关数据
    └── user.dart               # 用户模型
```

## 安装和配置

1. 克隆项目到本地：

   ```bash
   git clone https://github.com/ghhufue/chatapp.git
   cd chatapp
   ```

2. 安装依赖：

   ```bash
   flutter pub get
   ```

3. 运行项目：
   ```bash
   flutter run
   ```

## 当前任务进度

### ✅ 完成任务

- **用户管理功能：**

  - [x] 登录功能
  - [x] 注册功能
  - [x] 加密储存隐私信息
  - [x] 用户 token 的生成与验证

- **好友聊天功能：**
  - [x] 好友列表的加载与显示
  - [x] 消息的及时转发及存储
  - [x] 图片显示与传输功能 🖼️ &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; **负责人**: 🧑‍💻 jcl

- **机器人聊天功能：**
  - [x] 机器人的实时聊天功能

---

### 🚀 正在进行中

- **功能开发：**
  - [ ] 好友添加的程序及界面 🤝 &nbsp;&nbsp;&nbsp;&nbsp; **负责人**: 🧑‍💻 zhz
  - [ ] 个人资料界面 🤝 &nbsp;&nbsp;&nbsp;&nbsp; **负责人**: 🧑‍💻 jcl

---

### ⏳ 待开始

- **功能实现：**
  - [ ] 好友管理页面
  - [ ] 不定时的主动式交互
  - [ ] 个性化定制私有聊天伙伴
  - [ ] 朋友圈机器人评论分享功能
  - [ ] 用户偏好（如聊天频率，活跃时间，兴趣爱好，性格品质，人生经历）的分析与好友推荐
- **架构优化：**
  - [ ] 本地数据库 sqlite 的缓存机制
- **产品部署：**
  - [ ] 本地服务器移植到云服务器
  - [ ] 发布 app 并进行测试

## 功能详情

### auth_service.dart

```dart
class AuthService {
  static late final String baseUrl; // 服务器地址
  static void init() {}
  static Future<Map<String, dynamic>>  register(String username, String password, String phoneNumber) async {}
  static Future<Map<String, dynamic>> login(String username, String password) async {}
}
```

### chat_service.dart

```dart

class ChatService {
  static late WebSocketChannel _channel;
  static Function(Message)? onNewMessage;
  static void setCallback(Function(Message) func) {
    onNewMessage = func;
  }
  static void connect() {} // 初始化连接，用于与服务器websocket建立连接，并注册
  static void sendMessage(String? message, String? messageType, int? receiverId) {} // 发送消息，同时传入用户token用作验证
  static void readMessage(int? senderId) {} // 告知服务器已阅读过某人的消息，更新消息状态
  void sendFriendRequest(String friendId) {} // 发送朋友申请
  static void sortMessages(List<Message> messages) {} // 按时间顺序排列消息
  static Future<void> sendMessageToBot(List<Message> messages, int? receiverId) async {}
  // 发送给机器人消息，同时附上历史聊天记录，回复消息现在会通过websocket直接传回
  static void handleMessage(String message) {} // 实时接收到消息时调用回调函数，更新消息列表（这里逻辑有点复杂）
  static Message getMessage(Map<String, dynamic> response) {} // 将response解包为Message类型
  static Future<String> getUrl(String objectKey, String method) async {} // 向node server请求存储桶中名称为objectKey的图片的带签名链接，对应的方法是method
  static Future<void> uploadImage(
      String objectKey, Uint8List fileBytes) async {} // 向存储桶发送要上传的图片的名称objectKey和数据fileBytes
  static Future<Uint8List> downloadImage(String objectKey) async {} // 向存储桶请求其中名称为objectKey的图片数据
}

```

### user.dart

```dart
class CurrentUser {
  int? userId;
  String? nickname;
  String? token;
  List<Friend> friendList = [];
  CurrentUser._privateConstructor();
  static final CurrentUser instance = CurrentUser._privateConstructor();
  void clear() {}
  Future<void> loadFriends(String serverUrl) async {} // 加载好友
  Future<void> loadMessages(String serverUrl, int messageNum) async {} // 加载消息
}

class Friend {
  int? friendId;
  String? nickname;
  String? avatar;
  int? isbot;
  List<Message> historyMessage;
  factory Friend.fromJson(Map<String, dynamic> json) {} // 将json类型转化成Friend类型
}

class Message {
  int? messageId; // 注意，这里的id不是数据库中消息的id，而是某个朋友下消息的id（在服务器端被处理过）
  int? senderId;
  int? receiverId;
  String? content;
  String? messageType;
  String? timestamp;
  factory Message.fromJson(Map<String, dynamic> json) {}
  // 注意区分 "sender_id"和"senderId"，"receiver_id"和"receiverId"，"messageType"和"message_type"
  // 如果发现某个数据为空，可能是上面键值写错的原因，具体见服务器端的名称
  Map<String, dynamic> toJson() {
    return {
      "id": messageId,
      "sender_id": senderId,
      "receiver_id": receiverId,
      "content": content,
      "messageType": messageType,
      "timestamp": timestamp,
    };
  }
}
```

⚠ **具体实现细节请问 yht（消息部分）或 jcl（图片部分）** ⚠

---

## 数据库结构

连接到数据库指令

```bash
mysql -u remote_user -p -h chatappdb.yht20050302.top -P 53578
```

# 数据库结构说明

该数据库用于存储聊天应用的数据，包含三个表：`users`、`friends` 和 `messages`。下面是对每个表的结构和字段含义的详细解释。

## 1. `users` 表

此表用于存储用户信息。

| 字段名称          | 类型           | 说明                                               |
| ----------------- | -------------- | -------------------------------------------------- |
| `id`              | `int`          | 用户的唯一标识，自动增长。                         |
| `username`        | `varchar(255)` | 用户的用户名，必须唯一。                           |
| `encrypted_phone` | `text`         | 加密存储的用户电话号码。                           |
| `iv`              | `varchar(32)`  | 用于加密的初始化向量（IV），确保加密数据的安全性。 |
| `created_at`      | `timestamp`    | 用户账号的创建时间，默认为当前时间。               |
| `password`        | `varchar(255)` | 用户的密码，使用加密存储（哈希值）。               |
| `nickname`        | `varchar(255)` | 用户的昵称，可选。                                 |
| `avatar`          | `varchar(255)` | 用户头像的 URL，默认为一个占位符图片。             |
| `isbot`           | `tinyint(1)`   | 用户是否为机器人，默认否                           |

## 2. `friends` 表

此表用于存储用户之间的好友关系。

| 字段名称     | 类型        | 说明                                       |
| ------------ | ----------- | ------------------------------------------ |
| `user_id`    | `int`       | 用户的 ID，关联 `users` 表中的 `id` 字段。 |
| `friend_id`  | `int`       | 好友的 ID，关联 `users` 表中的 `id` 字段。 |
| `status`     | `enum`      | 好友关系的状态                             |
| `created_at` | `timestamp` | 好友关系建立的时间，默认为当前时间。       |

好友关系的状态有以下四种：

- `'unrelated'`：无关系
- `'pending'`：待确认
- `'accepted'`：已接受
- `'blocked'`：已阻止

## 3. `messages` 表

此表用于存储用户之间的消息。

| 字段名称       | 类型          | 说明                                                          |
| -------------- | ------------- | ------------------------------------------------------------- |
| `message_id`   | `int`         | 消息的唯一标识，自动增长。                                    |
| `sender_id`    | `int`         | 发送者的 ID，关联 `users` 表中的 `id` 字段。                  |
| `receiver_id`  | `int`         | 接收者的 ID，关联 `users` 表中的 `id` 字段。                  |
| `content`      | `text`        | 消息的内容。                                                  |
| `message_type` | `varchar(10)` | 消息类型，默认值为 `'text'`，可能的值为 `'text'` 或其他类型。 |
| `timestamp`    | `datetime`    | 消息的发送时间，默认为当前时间。                              |
| `is_received`  | `tinyint(1)`  | 消息是否已接收，`0` 表示未接收，`1` 表示已接收。              |

---

# 大模型

## 本次需要构建的大模型需要具有以下特点：

- 碎片化，口语化，网络化的语言风格，模仿人类在社交媒体上聊天时的风格
- 回复更加关注用户的话语中的情感，心情，结合用户的经历进行回复
- 需要有个性化的回复，建立大模型个体的性格，喜好

## 参考资料

大模型的构建将在 Chatglm3-6B 的基础上进行微调和训练，以下是可供参考的资料：

- [Chatglm3-6B Github Page](https://github.com/THUDM/ChatGLM-6B)
- [HuggingFace](https://huggingface.co/THUDM/chatglm-6b)
- [Modelscope](https://www.modelscope.cn/models/ZhipuAI/chatglm3-6b)
- [智普 ai 开发文档](https://zhipu-ai.feishu.cn/wiki/WvQbwIJ9tiPAxGk8ywDck6yfnof)
