// Stub for non-web platforms
import 'dart:typed_data';

typedef WebDropCallback = void Function(Uint8List bytes, String fileName);

void setupWebDragDrop({required WebDropCallback onDrop, required void Function(bool) onDragOver}) {
  // No-op on non-web
}

void teardownWebDragDrop() {
  // No-op on non-web
}

void setupWebPasteHandler({required WebDropCallback onPaste}) {
  // No-op on non-web
}

void teardownWebPasteHandler() {
  // No-op on non-web
}
