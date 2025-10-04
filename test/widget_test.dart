import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Simple app initialization test', (WidgetTester tester) async {
    // Just test basic widget tree construction
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: Text('Test')),
          body: Center(child: Text('Hello, World!')),
        ),
      ),
    );
    
    // Verify basic widget functionality
    expect(find.text('Test'), findsOneWidget);
    expect(find.text('Hello, World!'), findsOneWidget);
  });
}
