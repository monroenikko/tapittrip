import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/airport.dart';
import '../providers/lounge_provider.dart';
import '../widgets/lounge_card.dart';

class AirportLoungeFinderPage extends ConsumerStatefulWidget {
  const AirportLoungeFinderPage({
    super.key,
    this.initialIata,
    this.initialTerminal,
  });

  final String? initialIata;
  final String? initialTerminal;

  @override
  ConsumerState<AirportLoungeFinderPage> createState() =>
      _AirportLoungeFinderPageState();
}

class _AirportLoungeFinderPageState
    extends ConsumerState<AirportLoungeFinderPage> {
  late final TextEditingController _searchController;
  WorldRegion _selectedRegion = WorldRegion.popular;
  List<Airport> _suggestions = [];

  static const Map<WorldRegion, List<({String iata, String name, String city})>>
  _regionAirports = {
    WorldRegion.popular: [
      (iata: 'HND', name: 'Tokyo Haneda', city: 'Tokyo'),
      (iata: 'SIN', name: 'Singapore Changi', city: 'Singapore'),
      (iata: 'DXB', name: 'Dubai International', city: 'Dubai'),
      (iata: 'LHR', name: 'London Heathrow', city: 'London'),
      (iata: 'CDG', name: 'Paris Charles de Gaulle', city: 'Paris'),
      (iata: 'JFK', name: 'New York JFK', city: 'New York'),
      (iata: 'BKK', name: 'Bangkok Suvarnabhumi', city: 'Bangkok'),
      (iata: 'ICN', name: 'Seoul Incheon', city: 'Seoul'),
      (iata: 'SYD', name: 'Sydney Kingsford Smith', city: 'Sydney'),
      (iata: 'MNL', name: 'Manila Ninoy Aquino', city: 'Manila'),
    ],
    WorldRegion.asia: [
      (iata: 'HND', name: 'Tokyo Haneda', city: 'Tokyo'),
      (iata: 'NRT', name: 'Tokyo Narita', city: 'Tokyo'),
      (iata: 'KIX', name: 'Kansai Osaka', city: 'Osaka'),
      (iata: 'SIN', name: 'Singapore Changi', city: 'Singapore'),
      (iata: 'BKK', name: 'Bangkok Suvarnabhumi', city: 'Bangkok'),
      (iata: 'ICN', name: 'Seoul Incheon', city: 'Seoul'),
      (iata: 'HKG', name: 'Hong Kong International', city: 'Hong Kong'),
      (iata: 'TPE', name: 'Taiwan Taoyuan', city: 'Taipei'),
      (iata: 'KUL', name: 'Kuala Lumpur', city: 'Kuala Lumpur'),
      (iata: 'MNL', name: 'Manila Ninoy Aquino', city: 'Manila'),
      (iata: 'CEB', name: 'Cebu Mactan', city: 'Cebu'),
      (iata: 'DPS', name: 'Bali Ngurah Rai', city: 'Bali'),
    ],
    WorldRegion.europe: [
      (iata: 'LHR', name: 'London Heathrow', city: 'London'),
      (iata: 'LGW', name: 'London Gatwick', city: 'London'),
      (iata: 'CDG', name: 'Paris CDG', city: 'Paris'),
      (iata: 'AMS', name: 'Amsterdam Schiphol', city: 'Amsterdam'),
      (iata: 'FRA', name: 'Frankfurt Airport', city: 'Frankfurt'),
      (iata: 'MUC', name: 'Munich Airport', city: 'Munich'),
      (iata: 'MAD', name: 'Madrid Barajas', city: 'Madrid'),
      (iata: 'BCN', name: 'Barcelona El Prat', city: 'Barcelona'),
      (iata: 'FCO', name: 'Rome Fiumicino', city: 'Rome'),
      (iata: 'ZRH', name: 'Zurich Airport', city: 'Zurich'),
      (iata: 'IST', name: 'Istanbul Airport', city: 'Istanbul'),
    ],
    WorldRegion.americas: [
      (iata: 'JFK', name: 'New York JFK', city: 'New York'),
      (iata: 'LAX', name: 'Los Angeles International', city: 'Los Angeles'),
      (iata: 'SFO', name: 'San Francisco International', city: 'San Francisco'),
      (iata: 'ORD', name: 'Chicago O\'Hare', city: 'Chicago'),
      (iata: 'MIA', name: 'Miami International', city: 'Miami'),
      (iata: 'ATL', name: 'Atlanta Hartsfield', city: 'Atlanta'),
      (iata: 'DFW', name: 'Dallas/Fort Worth', city: 'Dallas'),
      (iata: 'YYZ', name: 'Toronto Pearson', city: 'Toronto'),
      (iata: 'YVR', name: 'Vancouver International', city: 'Vancouver'),
      (iata: 'MEX', name: 'Mexico City', city: 'Mexico City'),
      (iata: 'GRU', name: 'São Paulo Guarulhos', city: 'São Paulo'),
    ],
    WorldRegion.middleEast: [
      (iata: 'DXB', name: 'Dubai International', city: 'Dubai'),
      (iata: 'DOH', name: 'Doha Hamad', city: 'Doha'),
      (iata: 'AUH', name: 'Abu Dhabi Zayed', city: 'Abu Dhabi'),
      (iata: 'RUH', name: 'Riyadh King Khalid', city: 'Riyadh'),
      (iata: 'SYD', name: 'Sydney Kingsford Smith', city: 'Sydney'),
      (iata: 'MEL', name: 'Melbourne Tullamarine', city: 'Melbourne'),
      (iata: 'AKL', name: 'Auckland International', city: 'Auckland'),
      (iata: 'JNB', name: 'Johannesburg O.R. Tambo', city: 'Johannesburg'),
      (iata: 'CAI', name: 'Cairo International', city: 'Cairo'),
    ],
  };

  @override
  void initState() {
    super.initState();
    final initial = widget.initialIata ?? 'MNL';
    _searchController = TextEditingController(text: initial);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedAirportIataProvider.notifier).setIata(initial);
      if (widget.initialTerminal != null) {
        ref
            .read(selectedTerminalFilterProvider.notifier)
            .selectTerminal(widget.initialTerminal);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) async {
    final clean = value.trim();
    if (clean.length >= 2) {
      final repo = ref.read(loungeRepositoryProvider);
      final results = await repo.getGlobalAirports(query: clean);
      if (mounted) {
        setState(() {
          _suggestions = results.take(5).toList();
        });
      }
    } else {
      if (_suggestions.isNotEmpty && mounted) {
        setState(() {
          _suggestions = [];
        });
      }
    }
  }

  void _selectAirport(String iata) {
    final clean = iata.trim().toUpperCase();
    if (clean.isNotEmpty) {
      setState(() {
        _searchController.text = clean;
        _suggestions = [];
      });
      ref.read(selectedTerminalFilterProvider.notifier).selectTerminal(null);
      ref.read(selectedAirportIataProvider.notifier).setIata(clean);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedIata = ref.watch(selectedAirportIataProvider);
    final selectedTerminal = ref.watch(selectedTerminalFilterProvider);
    final isAirside = ref.watch(selectedAirsideFilterProvider);
    final loungesAsync = ref.watch(airportLoungesProvider);

    final currentAirports = _regionAirports[_selectedRegion] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Airport Lounges'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(airportLoungesProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Global Airport Search & Region Selector
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: colorScheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Search city, airport name, or IATA (e.g. LHR, Tokyo, DXB)...',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(Icons.flight_takeoff_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _suggestions = []);
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.45,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: _onSearchChanged,
                  onSubmitted: _selectAirport,
                ),

                // Live Suggestions overlay if user is searching
                if (_suggestions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _suggestions.map((apt) {
                        return ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              apt.iataCode,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          title: Text(
                            apt.name,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          subtitle: Text(
                            '${apt.city}, ${apt.country} • ${apt.terminals.length} Terminals',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          onTap: () => _selectAirport(apt.iataCode),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                // World Region Filter Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: WorldRegion.values.map((region) {
                      final isSelected = _selectedRegion == region;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(region.label),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedRegion = region;
                                _suggestions = [];
                              });
                            }
                          },
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 8),

                // Airport Quick Selector Chips for the Active Region
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: currentAirports.map((item) {
                      final isSelected = selectedIata == item.iata;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text('${item.iata} (${item.city})'),
                          onSelected: (_) => _selectAirport(item.iata),
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Lounge List with Airport Overview & Terminal Filters
          Expanded(
            child: loungesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Airport not found',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Could not load lounges for airport code "$selectedIata". Tap another airport or check the search query.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              data: (result) {
                final terminals = result.airport.terminals;

                return Column(
                  children: [
                    // Airport Overview Card
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.flight_rounded, size: 16),
                                const SizedBox(height: 2),
                                Text(
                                  result.airport.iataCode,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  result.airport.name,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${result.airport.city}, ${result.airport.country} • ${terminals.length} Terminal${terminals.length == 1 ? '' : 's'}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Terminal Filter Chips Row
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChip(
                              label: const Text('All Terminals'),
                              selected: selectedTerminal == null,
                              onSelected: (_) {
                                ref
                                    .read(
                                      selectedTerminalFilterProvider.notifier,
                                    )
                                    .selectTerminal(null);
                              },
                              visualDensity: VisualDensity.compact,
                            ),
                            ...terminals.map((t) {
                              final isSelected = selectedTerminal == t.code;
                              return Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: FilterChip(
                                  label: Text(t.code),
                                  tooltip: t.name,
                                  selected: isSelected,
                                  onSelected: (_) {
                                    ref
                                        .read(
                                          selectedTerminalFilterProvider
                                              .notifier,
                                        )
                                        .selectTerminal(
                                          isSelected ? null : t.code,
                                        );
                                  },
                                  visualDensity: VisualDensity.compact,
                                ),
                              );
                            }),
                            const SizedBox(width: 8),
                            FilterChip(
                              avatar: Icon(
                                isAirside == true
                                    ? Icons.check
                                    : Icons.lock_outline,
                                size: 14,
                              ),
                              label: const Text('Airside Only'),
                              selected: isAirside == true,
                              onSelected: (val) {
                                ref
                                    .read(
                                      selectedAirsideFilterProvider.notifier,
                                    )
                                    .setAirside(val ? true : null);
                              },
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (result.isFromCache)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        color: Colors.amber.withValues(alpha: 0.15),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.offline_bolt_outlined,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Viewing cached directory offline',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Lounges List
                    Expanded(
                      child: result.lounges.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.airline_seat_recline_extra_outlined,
                                      size: 48,
                                      color: colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No lounges found',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'No accessible lounges match the selected terminal or area.',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: result.lounges.length,
                              itemBuilder: (ctx, index) {
                                final lounge = result.lounges[index];
                                return LoungeCard(lounge: lounge);
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
