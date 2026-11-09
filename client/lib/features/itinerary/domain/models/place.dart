class Place {
  const Place({
    required this.id,
    required this.name,
    this.provider = 'manual',
    this.providerPlaceId,
    this.formattedAddress,
    this.countryCode,
    this.latitude,
    this.longitude,
    this.photoReference,
    this.attribution,
    this.googleMapsUrl,
  });

  final String id;
  final String name;
  final String provider;
  final String? providerPlaceId;
  final String? formattedAddress;
  final String? countryCode;
  final double? latitude;
  final double? longitude;
  final String? photoReference;
  final String? attribution;
  final String? googleMapsUrl;

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] as String,
      name: json['name'] as String,
      provider: json['provider'] as String? ?? 'manual',
      providerPlaceId: json['provider_place_id'] as String?,
      formattedAddress: json['formatted_address'] as String?,
      countryCode: json['country_code'] as String?,
      latitude: json['latitude'] is num
          ? (json['latitude'] as num).toDouble()
          : double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: json['longitude'] is num
          ? (json['longitude'] as num).toDouble()
          : double.tryParse(json['longitude']?.toString() ?? ''),
      photoReference: json['photo_reference'] as String?,
      attribution: json['attribution'] as String?,
      googleMapsUrl: json['google_maps_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'provider': provider,
      if (providerPlaceId != null) 'provider_place_id': providerPlaceId,
      if (formattedAddress != null) 'formatted_address': formattedAddress,
      if (countryCode != null) 'country_code': countryCode,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (photoReference != null) 'photo_reference': photoReference,
      if (attribution != null) 'attribution': attribution,
      if (googleMapsUrl != null) 'google_maps_url': googleMapsUrl,
    };
  }
}
