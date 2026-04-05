// Conditional import for web vs non-web
export 'web_drop_stub.dart'
    if (dart.library.js_interop) 'web_drop_web.dart';
