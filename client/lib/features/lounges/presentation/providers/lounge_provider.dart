import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/lounge_repository.dart';

final loungeRepositoryProvider = Provider<LoungeRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LoungeRepository(apiClient: apiClient);
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
