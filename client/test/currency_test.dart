import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapittrip/core/constants/countries.dart';
import 'package:tapittrip/core/network/api_client.dart';
import 'package:tapittrip/core/storage/token_storage.dart';
import 'package:tapittrip/features/auth/domain/models/auth_user.dart';
import 'package:tapittrip/features/auth/presentation/widgets/country_residence_dialog.dart';
import 'package:tapittrip/features/expenses/data/currency_repository.dart';
import 'package:tapittrip/features/expenses/presentation/widgets/add_expense_bottom_sheet.dart';
import 'package:tapittrip/features/trips/domain/models/trip.dart';

class FakeCurrencyApiClient extends ApiClient {
  FakeCurrencyApiClient() : super(tokenStorage: InMemoryTokenStorage());

  dynamic getResponse;
  String? lastGetPath;
  Map<String, dynamic>? lastQueryParams;

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    lastGetPath = path;
    lastQueryParams = queryParameters;

    if (path.contains('/currencies/rates')) {
      final from = queryParameters?['from'] ?? 'USD';
      final to = queryParameters?['to'] ?? 'PHP';
      final rate = from == 'JPY' && to == 'PHP' ? 0.3800 : 58.50;
      return getResponse ??
          {
            'from': from,
            'to': to,
            'rate': rate,
            'reciprocal_rate': rate > 0 ? (1.0 / rate) : 1.0,
            'as_of': '2026-11-08T12:00:00Z',
            'provider': 'test_forex',
          };
    }

