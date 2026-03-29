import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:inhabit_realties/constants/contants.dart';
import 'package:inhabit_realties/services/map/mapService.dart';
import 'package:inhabit_realties/pages/widgets/appSpinner.dart';

class LocationPickerPage extends StatefulWidget {
  final LatLng? initialLocation;
  final String? initialAddress;

  const LocationPickerPage({
    Key? key,
    this.initialLocation,
    this.initialAddress,
  }) : super(key: key);

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    // 1. Check if we have an explicit initial location
    if (widget.initialLocation != null) {
      setState(() {
        _selectedLocation = widget.initialLocation;
        _isLoading = false;
      });
      return;
    }

    // 2. Try to get current GPS location
    try {
      final position = await MapService.getCurrentLocation();
      if (position != null) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      // Continue to next fallback
    }

    // 3. Try to geocode the initial address if provided
    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      try {
        final location = await MapService.getCoordinatesFromAddressString(
            widget.initialAddress!);
        if (location != null) {
          setState(() {
            _selectedLocation = location;
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        // Continue to next fallback
      }
    }

    // 4. Ultimate fallback to India (or Maharashtra area as user previously saw)
    setState(() {
      _selectedLocation = const LatLng(19.0760, 72.8777); // Default to Mumbai as a better fallback
      _isLoading = false;
    });
  }

  void _handleTap(TapPosition tapPosition, LatLng latLng) {
    setState(() {
      _selectedLocation = latLng;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_selectedLocation != null)
            TextButton(
              onPressed: () => Navigator.pop(context, _selectedLocation),
              child: const Text(
                'Confirm',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      backgroundColor: backgroundColor,
      body: _isLoading
          ? const Center(child: AppSpinner())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedLocation!,
                    initialZoom: 15,
                    onTap: _handleTap,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: isDark
                          ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                          : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.inhabit.realties',
                      maxZoom: 19,
                      subdomains: isDark ? ['a', 'b', 'c', 'd'] : ['a', 'b', 'c'],
                    ),
                    if (_selectedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLocation!,
                            width: 50,
                            height: 50,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black87 : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(51), // 0.2 * 255
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Text(
                      'Tap on the map to select the property location.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final position = await MapService.getCurrentLocation();
          if (position != null) {
            final newLocation = LatLng(position.latitude, position.longitude);
            _mapController.move(newLocation, _mapController.camera.zoom);
            setState(() {
              _selectedLocation = newLocation;
            });
          }
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
