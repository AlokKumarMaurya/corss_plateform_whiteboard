import 'package:cross_platform_whiteboard/features/session/domain/models/session_message.dart';

abstract interface class SessionHost {
  Stream<SessionMessage> get messages;
  List<String> get localAddresses;

  Future<void> start({required String token, required int port});
  void broadcast(SessionMessage message);
  Future<void> close();
}
