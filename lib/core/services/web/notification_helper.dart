// Conditional import for web vs non-web
export 'notification_stub.dart'
    if (dart.library.js_interop) 'notification_web.dart';
