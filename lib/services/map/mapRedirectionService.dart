import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:inhabit_realties/models/address/Address.dart';
import '../../pages/widgets/appSnackBar.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

class MapRedirectionService {
  /// Static method to build the destination string or coordinates for the URL
  static String _getDestination(Address address) {
    if (address.location.lat != 0.0 && address.location.lng != 0.0) {
      return '${address.location.lat},${address.location.lng}';
    }
    return Uri.encodeComponent(_buildAddressString(address));
  }

  /// Redirect to Google Maps with directions from current location to property
  static Future<bool> redirectToGoogleMaps(Address propertyAddress) async {
    try {
      final destination = _getDestination(propertyAddress);

      // 1. Try Android Native Navigation Scheme
      if (Platform.isAndroid) {
        final androidUrl = Uri.parse('google.navigation:q=$destination&mode=d');
        if (await canLaunchUrl(androidUrl)) {
          return await launchUrl(androidUrl);
        }
      }

      // 2. Try iOS Google Maps App Scheme
      if (Platform.isIOS) {
        final iosUrl = Uri.parse(
            'comgooglemaps://?daddr=$destination&directionsmode=driving');
        if (await canLaunchUrl(iosUrl)) {
          return await launchUrl(iosUrl);
        }
      }

      // 3. Fallback to Universal HTTPS Link
      // We OMIT origin specifically to let the Google Maps app/web use its internal "My Location"
      final url = Uri.parse('https://www.google.com/maps/dir/?api=1'
          '&destination=$destination'
          '&travelmode=driving');

      return await _launchUrl(url);
    } catch (e) {
      return await _redirectToGoogleMapsDestination(propertyAddress);
    }
  }

  /// Redirect to Google Maps showing only the destination (Simpler fallback)
  static Future<bool> _redirectToGoogleMapsDestination(
      Address propertyAddress) async {
    try {
      final destination = _getDestination(propertyAddress);

      // Simple search/view URL
      final url = Uri.parse('https://www.google.com/maps/search/?api=1'
          '&query=$destination');

      return await _launchUrl(url);
    } catch (e) {
      return false;
    }
  }


  /// Redirect to Apple Maps with directions (iOS only)
  static Future<bool> redirectToAppleMaps(Address propertyAddress) async {
    if (!Platform.isIOS) {
      return false; // Apple Maps only available on iOS
    }

    try {
      // Get current location
      final currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final destination = _getDestination(propertyAddress);

      // Create Apple Maps URL with directions
      final url = Uri.parse('http://maps.apple.com/?saddr='
          '${currentPosition.latitude},${currentPosition.longitude}'
          '&daddr=$destination'
          '&dirflg=d' // driving directions
          );

      return await _launchUrl(url);
    } catch (e) {
      // If current location fails, just show the destination
      return await _redirectToAppleMapsDestination(propertyAddress);
    }
  }

  /// Redirect to Apple Maps showing only the destination
  static Future<bool> _redirectToAppleMapsDestination(
      Address propertyAddress) async {
    if (!Platform.isIOS) {
      return false;
    }

    try {
      final destination = _getDestination(propertyAddress);
      final url = Uri.parse('http://maps.apple.com/?q=$destination');

      return await _launchUrl(url);
    } catch (e) {
      return false;
    }
  }

  /// Build address string from Address model
  static String _buildAddressString(Address address) {
    final parts = <String>[];

    if (address.street.isNotEmpty) parts.add(address.street);
    if (address.area.isNotEmpty) parts.add(address.area);
    if (address.city.isNotEmpty) parts.add(address.city);
    if (address.state.isNotEmpty) parts.add(address.state);
    if (address.zipOrPinCode.isNotEmpty) parts.add(address.zipOrPinCode);
    if (address.country.isNotEmpty) parts.add(address.country);

    return parts.join(', ');
  }

  /// Launch URL with error handling
  static Future<bool> _launchUrl(Uri url) async {
    try {
      if (await canLaunchUrl(url)) {
        return await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      }
      return false;
    } catch (e) {
      // Try alternative launch mode for Android
      try {
        return await launchUrl(
          url,
          mode: LaunchMode.platformDefault,
        );
      } catch (e2) {
        return false;
      }
    }
  }

  /// Show map options dialog
  static Future<void> showMapOptions({
    required BuildContext context,
    required Address propertyAddress,
  }) async {
    final isIOS = Platform.isIOS;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'Open in Maps',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),

            // Google Maps option
            ListTile(
              leading: const Icon(Icons.map, color: Colors.red),
              title: const Text('Google Maps'),
              subtitle: const Text('Get directions with Google Maps'),
              onTap: () async {
                Navigator.pop(context);
                final success = await redirectToGoogleMaps(propertyAddress);
                if (!success && context.mounted) {
                  AppSnackBar.showSnackBar(
                    context,
                    'Error',
                    'Could not open Google Maps',
                    ContentType.failure,
                  );
                }
              },
            ),

            // Apple Maps option (iOS only)
            if (isIOS)
              ListTile(
                leading: const Icon(Icons.map_outlined, color: Colors.blue),
                title: const Text('Apple Maps'),
                subtitle: const Text('Get directions with Apple Maps'),
                onTap: () async {
                  Navigator.pop(context);
                  final success = await redirectToAppleMaps(propertyAddress);
                  if (!success && context.mounted) {
                    AppSnackBar.showSnackBar(
                      context,
                      'Error',
                      'Could not open Apple Maps',
                      ContentType.failure,
                    );
                  }
                },
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
