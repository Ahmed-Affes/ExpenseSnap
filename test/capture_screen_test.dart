import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_snap/screens/capture_screen.dart';
import 'package:expense_snap/theme/app_theme.dart';

void main() {
  group('CaptureScreen UI tests', () {
    testWidgets('renders all required elements in initial state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const CaptureScreen()),
      );

      // Verify branding and titles
      expect(find.text('ExpenseSnap'), findsOneWidget);
      expect(find.text('Scan a receipt'), findsOneWidget);
      expect(find.text('EXPENSE EXTRACTION'), findsOneWidget);

      // Verify empty upload area
      expect(find.text('No receipt selected yet'), findsOneWidget);
      expect(find.text('JPG or PNG · Max 5 MB'), findsOneWidget);

      // Verify action buttons
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);
      expect(find.text('Analyze Receipt'), findsOneWidget);

      // Verify Analyze button is disabled when no image is selected
      final ElevatedButton analyzeButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Analyze Receipt'),
      );
      expect(analyzeButton.onPressed, isNull);
    });
  });
}
