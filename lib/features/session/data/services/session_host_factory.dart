import 'package:cross_platform_whiteboard/features/session/domain/repositories/session_host.dart';
import 'package:cross_platform_whiteboard/features/session/data/services/session_host_stub.dart'
    if (dart.library.io) 'package:cross_platform_whiteboard/features/session/data/services/session_host_io.dart'
    as platform;

SessionHost createSessionHost() => platform.createSessionHost();
