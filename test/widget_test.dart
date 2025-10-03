import 'package:flutter_test/flutter_test.dart';
import 'package:food_ml/main.dart';

void main() {
  testWidgets('Food ML app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    
    // Verify that the app starts with the home page
    expect(find.text('Smart Food AI'), findsOneWidget);
    expect(find.text('AI-Powered Food Recognition'), findsOneWidget);
  });
}
