class AirportTerminal {
  const AirportTerminal({
    required this.id,
    required this.airportId,
    required this.name,
    required this.code,
  });

  final String id;
  final String airportId;
  final String name;
  final String code;

  factory AirportTerminal.fromJson(Map<String, dynamic> json) {
    return AirportTerminal(
      id: (json['id'] as String?) ?? (json['code'] as String? ?? ''),
      airportId: (json['airport_id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      code: (json['code'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'airport_id': airportId, 'name': name, 'code': code};
  }
}
