import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapittrip/core/config/app_config.dart';
import 'package:tapittrip/core/theme/app_colors.dart';
import 'package:tapittrip/core/theme/app_theme.dart';
import 'package:tapittrip/features/trips/domain/models/planning_mode.dart';
import 'package:tapittrip/features/trips/domain/models/trip.dart';
import 'package:tapittrip/features/trips/presentation/widgets/planning_mode_selector.dart';
import 'package:tapittrip/features/trips/presentation/widgets/trip_card.dart';

void main() {
  group('AppConfig and Environment', () {
    test('default API base URL uses port 8088', () {
      expect(AppConfig.defaultApiBaseUrl, contains('8088'));
      expect(AppConfig.apiBaseUrl, isNotEmpty);
    });
  });

  group('Brand Theme tokens', () {
    test('light theme uses brand Navy primary and Orange secondary', () {
      final theme = AppTheme.light();
      expect(theme.colorScheme.primary, AppColors.navy);
      expect(theme.colorScheme.secondary, AppColors.orange);
    });

    test('dark theme uses matching dark brand tokens', () {
      final theme = AppTheme.dark();
      expect(theme.colorScheme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, const Color(0xFFA6C8FF));
      expect(theme.colorScheme.secondary, const Color(0xFFFF8A3D));
    });
  });

  group('Traveler Inclusivity: Planning Modes (v1.4)', () {
    test('all 4 starting modes are defined with titles and descriptions', () {
      expect(PlanningMode.values.length, 4);
      expect(PlanningMode.values, contains(PlanningMode.diy));
      expect(PlanningMode.values, contains(PlanningMode.existing));
      expect(PlanningMode.values, contains(PlanningMode.guided));
      expect(PlanningMode.values, contains(PlanningMode.simple));

      for (final mode in PlanningMode.values) {
        expect(mode.title, isNotEmpty);
        expect(mode.subtitle, isNotEmpty);
      }
    });

    testWidgets('PlanningModeSelector renders all 4 starting modes', (
      tester,
    ) async {
      PlanningMode selected = PlanningMode.diy;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return PlanningModeSelector(
                  selectedMode: selected,
                  onModeSelected: (m) => setState(() => selected = m),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Choose your planning style'), findsOneWidget);
      expect(find.text('DIY Planner'), findsOneWidget);
      expect(find.text('Already-Booked'), findsOneWidget);
      expect(find.text('Guided Tour'), findsOneWidget);
      expect(find.text('Simple / Essentials'), findsOneWidget);

      // Select Already-Booked mode
      await tester.tap(find.text('Already-Booked'));
      await tester.pumpAndSettle();

      expect(selected, PlanningMode.existing);
    });
  });

  group('TripCard Widget', () {
    testWidgets('renders trip information and planning mode badge', (
      tester,
    ) async {
      const trip = Trip(
        id: '0194e1e8-7a54-7f12-8809-56cb2f2fa41e',
        ownerId: '0194e1e8-0000-0000-0000-000000000001',
        title: 'Japan Cherry Blossom Journey',
        startDate: '2026-04-01',
        endDate: '2026-04-15',
        destinationCountry: 'JP',
        tripType: 'leisure',
        planningMode: PlanningMode.diy,
      );

      bool tapped = false;
      bool deleted = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: TripCard(
              trip: trip,
              onTap: () => tapped = true,
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );

      expect(find.text('Japan Cherry Blossom Journey'), findsOneWidget);
      expect(find.text('2026-04-01 – 2026-04-15'), findsOneWidget);
      expect(find.text('JP'), findsOneWidget);
      expect(find.text('DIY Planner'), findsOneWidget);
      expect(find.text('LEISURE'), findsOneWidget);

      await tester.tap(find.text('Japan Cherry Blossom Journey'));
      expect(tapped, isTrue);

      await tester.tap(find.byTooltip('Delete trip'));
      expect(deleted, isTrue);
    });
  });
}
