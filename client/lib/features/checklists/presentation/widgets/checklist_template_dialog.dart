import 'package:flutter/material.dart';

class ChecklistTemplateDialog extends StatelessWidget {
  const ChecklistTemplateDialog({super.key, required this.onSelectTemplate});

  final Future<void> Function(String templateKey) onSelectTemplate;

  static final List<Map<String, dynamic>> templates = [
    {
      'key': 'all_essentials',
      'title': 'Trip Packing Essentials',
      'subtitle': 'Comprehensive 31-item pack covering documents, electronics, clothing & toiletries.',
      'icon': Icons.all_inclusive_rounded,
      'color': Colors.deepPurple,
      'count': 31,
    },
    {
      'key': 'international_essentials',
      'title': 'International Essentials',
      'subtitle': 'Passport, foreign currency, travel cards, plug adapters & prescriptions.',
      'icon': Icons.flight_takeoff_rounded,
      'color': Colors.blue,
      'count': 10,
    },
    {
      'key': 'electronics_gear',
      'title': 'Electronics & Tech',
      'subtitle':
          'Power banks, chargers, headphones, travel adapters & cables.',
      'icon': Icons.devices_other_rounded,
      'color': Colors.amber,
      'count': 7,
    },
    {
      'key': 'clothing_apparel',
      'title': 'Clothing & Apparel',
      'subtitle': 'Versatile layers, tops, walking shoes & weather gear.',
      'icon': Icons.checkroom_rounded,
      'color': Colors.teal,
      'count': 7,
    },
    {
      'key': 'toiletries_health',
      'title': 'Toiletries & Health',
      'subtitle': 'TSA liquids, hygiene essentials, first aid & personal meds.',
      'icon': Icons.medical_services_rounded,
      'color': Colors.pinkAccent,
      'count': 7,
    },
    {
      'key': 'departure_day',
      'title': 'Departure Day Checklist',
      'subtitle': 'Pre-flight door checks, passport in hand, luggage weighing & empty water bottles.',
      'icon': Icons.door_front_door_outlined,
      'color': Colors.orange,
      'count': 6,
    },
    {
      'key': 'return_trip',
      'title': 'Return Trip Checklist',
      'subtitle': 'Hotel room safe check, key drop-off, souvenirs, liquids repacked & return transit.',
      'icon': Icons.flight_land_rounded,
      'color': Colors.indigo,
      'count': 6,
    },
  ];

  static Future<void> show(
    BuildContext context, {
    required Future<void> Function(String templateKey) onSelectTemplate,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) =>
          ChecklistTemplateDialog(onSelectTemplate: onSelectTemplate),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Starter Packing Packs',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Choose a template to quickly bootstrap your list.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ...templates.map((tpl) {
                final key = tpl['key'] as String;
                final title = tpl['title'] as String;
                final subtitle = tpl['subtitle'] as String;
                final icon = tpl['icon'] as IconData;
                final color = (tpl['color'] ?? colorScheme.primary) as Color;
                final count = tpl['count'] as int;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () async {
                        Navigator.of(context).pop();
                        await onSelectTemplate(key);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(icon, color: color, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorScheme.secondaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '$count items',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme
                                                .onSecondaryContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitle,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
