import 'package:cross_platform_whiteboard/core/strings/app_strings.dart';
import 'package:cross_platform_whiteboard/features/session/data/services/realtime_session_service.dart';
import 'package:cross_platform_whiteboard/features/session/domain/models/session_status.dart';
import 'package:get/get.dart';

class SessionController extends GetxController {
  SessionController(this._service);

  final RealtimeSessionService _service;
  final RxString hostAddress = ''.obs;
  final RxString accessCode = ''.obs;

  Rx<SessionStatus> get status => _service.status;
  RxList<String> get hostAddresses => _service.hostAddresses;
  RxString get sessionToken => _service.sessionToken;
  RxString get errorMessage => _service.errorMessage;

  void setHostAddress(String value) => hostAddress.value = value.trim();

  void setAccessCode(String value) => accessCode.value = value.trim();

  Future<void> startHost() => _service.startHost();

  Future<void> connect() async {
    if (hostAddress.value.isEmpty || accessCode.value.isEmpty) {
      _service.errorMessage.value = AppStrings.errorMissingConnectionDetails;
      return;
    }
    await _service.connect(
      host: hostAddress.value,
      token: accessCode.value,
    );
  }

  Future<void> disconnect() => _service.disconnect();
}
