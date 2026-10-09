import 'package:cross_platform_whiteboard/core/constants/session_constants.dart';

abstract final class AppStrings {
  static const String appName = 'Wireless Stylus Pad';
  static const String inputMode = 'Input mode';
  static const String modeWrite = 'Write';
  static const String modeMove = 'Move';
  static const String pointerSpeed = 'Pointer speed';
  static const String scrollSpeed = 'Scroll speed';
  static const String inputSettings = 'Input settings';
  static const String writeModeHint = 'Drag to write in the active Windows app.';
  static const String moveModeHint = 'Drag to move the cursor; tap to click.';
  static const String twoFingerHint = 'Two fingers scroll or pinch to zoom.'
  static const String whiteboardTitle = 'Windows companion';
  static const String whiteboardSubtitle =
      'Connect your phone and control the active Windows application.';
  static const String canvasLabel = 'Whiteboard canvas';
  static const String toolPen = 'Pen';
  static const String toolEraser = 'Eraser';
  static const String actionUndo = 'Undo';
  static const String actionRedo = 'Redo';
  static const String actionClear = 'Clear canvas';
  static const String actionClearTitle = 'Clear the canvas?';
  static const String actionClearMessage =
      'This will remove every stroke from the current board.';
  static const String actionCancel = 'Cancel';
  static const String actionClearConfirm = 'Clear';
  static const String actionExport = 'Export';
  static const String statusReady = 'Ready to draw';
  static const String statusDrawing = 'Drawing';
  static const String statusEmpty = 'Start drawing anywhere on the canvas.';
  static const String actionComingSoon =
      'This tool will be available in a later milestone.';
  static const String sectionTools = 'Tools';
  static const String sectionCanvas = 'Canvas';
  static const String colorBlack = 'Black';
  static const String colorBlue = 'Blue';
  static const String colorRed = 'Red';
  static const String colorGreen = 'Green';
  static const String sectionColor = 'Color';
  static const String sectionWidth = 'Width';
  static const String actionConnectPhone = 'Connect phone';
  static const String titlePhoneConnection = 'Phone connection';
  static const String canvasSemanticsLabel = 'Whiteboard drawing area';
  static const String sectionConnection = 'Connection';
  static const String actionStartSession = 'Start Windows companion';
  static const String actionStopSession = 'Stop connection';
  static const String actionConnectSession = 'Connect to Windows';
  static const String actionDisconnectSession = 'Disconnect';
  static const String actionCopyCode = 'Copy session code';
  static const String labelHostAddress = 'Windows IP address';
  static const String hintHostAddress = 'Example: 192.168.1.20';
  static const String labelSessionCode = 'Session code';
  static const String hintSessionCode = 'Paste the code shown on Windows';
  static const String statusDisconnected = 'Disconnected';
  static const String statusConnecting = 'Connecting';
  static const String statusHosting = 'Waiting for phone';
  static const String statusConnected = 'Connected';
  static const String messageWindowsHostReady =
      'Enter one of these addresses and the session code on your phone:';
  static const String messageNoHostAddresses =
      'No private IPv4 address found. Connect this PC to Wi-Fi or Ethernet and try again.';
  static const String messageKeepCodePrivate =
      'Only share this code with the phone you want to control Windows.';
  static const String messageConnectedToHost =
      'Connected to the Windows companion.';
  static const String messageSameNetwork =
      'Phone and Windows must be on the same Wi-Fi/LAN.';
  static const String errorMissingConnectionDetails =
      'Enter the Windows IP address and session code.';
  static const int sessionPort = SessionConstants.defaultPort;
}
