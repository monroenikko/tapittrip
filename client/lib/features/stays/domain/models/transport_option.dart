import 'package:flutter/material.dart';

import '../../../../core/utils/currency_formatter.dart';
import 'stay.dart';

class TransportOption {
  const TransportOption({
    required this.id,
    required this.mode,
    required this.title,
    required this.provider,
    required this.estimatedDurationMinutes,
    required this.estimatedCostMinor,
    required this.currency,
    required this.transfers,
    required this.walkingMeters,
    required this.luggageCapacity,
    required this.accessibilityNotes,
    this.boardingLocation,
    this.dropoffLocation,
    this.dropoffAddress,
    this.lastMileWalkMeters,
    this.lastMileWalkMinutes,
    this.lastMileDirectionsUrl,
    this.convenienceScore = 0,
    this.isMostConvenient = false,
    this.isFastest = false,
    this.isCheapest = false,
    required this.explanation,
  });

  final String id;
  final String
  mode; // private_transfer, express_rail, public_transit, rideshare
  final String title;
  final String provider;
  final int estimatedDurationMinutes;
  final int estimatedCostMinor;
  final String currency;
  final int transfers;
  final int walkingMeters;
  final String luggageCapacity;
  final String accessibilityNotes;
  final String? boardingLocation;
  final String? dropoffLocation;
  final String? dropoffAddress;
  final int? lastMileWalkMeters;
  final int? lastMileWalkMinutes;
  final String? lastMileDirectionsUrl;
  final int convenienceScore;
  final bool isMostConvenient;
  final bool isFastest;
  final bool isCheapest;
  final String explanation;

  String get formattedCost {
    return CurrencyFormatter.formatAmount(
      estimatedCostMinor,
      currency,
      isMinor: true,
      trimZeroCents: true,
    );
  }

  String get formattedDuration {
    if (estimatedDurationMinutes < 60) {
      return '$estimatedDurationMinutes min';
    }
    final hours = estimatedDurationMinutes ~/ 60;
    final mins = estimatedDurationMinutes % 60;
    return mins == 0 ? '$hours hr' : '$hours hr $mins min';
  }

  IconData get modeIcon {
    switch (mode) {
      case 'express_rail':
        return Icons.train_rounded;
      case 'public_transit':
        return Icons.directions_bus_rounded;
      case 'rideshare':
        return Icons.local_taxi_rounded;
      case 'private_transfer':
      default:
        return Icons.directions_car_rounded;
    }
  }

  factory TransportOption.fromJson(Map<String, dynamic> json) {
    return TransportOption(
      id: json['id'] as String? ?? '',
      mode: json['mode'] as String? ?? 'private_transfer',
      title: json['title'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      estimatedDurationMinutes:
          (json['estimated_duration_minutes'] as num?)?.toInt() ?? 0,
      estimatedCostMinor: (json['estimated_cost_minor'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'USD',
      transfers: (json['transfers'] as num?)?.toInt() ?? 0,
      walkingMeters: (json['walking_meters'] as num?)?.toInt() ?? 0,
      luggageCapacity: json['luggage_capacity'] as String? ?? '',
      accessibilityNotes: json['accessibility_notes'] as String? ?? '',
      boardingLocation: json['boarding_location'] as String?,
      dropoffLocation: json['dropoff_location'] as String?,
      dropoffAddress: json['dropoff_address'] as String?,
      lastMileWalkMeters: (json['last_mile_walk_meters'] as num?)?.toInt(),
      lastMileWalkMinutes: (json['last_mile_walk_minutes'] as num?)?.toInt(),
      lastMileDirectionsUrl: json['last_mile_directions_url'] as String?,
      convenienceScore: (json['convenience_score'] as num?)?.toInt() ?? 0,
      isMostConvenient: json['is_most_convenient'] as bool? ?? false,
      isFastest: json['is_fastest'] as bool? ?? false,
      isCheapest: json['is_cheapest'] as bool? ?? false,
      explanation: json['explanation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mode': mode,
      'title': title,
      'provider': provider,
      'estimated_duration_minutes': estimatedDurationMinutes,
      'estimated_cost_minor': estimatedCostMinor,
      'currency': currency,
      'transfers': transfers,
      'walking_meters': walkingMeters,
      'luggage_capacity': luggageCapacity,
      'accessibility_notes': accessibilityNotes,
      'boarding_location': boardingLocation,
      'dropoff_location': dropoffLocation,
      'dropoff_address': dropoffAddress,
      'last_mile_walk_meters': lastMileWalkMeters,
      'last_mile_walk_minutes': lastMileWalkMinutes,
      'last_mile_directions_url': lastMileDirectionsUrl,
      'convenience_score': convenienceScore,
      'is_most_convenient': isMostConvenient,
      'is_fastest': isFastest,
      'is_cheapest': isCheapest,
      'explanation': explanation,
    };
  }
}

class TransportComparisonResult {
  const TransportComparisonResult({
    required this.verified,
    required this.status,
    required this.message,
    this.origin,
    required this.destination,
    required this.googleMapsDirectionsUrl,
    this.nearestTransit,
    required this.luggagePreset,
    this.partySize = 1,
    this.options = const [],
    required this.providerAttribution,
    required this.lastRefreshedAt,
  });

  final bool verified;
  final String status;
  final String message;
  final String? origin;
  final String destination;
  final String googleMapsDirectionsUrl;
  final NearestTransitInfo? nearestTransit;
  final String luggagePreset;
  final int partySize;
  final List<TransportOption> options;
  final String providerAttribution;
  final DateTime lastRefreshedAt;

  factory TransportComparisonResult.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? [];
    return TransportComparisonResult(
      verified: json['verified'] as bool? ?? false,
      status: json['status'] as String? ?? 'unverified',
      message: json['message'] as String? ?? '',
      origin: json['origin'] as String?,
      destination: json['destination'] as String? ?? '',
      googleMapsDirectionsUrl:
          json['google_maps_directions_url'] as String? ?? '',
      nearestTransit: json['nearest_transit'] != null
          ? NearestTransitInfo.fromJson(
              json['nearest_transit'] as Map<String, dynamic>,
            )
          : null,
      luggagePreset: json['luggage_preset'] as String? ?? 'standard',
      partySize: (json['party_size'] as num?)?.toInt() ?? 1,
      options: rawOptions
          .map((opt) => TransportOption.fromJson(opt as Map<String, dynamic>))
          .toList(),
      providerAttribution: json['provider_attribution'] as String? ?? '',
      lastRefreshedAt:
          DateTime.tryParse(json['last_refreshed_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'verified': verified,
      'status': status,
      'message': message,
      'origin': origin,
      'destination': destination,
      'google_maps_directions_url': googleMapsDirectionsUrl,
      'nearest_transit': nearestTransit?.toJson(),
      'luggage_preset': luggagePreset,
      'party_size': partySize,
      'options': options.map((opt) => opt.toJson()).toList(),
      'provider_attribution': providerAttribution,
      'last_refreshed_at': lastRefreshedAt.toIso8601String(),
    };
  }
}
