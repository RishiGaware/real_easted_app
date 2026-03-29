class Address {
  final String? id;
  final String street;
  final String area;
  final String city;
  final String state;
  final String zipOrPinCode;
  final String country;
  final Location location;

  Address({
    this.id,
    required this.street,
    required this.area,
    required this.city,
    required this.state,
    required this.zipOrPinCode,
    required this.country,
    required this.location,
  });

  /// Deserialize from JSON
  factory Address.fromJson(Map<String, dynamic> json) {
    try {
      return Address(
        id: json['_id']?.toString() ?? '',
        street: json['street']?.toString() ?? '',
        area: json['area']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        state: json['state']?.toString() ?? '',
        zipOrPinCode: json['zipOrPinCode']?.toString() ?? "",
        country: json['country']?.toString() ?? "",
        location: json['location'] != null
            ? Location.fromJson(json['location'] as Map<String, dynamic>)
            : Location(lat: 0, lng: 0),
      );
    } catch (e) {
      // Return a default address if parsing fails
      return Address(
        id: '',
        street: json['street']?.toString() ?? '',
        area: json['area']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        state: json['state']?.toString() ?? '',
        zipOrPinCode: json['zipOrPinCode']?.toString() ?? "",
        country: json['country']?.toString() ?? "",
        location: Location(lat: 0, lng: 0),
      );
    }
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'area': area,
      'city': city,
      'state': state,
      'zipOrPinCode': zipOrPinCode,
      'country': country,
      'location': location.toJson(),
    };
  }

  /// Get full address as string
  String get fullAddress {
    List<String> parts = [];
    if (street.isNotEmpty) parts.add(street);
    if (area.isNotEmpty) parts.add(area);
    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty) parts.add(state);
    if (zipOrPinCode.isNotEmpty) parts.add(zipOrPinCode);
    if (country.isNotEmpty) parts.add(country);
    return parts.join(', ');
  }

  /// Get short address (city, state, country)
  String get shortAddress {
    List<String> parts = [];
    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty) parts.add(state);
    if (country.isNotEmpty) parts.add(country);
    return parts.join(', ');
  }
}

class Location {
  final String? id;
  final double lat;
  final double lng;

  Location({this.id, required this.lat, required this.lng});

  /// Deserialize from JSON
  factory Location.fromJson(Map<String, dynamic> json) {
    try {
      return Location(
        id: json['_id']?.toString() ?? '',
        lat: (json['lat'] ?? 0).toDouble(),
        lng: (json['lng'] ?? 0).toDouble(),
      );
    } catch (e) {
      // Return default location if parsing fails
      return Location(
        id: '',
        lat: 0.0,
        lng: 0.0,
      );
    }
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson() {
    return {'lat': lat, 'lng': lng};
  }
}
