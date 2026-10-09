import 'dart:async';
import 'dart:ui' show Size;

import 'package:cross_platform_whiteboard/core/strings/app_strings.dart';
import 'package:cross_platform_whiteboard/features/session/data/services/realtime_session_service.dart';
import 'package:cross_platform_whiteboard/features/session/domain/models/session_event_type.dart';
import 'package:cross_platform_whiteboard/features/session/domain/models/session_message.dart';
import 'package:cross_platform_whiteboard/features/session/domain/models/session_status.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';

/// Converts phone touch/stylus contacts into remote system pointer events.
///
/// Write mode holds the remote left button while dragging. Move mode moves the
/// pointer without drawing. Two contacts always navigate using scroll/pinch.
class InputPadController extends GetxController {
  InputPadController(this._session);

  final RealtimeSessionService _session;
  final Map<int, Offset> _contacts = <int, Offset>{};
  Size _padSize = Size.zero;
  final RxBool _tabletMode = false.obs;
  final RxDouble _tabletZoom = 1.0.obs;
  final RxDouble _tabletAreaX = 0.5.obs;
  final RxDouble _tabletAreaY = 0.5.obs;
  static const double _edgeSnapFraction = 0.04;
  final RxBool _isNavigating = false.obs;
  final RxBool _writeMode = true.obs;
  final RxDouble _pointerSensitivity = 1.0.obs;
  final RxDouble _scrollSensitivity = 4.0.obs;
  final RxString _hint =
      AppStrings.initialInputHint.obs;

  Timer? _pendingFingerPress;
  Offset? _gestureCenter;
  double? _gestureDistance;
  bool _leftButtonDown = false;
  bool _suppressSingleUntilAllUp = false;
  bool _singleMoved = false;

  bool get isNavigating => _isNavigating.value;
  bool get writeMode => _writeMode.value;
  bool get tabletMode => _tabletMode.value;
  double get tabletZoom => _tabletZoom.value;
  double get tabletAreaX => _tabletAreaX.value;
  double get tabletAreaY => _tabletAreaY.value;
  double get pointerSensitivity => _pointerSensitivity.value;
  double get scrollSensitivity => _scrollSensitivity.value;
  String get hint => _hint.value;

  void setWriteMode(bool value) {
    if (_writeMode.value == value) return;
    _writeMode.value = value;
    _pendingFingerPress?.cancel();
    _pendingFingerPress = null;
    _releaseLeftButton();
    if (_contacts.isNotEmpty) {
      _suppressSingleUntilAllUp = true;
    }
    _hint.value = value
        ? AppStrings.writeModeHint
        : AppStrings.moveModeHint;
  }

  void setPadSize(Size value) {
    if (_padSize == value) return;
    _padSize = value;
  }

  void setTabletMode(bool value) {
    _tabletMode.value = value;
  }

  void setTabletZoom(double value) {
    _tabletZoom.value = value.clamp(1.0, 4.0).toDouble();
  }

  void setTabletAreaX(double value) {
    _tabletAreaX.value = value.clamp(0.0, 1.0).toDouble();
  }

  void setTabletAreaY(double value) {
    _tabletAreaY.value = value.clamp(0.0, 1.0).toDouble();
  }

  void setPointerSensitivity(double value) {
    _pointerSensitivity.value = value.clamp(0.5, 2.5).toDouble();
  }

  void setScrollSensitivity(double value) {
    _scrollSensitivity.value = value.clamp(1.0, 14.0).toDouble();
  }

  /// Moves the remote pointer while a hover-capable stylus is not touching
  /// the phone. This lets users reposition between separate writing strokes.
  void pointerHover(PointerHoverEvent event) {
    if (_contacts.isNotEmpty || !_isStylus(event.kind)) return;
    if (_tabletMode.value) {
      _sendAbsolutePosition(event.localPosition);
      return;
    }
    final Offset delta = event.localDelta;
    if (delta.distanceSquared == 0) return;
    _send(SessionEventType.pointerMove, <String, dynamic>{
      'dx': delta.dx * _pointerSensitivity.value,
      'dy': delta.dy * _pointerSensitivity.value,
    });
  }

