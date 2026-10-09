import 'dart:convert';

import 'package:cross_platform_whiteboard/features/session/domain/models/session_event_type.dart';

class SessionMessage {
  const SessionMessage({
    required this.senderId,
    required this.type,
    required this.payload,
    this.version = currentVersion,
  });

  static const int currentVersion = 1;

  final int version;
  final String senderId;
  final String type;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'version': version,
        'senderId': senderId,
        'type': type,
        'payload': payload,
      };

  String encode() => jsonEncode(toJson());

  factory SessionMessage.decode(String source) {
    final Object? decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Session message must be a JSON object.');
    }
    return SessionMessage.fromJson(decoded);
  }

  factory SessionMessage.fromJson(Map<String, dynamic> json) {
    final Object? version = json['version'];
    final Object? senderId = json['senderId'];
    final Object? type = json['type'];
    final Object? payload = json['payload'];

    if (version != currentVersion) {
      throw FormatException('Unsupported protocol version: $version');
    }
    if (senderId is! String || senderId.isEmpty || senderId.length > 64) {
      throw const FormatException('Invalid sender ID.');
    }
    if (type is! String || !SessionEventType.supported.contains(type)) {
      throw const FormatException('Unsupported session event type.');
    }
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Session payload must be a JSON object.');
    }

    return SessionMessage(
      version: version as int,
      senderId: senderId,
      type: type,
      payload: payload,
    );
  }
}
