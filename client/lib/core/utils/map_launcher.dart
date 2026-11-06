import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

/// Unified cross-platform map navigation launcher for TapItTrip.
///
/// Reliably directs travelers using:
/// 1. Native map apps (Google Maps app if installed, Apple Maps on iOS, Google Navigation on Android)
/// 2. External browser with Google Maps or Apple Maps
///
/// Prevents unhandled PlatformExceptions and avoids fragile in-app web views for navigation.
class MapLauncher {
  MapLauncher._();

  /// Launches navigation to the destination.
  ///
  /// Can take coordinates ([latitude], [longitude]), a text query or place name ([query]),
  /// or a [rawUrl] (like a stored Google Maps directions link).
  static Future<bool> launchDirections({
    double? latitude,
    double? longitude,
    String? query,
    String? rawUrl,
  }) async {
    // 1. If coordinates or query are provided, format destination
    String? destination;
    if (latitude != null && longitude != null) {
      destination = '$latitude,$longitude';
    } else if (query != null && query.trim().isNotEmpty) {
      destination = query.trim();
    } else if (rawUrl != null && rawUrl.isNotEmpty) {
      return _launchRawMapUrl(rawUrl);
    }

    if (destination == null || destination.isEmpty) {
      return false;
    }

    final encodedDest = Uri.encodeComponent(destination);

    // 2. iOS-specific navigation handlers
    if (!kIsWeb && Platform.isIOS) {
      // a) Try Google Maps app if installed
      final googleMapsAppUri = Uri.parse(
        'comgooglemaps://?daddr=$encodedDest&directionsmode=transit',
      );
      if (await _safeLaunch(
        googleMapsAppUri,
        mode: LaunchMode.externalApplication,
      )) {
        return true;
      }

      // b) Native Apple Maps directions (built into 100% of iPhones & iOS Simulators)
      final appleMapsUri = Uri.parse(
        'https://maps.apple.com/?daddr=$encodedDest&dirflg=d',
      );
      if (await _safeLaunch(
        appleMapsUri,
        mode: LaunchMode.externalApplication,
      )) {
        return true;
      }

      // c) Direct maps:// scheme for Apple Maps
      final appleMapsSchemeUri = Uri.parse('maps://?daddr=$encodedDest');
      if (await _safeLaunch(
        appleMapsSchemeUri,
        mode: LaunchMode.externalApplication,
      )) {
        return true;
      }
    }

    // 3. Android-specific navigation handlers
    if (!kIsWeb && Platform.isAndroid) {
      // a) Native Google Maps navigation intent
      final androidNavUri = Uri.parse('google.navigation:q=$encodedDest');
      if (await _safeLaunch(
        androidNavUri,
        mode: LaunchMode.externalApplication,
      )) {
        return true;
      }

      // b) Native geo: URI
      final geoUri = Uri.parse('geo:0,0?q=$encodedDest');
      if (await _safeLaunch(geoUri, mode: LaunchMode.externalApplication)) {
        return true;
      }
    }

    // 4. Universal fallback: Google Maps Web in external browser
    final webMapsUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$encodedDest',
    );
    if (await _safeLaunch(webMapsUri, mode: LaunchMode.externalApplication)) {
      return true;
    }

    // 5. Last resort fallback: platformDefault
    return await _safeLaunch(webMapsUri, mode: LaunchMode.platformDefault);
  }

  /// Handles raw Google Maps or directions URLs, extracting destination for iOS/Apple Maps if needed.
  static Future<bool> _launchRawMapUrl(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return false;

    // On iOS, extract destination parameter from Google Maps web URLs to launch native Apple Maps
    if (!kIsWeb &&
        Platform.isIOS &&
        (rawUrl.contains('google.com/maps') || rawUrl.contains('goo.gl'))) {
      final dest =
          uri.queryParameters['destination'] ??
          uri.queryParameters['daddr'] ??
          uri.queryParameters['q'];
      if (dest != null && dest.isNotEmpty) {
        return launchDirections(query: dest);
      }
    }

    // Try external application first
    if (await _safeLaunch(uri, mode: LaunchMode.externalApplication)) {
      return true;
    }

    return await _safeLaunch(uri, mode: LaunchMode.platformDefault);
  }

  /// Safely attempts to launch [uri] without letting any exceptions escape.
  static Future<bool> _safeLaunch(Uri uri, {required LaunchMode mode}) async {
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: mode);
      }
      // On some platforms/versions, canLaunchUrl returns false due to package visibility,
      // but launchUrl still succeeds.
      return await launchUrl(uri, mode: mode);
    } catch (_) {
      return false;
    }
  }
}
