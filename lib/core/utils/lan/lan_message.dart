import 'dart:convert';

// ============================================================
// LanMessageType — loại message trao đổi giữa các peer
// ============================================================

enum LanMessageType {
  /// Gửi khi vừa kết nối, giới thiệu senderId và displayName.
  hello,

  /// Payload dữ liệu tuỳ ý (game state, action, v.v.).
  data,

  /// Kiểm tra kết nối còn sống hay không.
  ping,

  /// Phản hồi ping.
  pong,

  /// Thông báo ngắt kết nối chủ động.
  bye,

  /// Thông báo lỗi.
  error,
}

// ============================================================
// LanMessage — đơn vị dữ liệu truyền qua WebSocket
// ============================================================

/// Đơn vị dữ liệu trao đổi giữa host và client qua WebSocket.
///
/// Serialized thành JSON string trước khi gửi qua socket.
/// [payload] là Map tuỳ ý — caller quy định nội dung.
class LanMessage {
  /// Loại message (dùng [LanMessageType.name] để serialize).
  final String type;

  /// ID của thiết bị gửi.
  final String senderId;

  /// ID thiết bị nhận. `null` = broadcast đến tất cả.
  final String? targetId;

  /// Nội dung message tuỳ ý.
  final Map<String, dynamic> payload;

  /// Thời điểm tạo (millisecondsSinceEpoch).
  final int timestamp;

  const LanMessage({
    required this.type,
    required this.senderId,
    this.targetId,
    this.payload = const {},
    required this.timestamp,
  });

  // ----------------------------------------------------------
  // Serialization
  // ----------------------------------------------------------

  factory LanMessage.fromJson(Map<String, dynamic> json) {
    return LanMessage(
      type: json['type'] as String,
      senderId: json['senderId'] as String,
      targetId: json['targetId'] as String?,
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
      timestamp: json['timestamp'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'senderId': senderId,
        if (targetId != null) 'targetId': targetId,
        'payload': payload,
        'timestamp': timestamp,
      };

  String toJsonString() => jsonEncode(toJson());

  /// Parse từ raw JSON string. Trả về `null` nếu lỗi format.
  static LanMessage? tryParse(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return LanMessage.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  // ----------------------------------------------------------
  // Typed getters
  // ----------------------------------------------------------

  LanMessageType get messageType {
    return LanMessageType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => LanMessageType.data,
    );
  }

  // ----------------------------------------------------------
  // Static factories — tạo nhanh các loại message phổ biến
  // ----------------------------------------------------------

  /// Gửi khi vừa kết nối để giới thiệu bản thân.
  static LanMessage hello(
    String senderId, {
    String? displayName,
  }) =>
      LanMessage(
        type: LanMessageType.hello.name,
        senderId: senderId,
        payload: {
          if (displayName != null) 'displayName': displayName,
        },
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

  /// Gửi payload dữ liệu tuỳ ý.
  static LanMessage data(
    String senderId,
    Map<String, dynamic> data, {
    String? targetId,
  }) =>
      LanMessage(
        type: LanMessageType.data.name,
        senderId: senderId,
        targetId: targetId,
        payload: data,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

  /// Kiểm tra connection còn sống.
  static LanMessage ping(String senderId) => LanMessage(
        type: LanMessageType.ping.name,
        senderId: senderId,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

  /// Phản hồi ping.
  static LanMessage pong(String senderId) => LanMessage(
        type: LanMessageType.pong.name,
        senderId: senderId,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

  /// Thông báo ngắt kết nối chủ động.
  static LanMessage bye(String senderId) => LanMessage(
        type: LanMessageType.bye.name,
        senderId: senderId,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

  /// Thông báo lỗi kèm message.
  static LanMessage error(String senderId, String message) => LanMessage(
        type: LanMessageType.error.name,
        senderId: senderId,
        payload: {'message': message},
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

  @override
  String toString() =>
      'LanMessage(type: $type, from: $senderId, to: ${targetId ?? "all"}, '
      'payload: $payload)';
}

// ============================================================
// LanIncomingEvent — event nhận được từ server hoặc client
// ============================================================

/// Event được emit trên stream khi nhận được message.
///
/// [clientId] là ID nội bộ của peer gửi message.
/// Trên host: clientId là UUID được server gán cho mỗi connection.
/// Trên client: clientId là 'host'.
class LanIncomingEvent {
  final String clientId;
  final LanMessage message;

  const LanIncomingEvent({
    required this.clientId,
    required this.message,
  });

  @override
  String toString() =>
      'LanIncomingEvent(from: $clientId, msg: $message)';
}
