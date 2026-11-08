import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final _popularAirports = [
    'MNL',
    'NRT',
    'HND',
    'SIN',
    'BKK',
    'ICN',
    'SFO',
    'LAX',
  ];

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

  void _onSearchSubmitted(String value) {
    final clean = value.trim().toUpperCase();
    if (clean.isNotEmpty) {
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

    return Scaffold(
      appBar: AppBar(title: const Text('Airport Lounges')),
      body: Column(
        children: [
          // Airport Search & Quick Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: colorScheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Search Airport IATA (e.g. MNL, NRT, SIN)...',
                    prefixIcon: const Icon(Icons.flight_takeoff_rounded),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search_rounded),
                      onPressed: () =>
                          _onSearchSubmitted(_searchController.text),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: _onSearchSubmitted,
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _popularAirports.map((iata) {
                      final isSelected = selectedIata == iata;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(iata),
                          onSelected: (_) {
                            _searchController.text = iata;
                            _onSearchSubmitted(iata);
                          },
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

          // Lounge List with Terminal Filters
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
                        'We could not find lounges for airport code "$selectedIata". Please check the IATA code and try again.',
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
                    // Terminal & Zone Filter Row
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
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

                    // Results
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
