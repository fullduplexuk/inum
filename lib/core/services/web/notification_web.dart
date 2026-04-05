// Web-specific notification implementation using dart:js_interop
import 'dart:js_interop';

@JS('eval')
external JSAny? _jsEval(String code);

/// Request browser notification permission. Returns true if granted.
Future<bool> requestNotificationPermission() async {
  try {
    final result = _jsEval(
      '(function(){ try { return Notification.permission; } catch(e) { return "denied"; } })()',
    );
    final perm = (result as JSString?)?.toDart ?? 'denied';
    if (perm == 'granted') return true;
    if (perm == 'denied') return false;

    // Request permission via promise
    final promiseResult = _jsEval(
      '(async function(){ try { return await Notification.requestPermission(); } catch(e) { return "denied"; } })()',
    );
    final awaited = await (promiseResult as JSPromise<JSAny?>).toDart;
    final granted = (awaited as JSString?)?.toDart ?? 'denied';
    return granted == 'granted';
  } catch (e) {
    return false;
  }
}

/// Show a browser notification.
void showBrowserNotification(String title, String body) {
  try {
    final safeTitle = _escapeJs(title);
    final safeBody = _escapeJs(body);
    _jsEval(
      'try { new Notification("$safeTitle", {body: "$safeBody", icon: "/icons/Icon-192.png"}); } catch(e) {}',
    );
  } catch (e) {
    // Silently fail
  }
}

/// Play a notification sound using Web Audio API.
void playNotificationSound() {
  try {
    _jsEval(
      '(function(){try{var c=new(window.AudioContext||window.webkitAudioContext)();var o=c.createOscillator();var g=c.createGain();o.connect(g);g.connect(c.destination);o.frequency.value=880;o.type="sine";g.gain.value=0.15;o.start(c.currentTime);g.gain.exponentialRampToValueAtTime(0.001,c.currentTime+0.3);o.stop(c.currentTime+0.3);}catch(e){}})()',
    );
  } catch (e) {
    // Silently fail
  }
}

String _escapeJs(String s) {
  return s
      .replaceAll(r'\', r'\\')
      .replaceAll('"', r'\"')
      .replaceAll("'", r"\'")
      .replaceAll('\n', r'\n');
}
