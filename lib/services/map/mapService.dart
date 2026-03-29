import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:inhabit_realties/models/address/Address.dart';

class MapService {
  static const String _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  static const String _osrmBaseUrl = 'https://router.project-osrm.org';

  /// Get current user location
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // Check if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        return null;
      }

      // Check location permissions
      permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Try to get current position with timeout
      Position? position;

      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        );
        return position;
      } catch (e) {
        // Fallback to last known location
        try {
          position = await Geolocator.getLastKnownPosition();
          if (position != null) {
            return position;
          }
        } catch (e2) {
          // Continue to next fallback
        }

        // If both fail, try with lower accuracy
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 10),
          );
          return position;
        } catch (e3) {
          // Continue to return null
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get coordinates from Address model (use only lat/lng, no geocoding)
  static Future<LatLng?> getCoordinatesFromAddress(Address address) async {
    if (address.location.lat != 0 && address.location.lng != 0) {
      return LatLng(address.location.lat, address.location.lng);
    } else {
      return null;
    }
  }

  /// Get route between two points
  static Future<Map<String, dynamic>?> getRoute(
    LatLng start,
    LatLng end,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_osrmBaseUrl/route/v1/driving/'
          '${start.longitude},${start.latitude};'
          '${end.longitude},${end.latitude}'
          '?overview=full&geometries=geojson',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          return {
            'geometry': route['geometry'],
            'distance': route['distance'], // in meters
            'duration': route['duration'], // in seconds
            'steps': route['legs'][0]['steps'],
          };
        }
      }
    } catch (e) {
      // Error handled silently
    }
    return null;
  }

  /// Calculate distance between two points
  static double calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  /// Format distance for display
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Format duration for display
  static String formatDuration(double durationInSeconds) {
    final hours = (durationInSeconds / 3600).floor();
    final minutes = ((durationInSeconds % 3600) / 60).round();

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Get address from coordinates
  static Future<String?> getAddressFromCoordinates(LatLng coordinates) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        coordinates.latitude,
        coordinates.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks[0];
        return '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}';
      }
    } catch (e) {
      // Error handled silently
    }
    return null;
  }

  /// Get coordinates from address search string
  static Future<LatLng?> getCoordinatesFromAddressString(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        return LatLng(location.latitude, location.longitude);
      }
    } catch (e) {
      // Error handled silently
    }
    return null;
  }
}
