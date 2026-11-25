class ExtractedFlightDetails {
  const ExtractedFlightDetails({
    this.airline,
    this.bookingReference,
    this.flightNumber,
    this.originAirport,
    this.destinationAirport,
  });

  final String? airline;
  final String? bookingReference;
  final String? flightNumber;
  final String? originAirport;
  final String? destinationAirport;

  bool get hasContent =>
      airline != null ||
      bookingReference != null ||
      flightNumber != null ||
      originAirport != null ||
      destinationAirport != null;
}

/// Conservative local extraction for pasted flight confirmation text.
/// It never fabricates times, airports, or timezones that were not explicit.
class FlightConfirmationParser {
  const FlightConfirmationParser();

  ExtractedFlightDetails parse(String rawText) {
    final text = rawText.trim();
    if (text.isEmpty) return const ExtractedFlightDetails();

    final reference = RegExp(
      r'(?:booking|reservation|confirmation)(?:\s+(?:reference|code|number|id))?\s*[:#]?\s*([A-Z0-9-]{4,24})',
      caseSensitive: false,
    ).firstMatch(text)?.group(1);
    final flightNumber = RegExp(
      r'\b([A-Z]{2,3}\s?\d{1,4}[A-Z]?)\b',
      caseSensitive: false,
    ).firstMatch(text)?.group(1)?.toUpperCase().replaceAll(' ', '');
    final route = RegExp(
      r'\b([A-Z]{3})\s*(?:→|->|–|-)\s*([A-Z]{3})\b',
      caseSensitive: false,
    ).firstMatch(text);
    final airline = RegExp(
      r'(?:airline|carrier)\s*[:#]?\s*([^\n\r]{2,80})',
      caseSensitive: false,
    ).firstMatch(text)?.group(1)?.trim();

    return ExtractedFlightDetails(
      airline: airline,
      bookingReference: reference?.toUpperCase(),
      flightNumber: flightNumber,
      originAirport: route?.group(1)?.toUpperCase(),
      destinationAirport: route?.group(2)?.toUpperCase(),
    );
  }
}
