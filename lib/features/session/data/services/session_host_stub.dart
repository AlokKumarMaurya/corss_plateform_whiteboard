import 'package:cross_platform_whiteboard/features/session/domain/repositories/session_host.dart';
import 'package:cross_platform_whiteboard/features/session/domain/models/session_message.dart';

SessionHost createSessionHost() => _UnsupportedSessionHost();

class _UnsupportedSessionHost implements SessionHost {
  @override
  Stream<SessionMessage> get messages => const Stream<SessionMessage>.empty();

  @override
  List<String> get localAddresses => const <String>[];

  @override
  Future<void> start({required String token, required int port}) {
    throw UnsupportedError(
      'Hosting is available in the Windows desktop app. Connect to a Windows host instead.',
    );
  }

  @override
  void broadcast(SessionMessage message) {}

  @override
  Future<void> close() async {}
}
