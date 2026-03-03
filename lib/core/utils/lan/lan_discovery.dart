// LanHostInfo luôn available trên mọi platform.
export 'lan_host_info.dart';

// LanDiscovery: dart:io implementation trên Android,
// web stub trên browser (PWA không thể gửi UDP broadcast).
export 'lan_discovery_io.dart' if (dart.library.html) 'lan_discovery_web.dart';
