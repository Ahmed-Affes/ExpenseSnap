import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_snap/models/receipt.dart';
import 'package:expense_snap/screens/capture_screen.dart';
import 'package:expense_snap/screens/review_screen.dart';
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

  group('ReviewScreen placeholder & data display tests', () {
    testWidgets('renders extracted receipt details correctly', (
      WidgetTester tester,
    ) async {
      const testReceipt = Receipt(
        id: 'test_123',
        merchant: 'Monoprix Express',
        date: '2026-11-13',
        amount: 84.50,
        currency: 'TND',
        category: ReceiptCategory.groceries,
        confidence: 0.92,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ReviewScreen(receipt: testReceipt),
        ),
      );

      expect(find.text('Review Receipt'), findsOneWidget);
      expect(find.text('Monoprix Express'), findsOneWidget);
      expect(find.text('2026-11-13'), findsOneWidget);
      expect(find.text('84.50 TND'), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('92.0%'), findsOneWidget);

      // High confidence (>= 0.7) should NOT display warning banner
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });

    testWidgets(
      'shows warning banner when extraction confidence is below 0.7',
      (WidgetTester tester) async {
        const lowConfidenceReceipt = Receipt(
          merchant: 'Faded Shop',
          date: '2026-11-10',
          amount: 15.0,
          currency: 'TND',
          category: ReceiptCategory.other,
          confidence: 0.58,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ReviewScreen(receipt: lowConfidenceReceipt),
          ),
        );

        // Low confidence warning banner should be displayed
        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
        expect(
          find.textContaining('Low confidence extraction (58%)'),
          findsOneWidget,
        );
      },
    );
  });
}
