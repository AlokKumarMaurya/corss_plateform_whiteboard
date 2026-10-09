abstract final class SessionConstants {
  static const int defaultPort = 8765;
  // System-wide mouse input must never be shared with multiple remote clients.
  static const int maximumClients = 1;
  static const int maximumMessageBytes = 1048576;
}
