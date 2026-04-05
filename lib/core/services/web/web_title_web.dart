// Web-specific title and favicon badge implementation
import 'dart:js_interop';

@JS('eval')
external JSAny? _jsEval(String code);

/// Set the browser tab title.
void setWebTitle(String title) {
  try {
    final safeTitle = title.replaceAll("'", r"\'").replaceAll('"', r'\"');
    _jsEval('document.title = "$safeTitle"');
  } catch (_) {}
}

/// Show or hide a red badge on the favicon.
void setWebFaviconBadge(bool show) {
  try {
    if (show) {
      _jsEval('''
(function(){
  try {
    var c = document.createElement("canvas");
    c.width = 32; c.height = 32;
    var ctx = c.getContext("2d");
    var img = new Image();
    img.onload = function(){
      ctx.drawImage(img, 0, 0, 32, 32);
      ctx.beginPath();
      ctx.arc(24, 8, 8, 0, 2*Math.PI);
      ctx.fillStyle = "#FF0000";
      ctx.fill();
      ctx.strokeStyle = "#FFFFFF";
      ctx.lineWidth = 2;
      ctx.stroke();
      var link = document.querySelector("link[rel='icon']") || document.createElement("link");
      link.rel = "icon";
      link.href = c.toDataURL("image/png");
      document.head.appendChild(link);
    };
    img.src = "favicon.png";
  } catch(e){}
})()
''');
    } else {
      _jsEval('''
(function(){
  try {
    var link = document.querySelector("link[rel='icon']");
    if(link) link.href = "favicon.png";
  } catch(e){}
})()
''');
    }
  } catch (_) {}
}
