// Conditional import for web vs non-web
export 'web_title_stub.dart'
    if (dart.library.js_interop) 'web_title_web.dart';
