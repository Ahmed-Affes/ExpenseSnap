import 'package:flutter_test/flutter_test.dart';
import 'package:expense_snap/main.dart';

void main() {
  testWidgets('ExpenseSnap basic smoke test', (WidgetTester tester) async {
    // Build the ExpenseSnap app
    await tester.pumpWidget(const ExpenseSnapApp());

    // Verify Capture and History tabs exist
    expect(find.text('Capture'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);

    // Initial screen should be Capture
    expect(find.text('Capture Receipt'), findsOneWidget);

    // Tap on History tab in bottom navigation bar
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    // Verify History screen is displayed
    expect(find.text('Expense History'), findsAtLeastNWidgets(1));
  });
}
