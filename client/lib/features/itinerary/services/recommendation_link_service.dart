import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/map_launcher.dart';

final recommendationLinkServiceProvider = Provider(
  (ref) => RecommendationLinkService(),
);

/// Builds trusted map links; provider text is only ever a search parameter.
class RecommendationLinkService {
  static Uri placeUri(String query) => Uri.https(
    'www.google.com',
    '/maps/search/',
    {'api': '1', 'query': query.trim()},
  );

  Future<bool> viewPlace(String query) async {
    final uri = placeUri(query);
    if (query.trim().isEmpty || uri.toString().length > 2048) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  Future<bool> directions(String query) async {
    if (query.trim().isEmpty || placeUri(query).toString().length > 2048) {
      return false;
    }
    return MapLauncher.launchDirections(query: query);
  }
}
