// Conditional export: dart:io implementation trên Android/desktop,
// web stub trên browser (PWA chỉ hỗ trợ client mode).
export 'lan_server_io.dart' if (dart.library.html) 'lan_server_web.dart';
