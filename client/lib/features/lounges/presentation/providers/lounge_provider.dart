import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/lounge_repository.dart';
import '../../domain/models/airport.dart';

final loungeRepositoryProvider = Provider<LoungeRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LoungeRepository(apiClient: apiClient);
});

enum WorldRegion {
  popular('Global Hubs'),
  asia('Asia & Pacific'),
  europe('Europe'),
  americas('Americas'),
  middleEast('Middle East & Africa');

  const WorldRegion(this.label);
  final String label;
}

class SelectedRegionNotifier extends Notifier<WorldRegion> {
  @override
  WorldRegion build() => WorldRegion.popular;

  void select(WorldRegion region) => state = region;
}

final selectedRegionProvider =
    NotifierProvider<SelectedRegionNotifier, WorldRegion>(
      SelectedRegionNotifier.new,
    );

class AirportSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String q) => state = q;
}

final airportSearchQueryProvider =
    NotifierProvider<AirportSearchQueryNotifier, String>(
      AirportSearchQueryNotifier.new,
    );

final globalAirportsProvider = FutureProvider<List<Airport>>((ref) async {
  final repository = ref.watch(loungeRepositoryProvider);
  final query = ref.watch(airportSearchQueryProvider);
  return repository.getGlobalAirports(query: query.isEmpty ? null : query);
});

class SelectedAirportIataNotifier extends Notifier<String> {
  @override
  String build() => 'MNL';

  void setIata(String iata) => state = iata.toUpperCase();
}

final selectedAirportIataProvider =
    NotifierProvider<SelectedAirportIataNotifier, String>(
      SelectedAirportIataNotifier.new,
    );

class SelectedTerminalFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void selectTerminal(String? terminal) => state = terminal;
}

final selectedTerminalFilterProvider =
    NotifierProvider<SelectedTerminalFilterNotifier, String?>(
      SelectedTerminalFilterNotifier.new,
    );

class SelectedAirsideFilterNotifier extends Notifier<bool?> {
  @override
  bool? build() => null;

  void setAirside(bool? isAirside) => state = isAirside;
}

final selectedAirsideFilterProvider =
    NotifierProvider<SelectedAirsideFilterNotifier, bool?>(
      SelectedAirsideFilterNotifier.new,
    );

final airportLoungesProvider = FutureProvider<LoungeSearchResult>((ref) async {
  final repository = ref.watch(loungeRepositoryProvider);
  final iata = ref.watch(selectedAirportIataProvider);
  final terminal = ref.watch(selectedTerminalFilterProvider);
  final airside = ref.watch(selectedAirsideFilterProvider);

  return repository.searchLounges(iata, terminal: terminal, isAirside: airside);
});
