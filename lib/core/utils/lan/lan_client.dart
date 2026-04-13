// Conditional export: WebSocket implementation on Android/desktop,
// WebRTC implementation on browser (PWA).
export 'lan_client_io.dart' if (dart.library.html) 'lan_client_web.dart';
