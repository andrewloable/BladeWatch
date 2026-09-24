import 'package:bladewatch_companion/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the app shell renders its first screen', (tester) async {
    await tester.pumpWidget(const CompanionApp());
    expect(find.text('Pair with your car to get started.'), findsOneWidget);
  });
}
