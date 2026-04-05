// Web-specific drag & drop and paste implementation
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

typedef WebDropCallback = void Function(Uint8List bytes, String fileName);

web.EventListener? _dragOverListener;
web.EventListener? _dragLeaveListener;
web.EventListener? _dropListener;
web.EventListener? _pasteListener;

void setupWebDragDrop({required WebDropCallback onDrop, required void Function(bool) onDragOver}) {
  teardownWebDragDrop();
  _dragOverListener = (web.Event e) {
    e.preventDefault();
    onDragOver(true);
  }.toJS;
  _dragLeaveListener = (web.Event e) {
    e.preventDefault();
    onDragOver(false);
  }.toJS;
  _dropListener = (web.Event e) {
    e.preventDefault();
    onDragOver(false);
    final de = e as web.DragEvent;
    final dt = de.dataTransfer;
    if (dt == null) return;
    final files = dt.files;
    for (int i = 0; i < files.length; i++) {
      final file = files.item(i);
      if (file == null) continue;
      final reader = web.FileReader();
      final fileName = file.name;
      reader.onloadend = (web.Event ev) {
        final result = reader.result;
        if (result != null) {
          final arrayBuf = result as JSArrayBuffer;
          final bytes = arrayBuf.toDart.asUint8List();
          onDrop(bytes, fileName);
        }
      }.toJS;
      reader.readAsArrayBuffer(file);
    }
  }.toJS;

  web.document.addEventListener('dragover', _dragOverListener!);
  web.document.addEventListener('dragleave', _dragLeaveListener!);
  web.document.addEventListener('drop', _dropListener!);
}

void teardownWebDragDrop() {
  if (_dragOverListener != null) {
    web.document.removeEventListener('dragover', _dragOverListener!);
    _dragOverListener = null;
  }
  if (_dragLeaveListener != null) {
    web.document.removeEventListener('dragleave', _dragLeaveListener!);
    _dragLeaveListener = null;
  }
  if (_dropListener != null) {
    web.document.removeEventListener('drop', _dropListener!);
    _dropListener = null;
  }
}

void setupWebPasteHandler({required WebDropCallback onPaste}) {
  teardownWebPasteHandler();
  _pasteListener = (web.Event e) {
    final ce = e as web.ClipboardEvent;
    final items = ce.clipboardData?.items;
    if (items == null) return;
    for (int i = 0; i < items.length; i++) {
      final item = items.item(i);
      if (item == null) continue;
      if (item.type.startsWith('image/')) {
        e.preventDefault();
        final file = item.getAsFile();
        if (file == null) continue;
        final reader = web.FileReader();
        final ext = item.type.split('/').last;
        final fileName = 'pasted_image.$ext';
        reader.onloadend = (web.Event ev) {
          final result = reader.result;
          if (result != null) {
            final arrayBuf = result as JSArrayBuffer;
            final bytes = arrayBuf.toDart.asUint8List();
            onPaste(bytes, fileName);
          }
        }.toJS;
        reader.readAsArrayBuffer(file);
      }
    }
  }.toJS;
  web.document.addEventListener('paste', _pasteListener!);
}

void teardownWebPasteHandler() {
  if (_pasteListener != null) {
    web.document.removeEventListener('paste', _pasteListener!);
    _pasteListener = null;
  }
}