    return getResponse ?? {};
  }
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('CountryCurrencyHelper', () {
    test('resolves currencies accurately from country codes and keywords', () {
      expect(CountryCurrencyHelper.resolveCurrency('PH'), 'PHP');
      expect(CountryCurrencyHelper.resolveCurrency('Philippines'), 'PHP');
      expect(CountryCurrencyHelper.resolveCurrency('Manila'), 'PHP');

      expect(CountryCurrencyHelper.resolveCurrency('JP'), 'JPY');
      expect(CountryCurrencyHelper.resolveCurrency('Japan'), 'JPY');
      expect(CountryCurrencyHelper.resolveCurrency('Tokyo, Japan'), 'JPY');

      expect(CountryCurrencyHelper.resolveCurrency('US'), 'USD');
      expect(CountryCurrencyHelper.resolveCurrency('United States'), 'USD');

      expect(CountryCurrencyHelper.resolveCurrency('FR'), 'EUR');
      expect(CountryCurrencyHelper.resolveCurrency('France'), 'EUR');
      expect(CountryCurrencyHelper.resolveCurrency('Paris'), 'EUR');

      expect(CountryCurrencyHelper.resolveCurrency('SG'), 'SGD');
      expect(CountryCurrencyHelper.resolveCurrency('Singapore'), 'SGD');

      expect(CountryCurrencyHelper.resolveCurrency('Myeongdong'), 'KRW');
      expect(CountryCurrencyHelper.resolveCurrency('Korea'), 'KRW');
      expect(CountryCurrencyHelper.resolveCurrency('Seoul'), 'KRW');

      expect(CountryCurrencyHelper.resolveCurrency('Hong Kong'), 'HKD');
      expect(CountryCurrencyHelper.resolveCurrency('迪士尼 Disney'), 'HKD');

      expect(CountryCurrencyHelper.resolveCurrency('BGC Taguig'), 'PHP');

      expect(CountryCurrencyHelper.resolveCurrency(null), 'USD');
      expect(CountryCurrencyHelper.resolveCurrency(''), 'USD');
    });

    test('resolves trip currency dynamically with title, destination, and expense fallbacks', () {
      expect(
        CountryCurrencyHelper.resolveTripCurrency(
          destinationCountry: 'Myeongdong',
          title: 'Korea',
        ),
        'KRW',
      );

      expect(
        CountryCurrencyHelper.resolveTripCurrency(
          destinationCountry: 'Taguig',
          title: 'BGC Staycation',
        ),
        'PHP',
      );

      expect(
        CountryCurrencyHelper.resolveTripCurrency(
          destinationCountry: 'Disneyland',
          title: 'Hong Kong Trip',
        ),
        'HKD',
      );

      // Falls back to title when destination is generic or empty
      expect(
        CountryCurrencyHelper.resolveTripCurrency(
          destinationCountry: 'Grand Hotel',
          title: 'South Korea Winter Tour',
        ),
        'KRW',
      );

      // Falls back to existing logged expenses when country/title are ambiguous
      expect(
        CountryCurrencyHelper.resolveTripCurrency(
          destinationCountry: 'Resort',
          title: 'Summer Getaway',
          expenseCurrencies: ['KRW', 'KRW', 'PHP'],
        ),
        'KRW',
      );

      expect(
        CountryCurrencyHelper.resolveTripCurrency(
          explicitCurrency: 'EUR',
          destinationCountry: null,
          title: null,
        ),
        'EUR',
      );
    });

    test('findByCode returns matching country item', () {
      final ph = CountryCurrencyHelper.findByCode('PH');
      expect(ph?.name, 'Philippines');
      expect(ph?.currency, 'PHP');
      expect(ph?.flag, '🇵🇭');

      final jp = CountryCurrencyHelper.findByCode('JP');
      expect(jp?.name, 'Japan');
      expect(jp?.currency, 'JPY');
      expect(jp?.flag, '🇯🇵');
    });

    test('resolves country flags accurately from country codes, names, and destinations', () {
      expect(CountryCurrencyHelper.resolveFlag('PH'), '🇵🇭');
      expect(CountryCurrencyHelper.resolveFlag('Philippines'), '🇵🇭');
      expect(CountryCurrencyHelper.resolveFlag('BGC Taguig'), '🇵🇭');
      expect(CountryCurrencyHelper.resolveFlag('Manila'), '🇵🇭');

      expect(CountryCurrencyHelper.resolveFlag('JP'), '🇯🇵');
      expect(CountryCurrencyHelper.resolveFlag('Japan'), '🇯🇵');
      expect(CountryCurrencyHelper.resolveFlag('Tokyo, Japan'), '🇯🇵');
      expect(CountryCurrencyHelper.resolveFlag('Hakone'), '🇯🇵');

      expect(CountryCurrencyHelper.resolveFlag('HK'), '🇭🇰');
      expect(CountryCurrencyHelper.resolveFlag('Hong Kong Trip'), '🇭🇰');

      expect(CountryCurrencyHelper.resolveFlag('FR'), '🇫🇷');
      expect(CountryCurrencyHelper.resolveFlag('Paris'), '🇫🇷');

      expect(CountryCurrencyHelper.resolveFlag('US'), '🇺🇸');
      expect(CountryCurrencyHelper.resolveFlag('New York'), '🇺🇸');

      expect(CountryCurrencyHelper.resolveFlag('SG'), '🇸🇬');
      expect(CountryCurrencyHelper.resolveFlag('Singapore'), '🇸🇬');

      expect(CountryCurrencyHelper.resolveFlag('AU'), '🇦🇺');
      expect(CountryCurrencyHelper.resolveFlag('Sydney'), '🇦🇺');

      expect(
        CountryCurrencyHelper.resolveFlag('NZ'),
        '🇳🇿',
      ); // Arbitrary ISO code converts to emoji
      expect(CountryCurrencyHelper.resolveFlag(null), isNull);
      expect(CountryCurrencyHelper.resolveFlag(''), isNull);
    });
  });

  group('Models & Deserialization', () {
    test('AuthUser deserializes homeCountry and homeCurrency correctly', () {
      final user = AuthUser.fromJson({
        'id': 'u-1',
        'name': 'Juan Cruz',
        'display_name': 'Juan',
        'email': 'juan@example.com',
        'home_country': 'PH',
        'home_currency': 'PHP',
      });

      expect(user.homeCountry, 'PH');
      expect(user.homeCurrency, 'PHP');
      expect(user.toJson()['home_country'], 'PH');
      expect(user.toJson()['home_currency'], 'PHP');
    });

    test('Trip deserializes destinationCurrency correctly', () {
      final trip = Trip.fromJson({
        'id': 'trip-tokyo',
        'title': 'Tokyo Adventure',
        'destination_country': 'JP',
        'destination_currency': 'JPY',
      });

      expect(trip.destinationCountry, 'JP');
      expect(trip.destinationCurrency, 'JPY');
      expect(trip.toJson()['destination_currency'], 'JPY');
    });
  });

  group('CurrencyRepository', () {
    test('fetches exchange rates and caches them to secure storage', () async {
      final fakeApi = FakeCurrencyApiClient();
      final repo = CurrencyRepository(apiClient: fakeApi);

      final details = await repo.getRateDetails('JPY', 'PHP');
      expect(details.from, 'JPY');
      expect(details.to, 'PHP');
      expect(details.rate, 0.3800);
      expect(details.provider, 'test_forex');
      expect(fakeApi.lastGetPath, '/currencies/rates');
      expect(fakeApi.lastQueryParams?['from'], 'JPY');
      expect(fakeApi.lastQueryParams?['to'], 'PHP');
    });

    test(
      'returns 1.0 for identical currencies without calling network',
      () async {
        final fakeApi = FakeCurrencyApiClient();
        final repo = CurrencyRepository(apiClient: fakeApi);

        final rate = await repo.getRate('PHP', 'PHP');
        expect(rate, 1.0);
        expect(fakeApi.lastGetPath, isNull);
      },
    );
  });

  group('Widgets & UI Conversion', () {
    testWidgets(
      'AddExpenseBottomSheet auto-selects destination currency and reflects home conversion live',
      (tester) async {
        final fakeApi = FakeCurrencyApiClient();
        final currencyRepo = CurrencyRepository(apiClient: fakeApi);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currencyRepositoryProvider.overrideWithValue(currencyRepo),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: AddExpenseBottomSheet(
                  tripId: 'trip-1',
                  defaultCurrency: 'JPY',
                  homeCurrency: 'PHP',
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Verify currency dropdown pre-selected to JPY
        expect(find.text('JPY'), findsOneWidget);

        // Enter amount in JPY
        await tester.enterText(find.widgetWithText(TextField, '0.00'), '3000');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Expect live conversion pill to appear showing PHP equivalent:
        // 3000 JPY * 0.3800 = ₱1140.00 PHP
        expect(find.textContaining('≈ ₱1140.00 PHP'), findsOneWidget);
        expect(find.textContaining('1 JPY = 0.3800 PHP'), findsOneWidget);
      },
    );

    testWidgets(
      'CountryResidenceDialog displays searchable country list and selects country',
      (tester) async {
        CountryItem? selectedResult;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Builder(
                builder: (context) {
                  return Scaffold(
                    body: Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          selectedResult = await CountryResidenceDialog.show(
                            context,
                          );
                        },
                        child: const Text('Open Dialog'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Country of Residence'), findsOneWidget);
        expect(find.text('Philippines'), findsOneWidget);
        expect(find.text('Japan'), findsOneWidget);

        // Search for Japan
        await tester.enterText(find.byType(TextField), 'Japan');
        await tester.pumpAndSettle();

        expect(find.widgetWithText(ListTile, 'Japan'), findsOneWidget);
        expect(find.widgetWithText(ListTile, 'Philippines'), findsNothing);

        // Tap Japan
        await tester.tap(find.widgetWithText(ListTile, 'Japan'));
        await tester.pumpAndSettle();

        expect(selectedResult?.code, 'JP');
        expect(selectedResult?.currency, 'JPY');
      },
    );
  });
}
