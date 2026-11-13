import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_snap/models/receipt.dart';
import 'package:expense_snap/screens/history_screen.dart';
import 'package:expense_snap/services/n8n_service.dart';
import 'package:expense_snap/theme/app_theme.dart';

/// Test implementation of N8nService that returns pre-configured responses
class FakeN8nService extends N8nService {
  ReceiptList? mockResponse;
  Exception? mockError;
  String? lastRequestedMonth;

  FakeN8nService({this.mockResponse, this.mockError});

  @override
  Future<ReceiptList> list({String? month}) async {
    lastRequestedMonth = month;
    if (mockError != null) {
      throw mockError!;
    }
    return mockResponse ?? const ReceiptList(items: [], total: 0.0);
  }

  @override
  Future<Receipt> analyze(File image) async {
    throw UnimplementedError();
  }

  @override
  Future<Receipt> save(Receipt receipt) async {
    throw UnimplementedError();
  }
}

void main() {
  group('HistoryScreen UI & Monthly Data Tests', () {
    testWidgets('renders monthly total and receipts when data is returned', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeService = FakeN8nService(
        mockResponse: const ReceiptList(
          items: [
            Receipt(
              id: 'rcp_1',
              merchant: 'MG Supermarket',
              date: '2026-11-13',
              amount: 150.0,
              currency: 'TND',
              category: ReceiptCategory.groceries,
            ),
            Receipt(
              id: 'rcp_2',
              merchant: 'Total Station',
              date: '2026-11-10',
              amount: 50.0,
              currency: 'TND',
              category: ReceiptCategory.transport,
            ),
          ],
          total: 200.0,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: HistoryScreen(service: fakeService),
        ),
      );

      // Await fetch
      await tester.pumpAndSettle();

      // Verify title & summary
      expect(find.text('Expense history'), findsOneWidget);
      expect(find.text('200.000 TND'), findsOneWidget);
      expect(find.text('2 saved receipts'), findsOneWidget);

      // Verify items in list
      expect(find.text('MG Supermarket'), findsOneWidget);
      expect(find.text('Total Station'), findsOneWidget);
      expect(find.text('150.000 TND'), findsOneWidget);
      expect(find.text('50.000 TND'), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
    });

    testWidgets(
      'renders empty state when no expenses exist for selected month',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fakeService = FakeN8nService(
          mockResponse: const ReceiptList(items: [], total: 0.0),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: HistoryScreen(service: fakeService),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('0.000 TND'), findsOneWidget);
        expect(find.text('0 saved receipts'), findsOneWidget);
        expect(find.text('No expenses this month'), findsOneWidget);
        expect(
          find.text('Your saved receipts will appear here.'),
          findsOneWidget,
        );
        expect(find.text('Scan a Receipt'), findsOneWidget);
      },
    );

    testWidgets('renders error state and allows retry on API failure', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeService = FakeN8nService(
        mockError: ReceiptException(
          'Connection timed out. Server unreachable.',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: HistoryScreen(service: fakeService),
        ),
      );

      await tester.pumpAndSettle();

      // Error message & retry button should be visible
      expect(find.text('Failed to load expenses'), findsOneWidget);
      expect(
        find.text('Connection timed out. Server unreachable.'),
        findsOneWidget,
      );
      expect(find.text('Try Again'), findsOneWidget);

      // Fix service and tap retry
      fakeService.mockError = null;
      fakeService.mockResponse = const ReceiptList(
        items: [
          Receipt(
            merchant: 'Resolved Cafe',
            date: '2026-11-01',
            amount: 8.5,
            currency: 'TND',
            category: ReceiptCategory.food,
          ),
        ],
        total: 8.5,
      );

      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      expect(find.text('Resolved Cafe'), findsOneWidget);
      expect(find.text('8.500 TND'), findsNWidgets(2));
    });

    testWidgets('month navigation updates requested month parameter', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeService = FakeN8nService(
        mockResponse: const ReceiptList(items: [], total: 0.0),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: HistoryScreen(service: fakeService),
        ),
      );

      await tester.pumpAndSettle();

      final now = DateTime.now();
      final currentMonthParam =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';
      expect(fakeService.lastRequestedMonth, currentMonthParam);

      // Tap previous month
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      final prev = DateTime(now.year, now.month - 1);
      final prevMonthParam =
          '${prev.year}-${prev.month.toString().padLeft(2, '0')}';
      expect(fakeService.lastRequestedMonth, prevMonthParam);
    });
  });
}
