abstract final class SessionEventType {
  static const String strokeStarted = 'stroke_started';
  static const String strokePoint = 'stroke_point';
  static const String strokeEnded = 'stroke_ended';
  static const String undo = 'undo';
  static const String redo = 'redo';
  static const String clearBoard = 'clear_board';
  static const String requestSnapshot = 'request_snapshot';
  static const String boardSnapshot = 'board_snapshot';

  static const String pointerMove = 'input_pointer_move';
  static const String pointerMoveAbsolute = 'input_pointer_move_absolute';
  static const String pointerDown = 'input_pointer_down';
  static const String pointerUp = 'input_pointer_up';
  static const String scroll = 'input_scroll';
  static const String zoom = 'input_zoom';

  static const Set<String> supported = <String>{
    strokeStarted,
    strokePoint,
    strokeEnded,
    undo,
    redo,
    clearBoard,
    requestSnapshot,
    boardSnapshot,
    pointerMove,
    pointerMoveAbsolute,
    pointerDown,
    pointerUp,
    scroll,
    zoom,
  };
}
