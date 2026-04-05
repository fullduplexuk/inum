// Web-specific drag & drop and paste implementation
import 'dart:js_interop';
import 'dart:typed_data';

@JS('eval')
external JSAny? _jsEval(String code);

typedef WebDropCallback = void Function(Uint8List bytes, String fileName);

bool _dragDropSetup = false;
bool _pasteSetup = false;

WebDropCallback? _globalOnDrop;
void Function(bool)? _globalOnDragOver;
WebDropCallback? _globalOnPaste;

// Dart-callable functions exposed to JS
@JS('window._inumDartOnFile')
external set _setDartOnFile(JSFunction? f);

@JS('window._inumDartOnDragState')
external set _setDartOnDragState(JSFunction? f);

@JS('window._inumDartOnPasteFile')
external set _setDartOnPasteFile(JSFunction? f);

void _dartOnFile(JSString name, JSUint8Array data) {
  _globalOnDrop?.call(data.toDart, name.toDart);
}

void _dartOnDragState(JSBoolean over) {
  _globalOnDragOver?.call(over.toDart);
}

void _dartOnPasteFile(JSString name, JSUint8Array data) {
  _globalOnPaste?.call(data.toDart, name.toDart);
}

const String _setupDragDropJs = '''
(function(){
  var dragCount = 0;
  function onDragOver(e) { e.preventDefault(); e.stopPropagation(); dragCount++; if(window._inumDartOnDragState) window._inumDartOnDragState(true); }
  function onDragLeave(e) { e.preventDefault(); dragCount--; if(dragCount<=0){dragCount=0; if(window._inumDartOnDragState) window._inumDartOnDragState(false);} }
  function onDrop(e) {
    e.preventDefault(); e.stopPropagation(); dragCount=0;
    if(window._inumDartOnDragState) window._inumDartOnDragState(false);
    var files = e.dataTransfer ? e.dataTransfer.files : [];
    for (var i = 0; i < files.length; i++) {
      (function(f){
        var reader = new FileReader();
        reader.onloadend = function(ev) {
          if(window._inumDartOnFile) window._inumDartOnFile(f.name, new Uint8Array(ev.target.result));
        };
        reader.readAsArrayBuffer(f);
      })(files[i]);
    }
  }
  document.addEventListener('dragover', onDragOver);
  document.addEventListener('dragleave', onDragLeave);
  document.addEventListener('drop', onDrop);
  window._inumCleanupDD = function() {
    document.removeEventListener('dragover', onDragOver);
    document.removeEventListener('dragleave', onDragLeave);
    document.removeEventListener('drop', onDrop);
  };
})()
''';

const String _setupPasteJs = '''
(function(){
  function onPaste(e) {
    var items = e.clipboardData ? e.clipboardData.items : [];
    for (var i = 0; i < items.length; i++) {
      if (items[i].type.indexOf('image') === 0) {
        e.preventDefault();
        var file = items[i].getAsFile();
        if (!file) continue;
        (function(f, ext){
          var reader = new FileReader();
          reader.onloadend = function(ev) {
            if(window._inumDartOnPasteFile) window._inumDartOnPasteFile('pasted_image.' + ext, new Uint8Array(ev.target.result));
          };
          reader.readAsArrayBuffer(f);
        })(file, items[i].type.split('/')[1] || 'png');
      }
    }
  }
  document.addEventListener('paste', onPaste);
  window._inumCleanupPaste = function() {
    document.removeEventListener('paste', onPaste);
  };
})()
''';

void setupWebDragDrop({required WebDropCallback onDrop, required void Function(bool) onDragOver}) {
  teardownWebDragDrop();
  _globalOnDrop = onDrop;
  _globalOnDragOver = onDragOver;

  _setDartOnFile = _dartOnFile.toJS;
  _setDartOnDragState = _dartOnDragState.toJS;

  _jsEval(_setupDragDropJs);
  _dragDropSetup = true;
}

void teardownWebDragDrop() {
  if (_dragDropSetup) {
    try { _jsEval('if(window._inumCleanupDD) window._inumCleanupDD()'); } catch(_) {}
    _setDartOnFile = null;
    _setDartOnDragState = null;
    _dragDropSetup = false;
  }
  _globalOnDrop = null;
  _globalOnDragOver = null;
}

void setupWebPasteHandler({required WebDropCallback onPaste}) {
  teardownWebPasteHandler();
  _globalOnPaste = onPaste;

  _setDartOnPasteFile = _dartOnPasteFile.toJS;

  _jsEval(_setupPasteJs);
  _pasteSetup = true;
}

void teardownWebPasteHandler() {
  if (_pasteSetup) {
    try { _jsEval('if(window._inumCleanupPaste) window._inumCleanupPaste()'); } catch(_) {}
    _setDartOnPasteFile = null;
    _pasteSetup = false;
  }
  _globalOnPaste = null;
}
