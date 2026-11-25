import 'package:flutter_test/flutter_test.dart';

import 'package:tapittrip/core/utils/currency_formatter.dart';
import 'package:tapittrip/features/expenses/data/expense_repository.dart';

void main() {
  group('Currency Minor Units & Zero-Decimal Audit', () {
    test(
      'accurately identifies all standard ISO 4217 zero-decimal currencies',
      () {
        final zeroDecimals = [
          'BIF',
          'CLP',
          'DJF',
          'GNF',
          'ISK',
          'JPY',
          'KMF',
          'KRW',
          'PYG',
          'RWF',
          'UGX',
          'VND',
          'VUV',
          'XAF',
          'XOF',
          'XPF',
        ];

        for (final code in zeroDecimals) {
          expect(
            CurrencyFormatter.isZeroDecimal(code),
            isTrue,
            reason: '$code must be recognized as zero-decimal',
          );
        }

        final standardCurrencies = [
          'USD',
          'EUR',
          'GBP',
          'PHP',
          'SGD',
          'AUD',
          'CAD',
          'HKD',
          'THB',
          'CHF',
          'AED',
          'TWD',
          'IDR',
          'MYR',
        ];

        for (final code in standardCurrencies) {
          expect(
            CurrencyFormatter.isZeroDecimal(code),
            isFalse,
            reason: '$code must be recognized as standard decimal',
          );
        }
      },
    );

    test('formats zero-decimal currencies without fractional cents', () {
      // 1,500 JPY in minor units is 1,500 whole Yen
      expect(
        CurrencyFormatter.formatAmount(1500, 'JPY', isMinor: true),
        '¥1500',
      );

      // 50,000 CLP in minor units is 50,000 whole Pesos
      expect(
        CurrencyFormatter.formatAmount(50000, 'CLP', isMinor: true),
        '\$50000',
      );

      // 13,850 ISK in minor units is 13,850 whole Kronur
      expect(
        CurrencyFormatter.formatAmount(13850, 'ISK', isMinor: true),
        'kr 13850',
      );

      // 25,000 KRW in minor units is 25,000 whole Won
      expect(
        CurrencyFormatter.formatAmount(25000, 'KRW', isMinor: true),
        '₩25000',
      );

      // 100,000 VND in minor units is 100,000 whole Dong
      expect(
        CurrencyFormatter.formatAmount(100000, 'VND', isMinor: true),
        '₫100000',
      );
    });

    test(
      'formats standard 2-decimal currencies dividing minor units by 100',
      () {
        // 1,500 cents USD is $15.00
        expect(
          CurrencyFormatter.formatAmount(1500, 'USD', isMinor: true),
          '\$15.00',
        );

        // 39,800 centavos PHP is ₱398.00
        expect(
          CurrencyFormatter.formatAmount(39800, 'PHP', isMinor: true),
          '₱398.00',
        );

        // 2,550 pence GBP is £25.50
        expect(
          CurrencyFormatter.formatAmount(2550, 'GBP', isMinor: true),
          '£25.50',
        );

        // trimZeroCents removes .00 for whole amounts
        expect(
          CurrencyFormatter.formatAmount(
            2000,
            'USD',
            isMinor: true,
            trimZeroCents: true,
          ),
          '\$20',
        );
        expect(
          CurrencyFormatter.formatAmount(
            2050,
            'USD',
            isMinor: true,
            trimZeroCents: true,
          ),
          '\$20.50',
        );
      },
    );

    test('formats dual currencies accurately across different scales', () {
      // Zero-decimal to 2-decimal: 10,000 JPY to PHP at rate 0.3980 -> 10000 * 0.398 = 3980.00 PHP
      final dualJpyPhp = CurrencyFormatter.formatDual(
        amount: 10000,
        fromCurrency: 'JPY',
        toCurrency: 'PHP',
        rate: 0.3980,
        isMinor: true,
      );
      expect(dualJpyPhp, '¥10000 (≈ ₱3980.00)');

      // 2-decimal to zero-decimal: $50.00 USD (5000 minor) to JPY at rate 155.0 -> 50 * 155 = 7750 JPY
      final dualUsdJpy = CurrencyFormatter.formatDual(
        amount: 5000,
        fromCurrency: 'USD',
        toCurrency: 'JPY',
        rate: 155.0,
        isMinor: true,
      );
      expect(dualUsdJpy, '\$50.00 (≈ ¥7750)');
    });

    test('ExpenseRepository.allocateEqualMinor eliminates rounding drift', () {
      // 100 minor units split equally among 3 travelers -> exactly 100 total
      final threeWay = ExpenseRepository.allocateEqualMinor(100, [
        'u1',
        'u2',
        'u3',
      ]);
      expect(threeWay, {'u1': 34, 'u2': 33, 'u3': 33});
      expect(threeWay.values.fold<int>(0, (a, b) => a + b), 100);

      // 1,000 minor units split equally among 7 travelers -> exactly 1000 total
      final sevenWay = ExpenseRepository.allocateEqualMinor(1000, [
        'u1',
        'u2',
        'u3',
        'u4',
        'u5',
        'u6',
        'u7',
      ]);
      expect(sevenWay.values.fold<int>(0, (a, b) => a + b), 1000);
      expect(sevenWay['u1'], 143);
      expect(sevenWay['u6'], 143);
      expect(sevenWay['u7'], 142);

      // 1 minor unit split among 2 travelers -> 1 and 0, sum is 1
      final oneMinor = ExpenseRepository.allocateEqualMinor(1, ['u1', 'u2']);
      expect(oneMinor, {'u1': 1, 'u2': 0});
      expect(oneMinor.values.fold<int>(0, (a, b) => a + b), 1);
    });
  });
}
