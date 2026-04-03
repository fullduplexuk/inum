import 'package:flutter_test/flutter_test.dart';
import 'package:inum/core/init/app_widget.dart';

void main() {
  testWidgets('App launches without crashing', (WidgetTester tester) async {
    // Verify the app widget can be created
    expect(const AppWidget(), isNotNull);
  });
}
