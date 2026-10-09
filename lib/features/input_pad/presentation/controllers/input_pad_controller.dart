import 'dart:async';
import 'dart:ui';

import 'package:cross_platform_whiteboard/features/session/data/services/realtime_session_service.dart';
import 'package:cross_platform_whiteboard/features/session/domain/models/session_event_type.dart';
import 'package:cross_platform_whiteboard/features/session/domain/models/session_message.dart';
import 'package:cross_platform_whiteboard/features/session/domain/models/session_status.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';

/// Converts phone touch/stylus contacts into remote system pointer events.
///
/// One contact draws by holding the remote left mouse button. Two contacts
/// always cancel drawing and navigate using scroll/pinch gestures.
class InputPadController extends GetxController {
  InputPadController(this._session);

  final RealtimeSessionService _session;
  final Map<int, Offset> _contacts = <int, Offset>{};
  final RxBool _isNavigating = false.obs;
  final RxString _hint =
      'Touch with one finger to write; use two fingers to pan or zoom.'.obs;

  Timer? _pendingFingerPress;
  Offset? _gestureCenter;
  double? _gestureDistance;
  bool _leftButtonDown = false;
  bool _suppressSingleUntilAllUp = false;
  bool _singleMoved = false;

  bool get isNavigating => _isNavigating.value;
  String get hint => _hint.value;

  void pointerDown(PointerDownEvent event) {
    _contacts[event.pointer] = event.localPosition;

    if (_contacts.length == 1) {
      _singleMoved = false;
      _suppressSingleUntilAllUp = false;
      if (_isStylus(event.kind)) {
        _pressLeftButton();
      } else {
        // Give a second finger a short window to claim the gesture so that
        // a two-finger pan does not leave an accidental ink dot in Paint.
        _pendingFingerPress?.cancel();
        _pendingFingerPress = Timer(
          const Duration(milliseconds: 70),
          () {
            if (_contacts.length == 1 && !_suppressSingleUntilAllUp) {
              _pressLeftButton();
            }
          },
        );
      }
      return;
    }

    if (_contacts.length == 2) {
      _pendingFingerPress?.cancel();
      _pendingFingerPress = null;
      _releaseLeftButton();
      _isNavigating.value = true;
      _suppressSingleUntilAllUp = true;
      _gestureCenter = _center;
      _gestureDistance = _distance;
      _hint.value = 'Two-finger navigation';
    }
  }

  void pointerMove(PointerMoveEvent event) {
    if (!_contacts.containsKey(event.pointer)) {
      return;
    }
    final Offset previous = _contacts[event.pointer]!;
    _contacts[event.pointer] = event.localPosition;

    if (_contacts.length >= 2) {
      if (!_isNavigating.value) {
        _pendingFingerPress?.cancel();
        _pendingFingerPress = null;
        _releaseLeftButton();
        _isNavigating.value = true;
        _suppressSingleUntilAllUp = true;
        _gestureCenter = _center;
        _gestureDistance = _distance;
        _hint.value = 'Two-finger navigation';
        return;
      }
      _updateNavigation();
      return;
    }

    if (_suppressSingleUntilAllUp) {
      return;
    }

    final Offset delta = event.localPosition - previous;
    if (delta.distanceSquared == 0) {
      return;
    }
    _singleMoved = true;
    _pendingFingerPress?.cancel();
    _pendingFingerPress = null;
    if (!_leftButtonDown) {
      _pressLeftButton();
    }
    _send(SessionEventType.pointerMove, <String, dynamic>{
      'dx': delta.dx,
      'dy': delta.dy,
    });
  }

  void pointerUp(PointerEvent event) {
    final bool wasSingleContact = _contacts.length == 1;
    _contacts.remove(event.pointer);
    _pendingFingerPress?.cancel();
    _pendingFingerPress = null;

    if (_contacts.isEmpty) {
      if (wasSingleContact && !_suppressSingleUntilAllUp && !_singleMoved) {
        // A short tap should still click in the foreground application.
        if (!_leftButtonDown) {
          _pressLeftButton();
        }
      }
      _releaseLeftButton();
      _isNavigating.value = false;
      _suppressSingleUntilAllUp = false;
      _gestureCenter = null;
      _gestureDistance = null;
      _hint.value =
          'Touch with one finger to write; use two fingers to pan or zoom.';
      return;
    }

    // If one finger remains after a two-finger gesture, keep it from starting
    // a stroke until all contacts are lifted.
    if (_suppressSingleUntilAllUp) {
      _isNavigating.value = false;
      _gestureCenter = null;
      _gestureDistance = null;
      return;
    }

    _releaseLeftButton();
  }

  void pointerCancel(PointerCancelEvent event) {
    _contacts.remove(event.pointer);
    _pendingFingerPress?.cancel();
    _pendingFingerPress = null;
    _releaseLeftButton();
    if (_contacts.isEmpty) {
      _isNavigating.value = false;
      _suppressSingleUntilAllUp = false;
      _gestureCenter = null;
      _gestureDistance = null;
    } else {
      _suppressSingleUntilAllUp = true;
    }
  }

  Offset get _center {
    if (_contacts.isEmpty) return Offset.zero;
    final List<Offset> points = _contacts.values.toList(growable: false);
    return points.reduce((Offset a, Offset b) => a + b) / points.length.toDouble();
  }

  double get _distance {
    if (_contacts.length < 2) return 0;
    final List<Offset> points = _contacts.values.toList(growable: false);
    return (points[0] - points[1]).distance;
  }

  void _updateNavigation() {
    final Offset center = _center;
    final double distance = _distance;
    final Offset? previousCenter = _gestureCenter;
    final double? previousDistance = _gestureDistance;
    _gestureCenter = center;
    _gestureDistance = distance;

    if (previousCenter == null || previousDistance == null || previousDistance <= 1) {
      return;
    }

    final double distanceChange = distance - previousDistance;
    final double distanceRatio = distanceChange.abs() / previousDistance;
    if (distanceChange.abs() >= 1.0 || distanceRatio >= 0.005) {
      final int zoomDelta = (distanceChange * 30.0).round().clamp(-480, 480);
      if (zoomDelta != 0) {
        _send(SessionEventType.zoom, <String, dynamic>{'delta': zoomDelta});
      }
      return;
    }

    final Offset movement = center - previousCenter;
    if (movement.distanceSquared > 0) {
      _send(SessionEventType.scroll, <String, dynamic>{
        // Match natural touchpad scrolling: content follows the fingers.
        'dx': -movement.dx * 4,
        'dy': -movement.dy * 4,
      });
    }
  }

  bool _isStylus(PointerDeviceKind kind) =>
      kind == PointerDeviceKind.stylus ||
      kind == PointerDeviceKind.invertedStylus;

  void _pressLeftButton() {
    if (_leftButtonDown) return;
    if (!_isConnected) return;
    _leftButtonDown = true;
    _send(SessionEventType.pointerDown, const <String, dynamic>{});
  }

  void _releaseLeftButton() {
    if (!_leftButtonDown) return;
    _leftButtonDown = false;
    _send(SessionEventType.pointerUp, const <String, dynamic>{});
  }

  bool get _isConnected =>
      _session.isHost || _session.status.value == SessionStatus.connected;

  void _send(String type, Map<String, dynamic> payload) {
    if (!_isConnected) return;
    _session.publish(
      SessionMessage(senderId: _session.clientId, type: type, payload: payload),
    );
  }

  @override
  void onClose() {
    _pendingFingerPress?.cancel();
    _releaseLeftButton();
    super.onClose();
  }
}
