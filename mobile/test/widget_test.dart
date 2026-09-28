import 'package:flutter_test/flutter_test.dart';
import 'package:deliversync_mobile/main.dart';

void main() {
  testWidgets('DeliverSyncApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DeliverSyncApp());
    expect(find.byType(DeliverSyncApp), findsOneWidget);
  });
}
