import 'package:flutter/widgets.dart';

/// Feature copy follows the resolved app locale, with English fallback.
class RecommendationsStrings {
  const RecommendationsStrings(this.locale);
  final Locale locale;
  bool get _filipino =>
      locale.languageCode == 'fil' || locale.languageCode == 'tl';

  String get empty => _filipino
      ? 'Magdagdag ng aktibidad para makita rito ang mga plano at mungkahi. Maaari pa ring gamitin ang biyahe nang walang itinerary.'
      : 'Add an activity to see itinerary highlights and suggestions here. You can still use your trip without an itinerary.';
  String get plannedHeading =>
      _filipino ? 'Mula sa iyong itinerary' : 'From your itinerary';
  String get planned => _filipino ? 'Nakaplano na' : 'Already planned';
  String get viewPlace => _filipino ? 'Tingnan ang lugar' : 'View place';
  String get directions => _filipino ? 'Mga direksyon' : 'Directions';
  String get linkError => _filipino
      ? 'Hindi mabuksan ang mapa. Subukang muli.'
      : 'Could not open maps. Please try again.';
  String get suggestedHeading => _filipino
      ? 'Mga mungkahi para sa iyong biyahe'
      : 'Suggested for your trip';
  String get loading => _filipino
      ? 'Naghahanap ng mga ideya batay sa iyong itinerary…'
      : 'Finding ideas based on your itinerary…';
  String get error => _filipino
      ? 'Hindi makuha ang mga mungkahi. Makikita pa rin sa itaas ang naka-save mong itinerary. Kumonekta sa internet at subukang muli.'
      : 'Suggestions are unavailable. Your saved itinerary is still shown above. Connect to the internet and try again.';
  String get retry => _filipino ? 'Subukang muli' : 'Retry suggestions';
  String get aiSource => _filipino
      ? 'Mga ideya mula sa AI • Suriin ang mga detalye bago magplano.'
      : 'AI-generated ideas • Check details before making plans.';
  String get fallbackSource => _filipino
      ? 'Walang mungkahi mula sa AI sa ngayon. Pangkalahatang ideya sa pagpaplano ang anumang mungkahi sa ibaba.'
      : 'AI suggestions are unavailable. Any ideas below are general planning suggestions.';
  String get noSuggestions => _filipino
      ? 'Wala pang karagdagang mungkahi.'
      : 'No additional suggestions yet.';
  String get advisory => _filipino
      ? 'Mga mungkahi lamang ito at hindi pa naidagdag sa iyong itinerary.'
      : 'Suggestions are advisory and have not been added to your itinerary.';
}
