import 'package:cross_platform_whiteboard/features/session/domain/models/session_message.dart';

abstract interface class DrawingSyncGateway {
  String get clientId;
  bool get isHost;
  Stream<SessionMessage> get incomingMessages;

  void publish(SessionMessage message);
}
