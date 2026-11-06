class ExtractedStayDetails {
  const ExtractedStayDetails({
    this.name,
    this.stayType = 'hotel',
    this.address,
    this.checkInAt,
    this.checkOutAt,
    this.bookingReference,
    this.phone,
    this.notes,
  });

  final String? name;
  final String stayType;
  final String? address;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final String? bookingReference;
  final String? phone;
  final String? notes;

  bool get hasContent =>
      name != null ||
      bookingReference != null ||
      checkInAt != null ||
      address != null;
}

class BookingConfirmationParser {
  const BookingConfirmationParser();

  /// Parse raw booking confirmation text from emails, receipts, or OCR.
  ExtractedStayDetails parse(String rawText) {
    if (rawText.trim().isEmpty) {
      return const ExtractedStayDetails();
    }

    final lines = rawText.split(RegExp(r'\r?\n'));
    String? name;
    String stayType = 'hotel';
    String? address;
    DateTime? checkInAt;
    DateTime? checkOutAt;
    String? bookingReference;
    String? phone;

    // Detect stay type
    final lowerText = rawText.toLowerCase();
    if (lowerText.contains('airbnb') ||
        lowerText.contains('apartment') ||
        lowerText.contains('villa') ||
        lowerText.contains('vacation rental')) {
      stayType = 'rental';
    } else if (lowerText.contains('hostel') || lowerText.contains('capsule')) {
      stayType = 'hostel';
    }

    // 1. Booking Reference / Confirmation code
    final refRegex = RegExp(
      r'(?:booking\s+confirmation|confirmation(?:\s+code|\s+number)?|booking(?:\s+reference|\s+id|\s+number)?|reservation(?:\s+number|\s+code)?|ref(?:erence)?)\s*[:#]?\s*([A-Za-z0-9\-_]{4,24})',
      caseSensitive: false,
    );
    final refMatch = refRegex.firstMatch(rawText);
    if (refMatch != null) {
      bookingReference = refMatch.group(1)?.trim();
    }

    // 2. Hotel / Stay Name
    final nameRegex = RegExp(
      r'(?:hotel|property|accommodation|resort|welcome\s+to|reservation\s+(?:at|for))[:\s]+([^\n\r,]+)',
      caseSensitive: false,
    );
    final nameMatch = nameRegex.firstMatch(rawText);
    if (nameMatch != null) {
      name = nameMatch.group(1)?.trim();
    } else {
      // If no label, look for first non-empty line that doesn't look like generic header
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.length > 3 &&
            !trimmed.toLowerCase().startsWith('booking') &&
            !trimmed.toLowerCase().startsWith('reservation') &&
            !trimmed.toLowerCase().startsWith('confirmation') &&
            !trimmed.toLowerCase().startsWith('dear') &&
            !trimmed.contains('@') &&
            !trimmed.contains('http')) {
          name = trimmed;
          break;
        }
      }
    }

    // 3. Address
    final addressRegex = RegExp(
      r'(?:address|location)[:\s]+([^\n\r]+)',
      caseSensitive: false,
    );
    final addressMatch = addressRegex.firstMatch(rawText);
    if (addressMatch != null) {
      address = addressMatch.group(1)?.trim();
    }

    // 4. Phone
    final phoneRegex = RegExp(
      r'(?:phone|tel|contact)[:\s]+([+0-9\s()-]{8,20})',
      caseSensitive: false,
    );
    final phoneMatch = phoneRegex.firstMatch(rawText);
    if (phoneMatch != null) {
      phone = phoneMatch.group(1)?.trim();
    }

    // 5. Check-in Date
    final checkInRegex = RegExp(
      r'(?:check[\s-]?in|arrival|from)[:\s]+([A-Za-z0-9,\s/-]{6,30})',
      caseSensitive: false,
    );
    final checkInMatch = checkInRegex.firstMatch(rawText);
    if (checkInMatch != null) {
      checkInAt = _parseDateString(checkInMatch.group(1)?.trim() ?? '');
    }

    // 6. Check-out Date
    final checkOutRegex = RegExp(
      r'(?:check[\s-]?out|departure|until|to)[:\s]+([A-Za-z0-9,\s/-]{6,30})',
      caseSensitive: false,
    );
    final checkOutMatch = checkOutRegex.firstMatch(rawText);
    if (checkOutMatch != null) {
      checkOutAt = _parseDateString(checkOutMatch.group(1)?.trim() ?? '');
    }

    // 7. Alternative range match: "Dates: May 12, 2026 - May 18, 2026"
    if (checkInAt == null && checkOutAt == null) {
      final datesRegex = RegExp(
        r'(?:dates?)[:\s]+([A-Za-z0-9,\s]+?)\s*(?:-|to|–)\s*([A-Za-z0-9,\s]+)',
        caseSensitive: false,
      );
      final datesMatch = datesRegex.firstMatch(rawText);
      if (datesMatch != null) {
        checkInAt = _parseDateString(datesMatch.group(1)?.trim() ?? '');
        checkOutAt = _parseDateString(datesMatch.group(2)?.trim() ?? '');
      }
    }

    return ExtractedStayDetails(
      name: name,
      stayType: stayType,
      address: address,
      checkInAt: checkInAt,
      checkOutAt: checkOutAt,
      bookingReference: bookingReference,
      phone: phone,
      notes: 'Imported from confirmation email/ticket.',
    );
  }

  DateTime? _parseDateString(String dateStr) {
    final cleaned = dateStr
        .replaceAll(RegExp(r'\(.*?\)|from|until', caseSensitive: false), '')
        .trim();

    // Try ISO format
    final direct = DateTime.tryParse(cleaned);
    if (direct != null) return direct;

    // Month name regex: "May 12, 2026" or "12 May 2026"
    final months = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };

    final monthNamePattern = RegExp(
      r'([A-Za-z]{3,9})\s+(\d{1,2})(?:st|nd|rd|th)?,?\s*(\d{4})?',
      caseSensitive: false,
    );
    final mMatch = monthNamePattern.firstMatch(cleaned);
    if (mMatch != null) {
      final monthStr = mMatch.group(1)!.substring(0, 3).toLowerCase();
      final month = months[monthStr];
      final day = int.tryParse(mMatch.group(2) ?? '');
      final year = int.tryParse(mMatch.group(3) ?? '') ?? DateTime.now().year;
      if (month != null && day != null) {
        return DateTime(year, month, day);
      }
    }

    // Day Month Year pattern: "12 May 2026"
    final dayMonthPattern = RegExp(
      r'(\d{1,2})(?:st|nd|rd|th)?\s+([A-Za-z]{3,9}),?\s*(\d{4})?',
      caseSensitive: false,
    );
    final dmMatch = dayMonthPattern.firstMatch(cleaned);
    if (dmMatch != null) {
      final day = int.tryParse(dmMatch.group(1) ?? '');
      final monthStr = dmMatch.group(2)!.substring(0, 3).toLowerCase();
      final month = months[monthStr];
      final year = int.tryParse(dmMatch.group(3) ?? '') ?? DateTime.now().year;
      if (month != null && day != null) {
        return DateTime(year, month, day);
      }
    }

    return null;
  }
}
