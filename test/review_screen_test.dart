import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_snap/models/receipt.dart';
import 'package:expense_snap/screens/review_screen.dart';
import 'package:expense_snap/theme/app_theme.dart';

void main() {
  group('ReviewScreen Form & Pre-fill Tests', () {
    const sampleReceipt = Receipt(
      id: 'rec_100',
      merchant: 'Monoprix City',
      date: '2026-11-12',
      amount: 45.50,
      currency: 'TND',
      category: ReceiptCategory.groceries,
      confidence: 0.95,
    );

    testWidgets('pre-fills all form fields from provided Receipt', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ReviewScreen(receipt: sampleReceipt),
        ),
      );

      // Verify header
      expect(find.text('Review receipt'), findsOneWidget);
      expect(
        find.text('Check the extracted details before saving.'),
        findsOneWidget,
      );

      // Verify pre-filled inputs
      expect(
        find.widgetWithText(TextFormField, 'Monoprix City'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextFormField, '2026-11-12'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '45.50'), findsOneWidget);
      expect(find.text('Groceries'), findsAtLeastNWidgets(1));

      // Confidence >= 0.7 should NOT show warning banner
      expect(
        find.text(
          'Some details may be inaccurate. Please review them carefully.',
        ),
        findsNothing,
      );
      expect(find.text('Extraction confidence: 95%'), findsOneWidget);

      // Verify action buttons exist
      expect(find.text('Save Receipt'), findsOneWidget);
      expect(find.text('Discard & Retake'), findsOneWidget);
    });

    testWidgets('shows warning banner when confidence is below 0.7', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const lowConfidenceReceipt = Receipt(
        merchant: 'Unknown Market',
        date: '2026-11-10',
        amount: 12.00,
        currency: 'TND',
        category: ReceiptCategory.other,
        confidence: 0.62,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ReviewScreen(receipt: lowConfidenceReceipt),
        ),
      );

      // Subtle warning banner must appear
      expect(
        find.text(
          'Some details may be inaccurate. Please review them carefully.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.text('Extraction confidence: 62%'), findsOneWidget);
    });
  });

  group('ReviewScreen Form Validation Tests', () {
    testWidgets('rejects empty merchant name', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const sampleReceipt = Receipt(
        merchant: '',
        date: '2026-11-12',
        amount: 25.0,
        currency: 'TND',
        category: ReceiptCategory.food,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ReviewScreen(receipt: sampleReceipt),
        ),
      );

      // Tap Save
      final saveButtonFinder = find.text('Save Receipt');
      await tester.ensureVisible(saveButtonFinder);
      await tester.tap(saveButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('Merchant name cannot be empty'), findsOneWidget);
    });

    testWidgets('rejects zero or negative amount', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const sampleReceipt = Receipt(
        merchant: 'Carrefour',
        date: '2026-11-12',
        amount: 0.0,
        currency: 'TND',
        category: ReceiptCategory.shopping,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ReviewScreen(receipt: sampleReceipt),
        ),
      );

      final saveButtonFinder = find.text('Save Receipt');
      await tester.ensureVisible(saveButtonFinder);
      await tester.tap(saveButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('Enter amount'), findsOneWidget);

      // Enter 0 and verify 'Must be > 0'
      final amountFieldFinder = find.byType(TextFormField).at(2);
      await tester.enterText(amountFieldFinder, '0');
      await tester.tap(saveButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('Must be > 0'), findsOneWidget);
    });

    testWidgets('allows editing merchant and category fields', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const sampleReceipt = Receipt(
        merchant: 'Store A',
        date: '2026-11-12',
        amount: 10.0,
        currency: 'TND',
        category: ReceiptCategory.other,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ReviewScreen(receipt: sampleReceipt),
        ),
      );

      // Edit merchant
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Store A'),
        'Store B New',
      );
      await tester.pump();

      expect(find.text('Store B New'), findsOneWidget);
    });
  });
}
