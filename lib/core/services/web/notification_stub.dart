// Stub for non-web platforms

Future<bool> requestNotificationPermission() async => false;

void showBrowserNotification(String title, String body) {
  // No-op on non-web
}

void playNotificationSound() {
  // No-op on non-web
}
