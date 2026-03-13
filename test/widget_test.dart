import 'package:flutter_test/flutter_test.dart';
import 'package:ricewatch/main.dart';

void main() {
  testWidgets('App shows welcome screen with Get Started button', (WidgetTester tester) async {
    await tester.pumpWidget(const RiceWatchApp());
    await tester.pumpAndSettle();

    expect(find.text('Get Started'), findsOneWidget);
  });
}
