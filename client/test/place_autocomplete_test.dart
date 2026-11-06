import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapittrip/core/theme/app_theme.dart';
import 'package:tapittrip/features/itinerary/data/itinerary_repository.dart';
import 'package:tapittrip/features/itinerary/domain/models/place.dart';
import 'package:tapittrip/features/itinerary/presentation/providers/itinerary_provider.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/place_autocomplete_field.dart';

const suggestion = Place(
  id: 'place-1',
  name: 'Sample Hotel',
  formattedAddress: '10 Example Street',
);

class FakePlaceSearchRepository implements ItineraryRepository {
  final queries = <String>[];

  @override
  Future<List<Place>> searchPlaces(String query) async {
    queries.add(query);
    return [suggestion];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final isAddress in [false, true]) {
    testWidgets('suggestions render and select in address mode $isAddress', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final repository = FakePlaceSearchRepository();
      Place? selected;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            itineraryRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: PlaceAutocompleteField(
                controller: controller,
                labelText: isAddress ? 'Address' : 'Place',
                prefixIcon: Icons.place,
                isAddressField: isAddress,
                onPlaceSelected: (place) => selected = place,
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'Sample');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(repository.queries, ['Sample']);
      expect(tester.takeException(), isNull);
      expect(find.byType(ListTile), findsOneWidget);
      expect(find.text(suggestion.formattedAddress!), findsOneWidget);
      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      expect(selected, same(suggestion));
      expect(
        controller.text,
        isAddress ? suggestion.formattedAddress : suggestion.name,
      );
      expect(find.byType(ListTile), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
