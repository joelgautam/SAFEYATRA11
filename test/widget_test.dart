import 'package:flutter_test/flutter_test.dart';
import 'package:safe_yatra/main.dart';

void main() {
  testWidgets('SafeYatra smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SafeYatraApp());
  });
}
