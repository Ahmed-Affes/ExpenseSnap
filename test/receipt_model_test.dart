import 'package:flutter_test/flutter_test.dart';
import 'package:expense_snap/models/receipt.dart';

void main() {
  group('ReceiptCategory', () {
    test('fromString maps standard strings accurately', () {
      expect(ReceiptCategory.fromString('food'), ReceiptCategory.food);
      expect(
        ReceiptCategory.fromString('Groceries'),
        ReceiptCategory.groceries,
      );
      expect(
        ReceiptCategory.fromString('transport'),
        ReceiptCategory.transport,
      );
      expect(
        ReceiptCategory.fromString('utilities'),
        ReceiptCategory.utilities,
      );
      expect(
        ReceiptCategory.fromString('entertainment'),
        ReceiptCategory.entertainment,
      );
      expect(ReceiptCategory.fromString('health'), ReceiptCategory.health);
      expect(ReceiptCategory.fromString('shopping'), ReceiptCategory.shopping);
    });

    test('fromString handles unknown or null strings safely', () {
      expect(ReceiptCategory.fromString(null), ReceiptCategory.other);
      expect(ReceiptCategory.fromString(''), ReceiptCategory.other);
      expect(
        ReceiptCategory.fromString('unknown_category_xyz'),
        ReceiptCategory.other,
      );
    });

    test('displayName and icon are defined for all categories', () {
      for (final cat in ReceiptCategory.values) {
        expect(cat.displayName.isNotEmpty, isTrue);
        expect(cat.icon, isNotNull);
      }
    });
  });

  group('Receipt Model', () {
    test('fromJson and toJson roundtrip', () {
      final json = {
        'id': 'rec_123',
        'createdAt': '2026-11-13T20:30:00.000Z',
        'merchant': 'Monoprix',
        'date': '2026-11-13',
        'amount': 45.75,
        'currency': 'TND',
        'category': 'groceries',
        'confidence': 0.95,
      };

      final receipt = Receipt.fromJson(json);

      expect(receipt.id, 'rec_123');
      expect(receipt.createdAt, isNotNull);
      expect(receipt.merchant, 'Monoprix');
      expect(receipt.date, '2026-11-13');
      expect(receipt.amount, 45.75);
      expect(receipt.currency, 'TND');
      expect(receipt.category, ReceiptCategory.groceries);
      expect(receipt.confidence, 0.95);

      final exportedJson = receipt.toJson();
      expect(exportedJson['merchant'], 'Monoprix');
      expect(exportedJson['amount'], 45.75);
      expect(exportedJson['category'], 'groceries');
      expect(exportedJson['id'], 'rec_123');
    });

    test('fromJson handles null id and createdAt for unsaved receipts', () {
      final json = {
        'merchant': 'Carrefour Express',
        'date': '2026-11-12',
        'amount': 18.5,
        'currency': 'TND',
        'category': 'food',
        'confidence': 0.88,
      };

      final receipt = Receipt.fromJson(json);

      expect(receipt.id, isNull);
      expect(receipt.createdAt, isNull);
      expect(receipt.merchant, 'Carrefour Express');
      expect(receipt.amount, 18.5);
      expect(receipt.category, ReceiptCategory.food);
    });

    test('ReceiptList.fromJson handles items and total correctly', () {
      final json = {
        'items': [
          {
            'id': '1',
            'merchant': 'Cafe De Paris',
            'date': '2026-11-01',
            'amount': 6.5,
            'currency': 'TND',
            'category': 'food',
          },
          {
            'id': '2',
            'merchant': 'Shell Station',
            'date': '2026-11-02',
            'amount': 50.0,
            'currency': 'TND',
            'category': 'transport',
          },
        ],
        'total': 56.5,
      };

      final list = ReceiptList.fromJson(json);

      expect(list.items.length, 2);
      expect(list.total, 56.5);
      expect(list.items[0].merchant, 'Cafe De Paris');
      expect(list.items[1].category, ReceiptCategory.transport);
    });
  });
}
