import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapittrip/core/theme/app_theme.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/add_activity_bottom_sheet.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('activity sheet has opaque surface with keyboard, dark=$dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: dark ? AppTheme.dark() : AppTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => AddActivityBottomSheet(
                      tripId: 'trip-1',
                      onSubmit: ({
                        required title,
                        required kind,
                        tripDayId,
                        inlinePlace,
                        notes,
                      }) async {},
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final surface = find.byKey(const ValueKey('activity-sheet-surface'));
      final material = tester.widget<Material>(surface);
      expect(material.color!.a, 1);
      expect(
        material.color,
        (dark ? AppTheme.dark() : AppTheme.light()).colorScheme.surface,
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Add Activity'),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .getBottomRight(find.widgetWithText(FilledButton, 'Add Activity'))
            .dy,
        lessThanOrEqualTo(420),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
