enum PlanningMode {
  diy(
    value: 'diy',
    title: 'DIY Planner',
    subtitle: 'Crafts custom itineraries and explores freely step-by-step',
  ),
  existing(
    value: 'existing',
    title: 'Already-Booked',
    subtitle:
        'Has flights, hotels, or tickets booked; organize them seamlessly',
  ),
  guided(
    value: 'guided',
    title: 'Guided Tour',
    subtitle: 'Package or group tour with scheduled activities and guides',
  ),
  simple(
    value: 'simple',
    title: 'Simple / Essentials',
    subtitle: 'Minimal organization for reminders, stays, and emergency info',
  );

  const PlanningMode({
    required this.value,
    required this.title,
    required this.subtitle,
  });

  final String value;
  final String title;
  final String subtitle;

  static PlanningMode fromString(String? value) {
    return PlanningMode.values.firstWhere(
      (m) => m.value == value,
      orElse: () => PlanningMode.diy,
    );
  }
}
