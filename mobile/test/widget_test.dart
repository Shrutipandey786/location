import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('LocationTrackerApp builds cleanly', (WidgetTester tester) async {
    await tester.pumpWidget(const LocationTrackerApp());
    expect(find.byType(LocationTrackerApp), findsOneWidget);
  });
}