  void pointerDown(PointerDownEvent event) {
    _contacts[event.pointer] = event.localPosition;

    if (_contacts.length == 1) {
      if (_tabletMode.value) _sendAbsolutePosition(event.localPosition);
      _singleMoved = false;
      _suppressSingleUntilAllUp = false;
      if (!_writeMode.value) {
        _hint.value = AppStrings.moveModeHint;
      } else if (_isStylus(event.kind)) {
        _pressLeftButton();
      } else {
        // Give a second finger a short window to claim navigation so that a
        // two-finger pan does not leave an accidental ink dot in Paint.
        _pendingFingerPress?.cancel();
        _pendingFingerPress = Timer(
          const Duration(milliseconds: 70),
          () {
            if (_contacts.length == 1 &&
                !_suppressSingleUntilAllUp &&
                _writeMode.value) {
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
      _hint.value = AppStrings.twoFingerHint;
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
        _hint.value = AppStrings.twoFingerHint;
        return;
      }
      _updateNavigation();
      return;
    }

    if (_suppressSingleUntilAllUp) {
      return;
    }

    if (_tabletMode.value) {
      _singleMoved = true;
      _pendingFingerPress?.cancel();
      _pendingFingerPress = null;
      if (_writeMode.value && !_leftButtonDown) {
        _pressLeftButton();
      }
      _sendAbsolutePosition(event.localPosition);
      return;
    }

    final Offset delta = event.localPosition - previous;
    if (delta.distanceSquared == 0) {
      return;
    }
    _singleMoved = true;
    _pendingFingerPress?.cancel();
    _pendingFingerPress = null;
    if (_writeMode.value && !_leftButtonDown) {
      _pressLeftButton();
    }
    _send(SessionEventType.pointerMove, <String, dynamic>{
      'dx': delta.dx * _pointerSensitivity.value,
      'dy': delta.dy * _pointerSensitivity.value,
    });
  }

  void pointerUp(PointerEvent event) {
    final bool wasSingleContact = _contacts.length == 1;
    _contacts.remove(event.pointer);
    _pendingFingerPress?.cancel();
    _pendingFingerPress = null;

    if (_contacts.isEmpty) {
      if (wasSingleContact && !_suppressSingleUntilAllUp && !_singleMoved) {
        // A stationary contact is a click in either mode.
        if (!_leftButtonDown) {
          _pressLeftButton();
        }
      }
      _releaseLeftButton();
      _isNavigating.value = false;
      _suppressSingleUntilAllUp = false;
      _gestureCenter = null;
      _gestureDistance = null;
      _hint.value = _writeMode.value
          ? AppStrings.writeModeHint
          : 'Move mode: drag to move the cursor; tap to click.';
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
    return points.reduce((Offset a, Offset b) => a + b) /
        points.length.toDouble();
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

    if (previousCenter == null ||
        previousDistance == null ||
        previousDistance <= 1) {
      _gestureCenter = center;
      _gestureDistance = distance;
      return;
    }

    final double distanceChange = distance - previousDistance;
    if (distanceChange.abs() >= 2.5) {
      _gestureCenter = center;
      _gestureDistance = distance;
      final int zoomDelta = (distanceChange * 30.0).round().clamp(-480, 480);
      if (zoomDelta != 0) {
        _send(SessionEventType.zoom, <String, dynamic>{'delta': zoomDelta});
      }
      return;
    }

    _gestureCenter = center;
    if (distanceChange.abs() > 0.5) {
      return;
    }

    final Offset movement = center - previousCenter;
    if (movement.distanceSquared > 0) {
      _send(SessionEventType.scroll, <String, dynamic>{
        'dx': -movement.dx * _scrollSensitivity.value,
        'dy': -movement.dy * _scrollSensitivity.value,
      });
    }
  }

  bool _isStylus(PointerDeviceKind kind) =>
      kind == PointerDeviceKind.stylus ||
      kind == PointerDeviceKind.invertedStylus;

  void _sendAbsolutePosition(Offset position) {
    if (_padSize.width <= 0 || _padSize.height <= 0) return;

    // Shrink the active touch range slightly so users do not have to touch
    // the physical edge of the phone to reach the desktop's edges/corners.
    final double touchX = _normalizeTouchCoordinate(
      position.dx,
      _padSize.width,
    );
    final double touchY = _normalizeTouchCoordinate(
      position.dy,
      _padSize.height,
    );
    final double zoom = _tabletZoom.value;
    final double visibleFraction = 1.0 / zoom;
    final double originX = _tabletAreaX.value * (1.0 - visibleFraction);
    final double originY = _tabletAreaY.value * (1.0 - visibleFraction);
    final double x = (originX + touchX * visibleFraction)
        .clamp(0.0, 1.0)
        .toDouble();
    final double y = (originY + touchY * visibleFraction)
        .clamp(0.0, 1.0)
        .toDouble();

    _send(SessionEventType.pointerMoveAbsolute, <String, dynamic>{
      'x': x,
      'y': y,
    });
  }

  double _normalizeTouchCoordinate(double coordinate, double extent) {
    final double fraction = (coordinate / extent).clamp(0.0, 1.0).toDouble();
    return ((fraction - _edgeSnapFraction) / (1.0 - 2 * _edgeSnapFraction))
        .clamp(0.0, 1.0)
        .toDouble();
  }

  void _pressLeftButton() {
    if (_leftButtonDown || !_isConnected) return;
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
