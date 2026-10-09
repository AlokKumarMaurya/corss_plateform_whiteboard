import 'dart:async';
import 'dart:math' as math;

import 'package:cross_platform_whiteboard/core/constants/drawing_constants.dart';
import 'package:cross_platform_whiteboard/features/drawing/domain/models/drawing_point.dart';
import 'package:cross_platform_whiteboard/features/drawing/domain/models/drawing_stroke.dart';
import 'package:cross_platform_whiteboard/features/drawing/domain/models/drawing_tool.dart';
import 'package:cross_platform_whiteboard/features/drawing/domain/repositories/drawing_repository.dart';
import 'package:cross_platform_whiteboard/features/session/domain/models/session_event_type.dart';
import 'package:cross_platform_whiteboard/features/session/domain/models/session_message.dart';
import 'package:cross_platform_whiteboard/features/session/domain/repositories/drawing_sync_gateway.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WhiteboardController extends GetxController {
  WhiteboardController(this._repository, this._sync);

  final DrawingRepository _repository;
  final DrawingSyncGateway _sync;
  final RxList<DrawingStroke> _strokes = <DrawingStroke>[].obs;
  final Rxn<DrawingStroke> activeStroke = Rxn<DrawingStroke>();
  final RxMap<String, DrawingStroke> _remoteActiveStrokes =
      <String, DrawingStroke>{}.obs;
  final Rx<DrawingTool> selectedTool = DrawingTool.pen.obs;
  final RxInt selectedColorValue = const Color(0xFF172033).toARGB32().obs;
  final RxDouble strokeWidth = DrawingConstants.defaultStrokeWidth.obs;
  final RxBool _canRedo = false.obs;
  final List<DrawingStroke> _redoStack = <DrawingStroke>[];
  StreamSubscription<SessionMessage>? _syncSubscription;

  List<DrawingStroke> get strokes => _strokes.toList(growable: false);
  List<DrawingStroke> get remoteActiveStrokes =>
      _remoteActiveStrokes.values.toList(growable: false);
  bool get canUndo => _strokes.isNotEmpty;
  bool get canRedo => _canRedo.value;
  bool get isEmpty =>
      _strokes.isEmpty && activeStroke.value == null && _remoteActiveStrokes.isEmpty;

  @override
  void onInit() {
    super.onInit();
    _strokes.assignAll(_repository.strokes);
    _syncSubscription = _sync.incomingMessages.listen(_handleRemoteMessage);
  }

  void setTool(DrawingTool tool) {
    selectedTool.value = tool;
  }

  void setColor(Color color) {
    selectedColorValue.value = color.toARGB32();
    selectedTool.value = DrawingTool.pen;
  }

  void setStrokeWidth(double width) {
    strokeWidth.value = width
        .clamp(
          DrawingConstants.minimumStrokeWidth,
          DrawingConstants.maximumStrokeWidth,
        )
        .toDouble();
  }

  void startStroke(Offset position, Size size, {double pressure = 1}) {
    if (size.isEmpty) {
      return;
    }
    final bool erasing = selectedTool.value == DrawingTool.eraser;
    final DrawingPoint point = _normalizePoint(position, size, pressure);
    final DrawingStroke stroke = DrawingStroke(
      id: _createStrokeId(),
      points: <DrawingPoint>[point],
      colorValue: erasing ? Colors.white.toARGB32() : selectedColorValue.value,
      width: erasing ? math.max(strokeWidth.value * 4, 16) : strokeWidth.value,
      isEraser: erasing,
    );
    activeStroke.value = stroke;
    _publish(SessionEventType.strokeStarted, <String, dynamic>{
      'stroke': stroke.toJson(),
    });
  }

  void appendPoint(Offset position, Size size, {double pressure = 1}) {
    final DrawingStroke? current = activeStroke.value;
    if (current == null || size.isEmpty) {
      return;
    }
    final DrawingPoint point = _normalizePoint(position, size, pressure);
    activeStroke.value = current.copyWith(
      points: <DrawingPoint>[...current.points, point],
    );
    _publish(SessionEventType.strokePoint, <String, dynamic>{
      'strokeId': current.id,
      'point': point.toJson(),
    });
  }

  void finishStroke() {
    final DrawingStroke? stroke = activeStroke.value;
    if (stroke == null) {
      return;
    }
    _strokes.add(stroke);
    _repository.replaceStrokes(_strokes);
    _redoStack.clear();
    _canRedo.value = false;
    activeStroke.value = null;
    _publish(SessionEventType.strokeEnded, <String, dynamic>{
      'strokeId': stroke.id,
    });
  }

  void undo() => _undo(publish: true);

  void _undo({required bool publish}) {
    if (_strokes.isEmpty) {
      return;
    }
    _redoStack.add(_strokes.removeLast());
    _canRedo.value = true;
    _repository.replaceStrokes(_strokes);
    if (publish) {
      _publish(SessionEventType.undo, const <String, dynamic>{});
    }
  }

  void redo() => _redo(publish: true);

  void _redo({required bool publish}) {
    if (_redoStack.isEmpty) {
      return;
    }
    _strokes.add(_redoStack.removeLast());
    _canRedo.value = _redoStack.isNotEmpty;
    _repository.replaceStrokes(_strokes);
    if (publish) {
      _publish(SessionEventType.redo, const <String, dynamic>{});
    }
  }

  void clearCanvas() => _clearCanvas(publish: true);

  void _clearCanvas({required bool publish}) {
    _strokes.clear();
    _remoteActiveStrokes.clear();
    activeStroke.value = null;
    _redoStack.clear();
    _canRedo.value = false;
    _repository.replaceStrokes(_strokes);
    if (publish) {
      _publish(SessionEventType.clearBoard, const <String, dynamic>{});
    }
  }

  void _handleRemoteMessage(SessionMessage message) {
    if (message.senderId == _sync.clientId) {
      return;
    }

    final Map<String, dynamic> payload = message.payload;
    switch (message.type) {
      case SessionEventType.strokeStarted:
        final Object? rawStroke = payload['stroke'];
        if (rawStroke is Map<String, dynamic>) {
          final DrawingStroke stroke = DrawingStroke.fromJson(rawStroke);
          _remoteActiveStrokes[_remoteKey(message.senderId, stroke.id)] = stroke;
        }
      case SessionEventType.strokePoint:
        final Object? strokeId = payload['strokeId'];
        final Object? rawPoint = payload['point'];
        if (strokeId is! String || rawPoint is! Map<String, dynamic>) {
          return;
        }
        final String key = _remoteKey(message.senderId, strokeId);
        final DrawingStroke? current = _remoteActiveStrokes[key];
        if (current == null) {
          return;
        }
        final DrawingPoint point = DrawingPoint.fromJson(rawPoint);
        _remoteActiveStrokes[key] = current.copyWith(
          points: <DrawingPoint>[...current.points, point],
        );
      case SessionEventType.strokeEnded:
        final Object? strokeId = payload['strokeId'];
        if (strokeId is! String) {
          return;
        }
        final DrawingStroke? stroke =
            _remoteActiveStrokes.remove(_remoteKey(message.senderId, strokeId));
        if (stroke == null) {
          return;
        }
        _strokes.add(stroke);
        _redoStack.clear();
        _canRedo.value = false;
        _repository.replaceStrokes(_strokes);
      case SessionEventType.undo:
        _undo(publish: false);
      case SessionEventType.redo:
        _redo(publish: false);
      case SessionEventType.clearBoard:
        _clearCanvas(publish: false);
      case SessionEventType.requestSnapshot:
        if (_sync.isHost) {
          _publish(SessionEventType.boardSnapshot, <String, dynamic>{
            'strokes': _strokes
                .map((DrawingStroke stroke) => stroke.toJson())
                .toList(growable: false),
          });
        }
      case SessionEventType.boardSnapshot:
        final Object? rawStrokes = payload['strokes'];
        if (rawStrokes is! List<dynamic>) {
          return;
        }
        final List<DrawingStroke> snapshot = rawStrokes.map((Object? raw) {
          if (raw is! Map<String, dynamic>) {
            throw const FormatException('Invalid stroke in board snapshot.');
          }
          return DrawingStroke.fromJson(raw);
        }).toList(growable: false);
        _strokes.assignAll(snapshot);
        _remoteActiveStrokes.clear();
        activeStroke.value = null;
        _redoStack.clear();
        _canRedo.value = false;
        _repository.replaceStrokes(_strokes);
    }
  }

  void _publish(String type, Map<String, dynamic> payload) {
    _sync.publish(
      SessionMessage(senderId: _sync.clientId, type: type, payload: payload),
    );
  }

  String _remoteKey(String senderId, String strokeId) => '$senderId:$strokeId';

  DrawingPoint _normalizePoint(Offset position, Size size, double pressure) {
    return DrawingPoint(
      x: (position.dx / size.width).clamp(0.0, 1.0).toDouble(),
      y: (position.dy / size.height).clamp(0.0, 1.0).toDouble(),
      pressure: pressure.isFinite ? pressure.clamp(0.0, 1.0).toDouble() : 1,
      timestampMicros: DateTime.now().microsecondsSinceEpoch,
    );
  }

  String _createStrokeId() {
    return '${_sync.clientId}-${DateTime.now().microsecondsSinceEpoch}-${_strokes.length}';
  }

  @override
  void onClose() {
    _syncSubscription?.cancel();
    super.onClose();
  }
}
