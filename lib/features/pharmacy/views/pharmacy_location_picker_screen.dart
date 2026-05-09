import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:diab_care/core/theme/app_colors.dart';

class PharmacyLocationPickerResult {
  final double latitude;
  final double longitude;

  const PharmacyLocationPickerResult({
    required this.latitude,
    required this.longitude,
  });
}

class PharmacyLocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final bool showAutoButton;
  final String title;
  final String autoButtonLabel;
  final String confirmButtonLabel;
  final String markerTitle;
  final String positionLabel;

  const PharmacyLocationPickerScreen({
    super.key,
    this.initialLocation,
    this.showAutoButton = true,
    this.title = 'Choisir la localisation',
    this.autoButtonLabel = 'Auto',
    this.confirmButtonLabel = 'Confirmer cette position',
    this.markerTitle = 'Position selectionnee',
    this.positionLabel = 'Lat',
  });

  @override
  State<PharmacyLocationPickerScreen> createState() =>
      _PharmacyLocationPickerScreenState();
}

class _PharmacyLocationPickerScreenState
    extends State<PharmacyLocationPickerScreen> {
  static const _defaultCenter = LatLng(36.8065, 10.1815); // Tunis
  static final _tunisiaBounds = LatLngBounds(
    southwest: LatLng(30.0, 7.0),
    northeast: LatLng(37.6, 12.5),
  );
  LatLng? _selected;
  GoogleMapController? _controller;
  bool _loadingCurrent = false;
  bool _myLocationEnabled = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialLocation ?? _defaultCenter;
    _resolveLocationLayerPermission();
  }

  Future<void> _resolveLocationLayerPermission() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;

      final permission = await Geolocator.checkPermission();
      final allowed = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;

      if (!mounted) return;
      setState(() => _myLocationEnabled = allowed);
    } catch (_) {
      // Keep map usable even if permission check fails.
    }
  }

  Future<void> _centerToCurrent() async {
    setState(() => _loadingCurrent = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      if (mounted && !_myLocationEnabled) {
        setState(() => _myLocationEnabled = true);
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(const Duration(seconds: 8));

      final next = LatLng(pos.latitude, pos.longitude);
      if (!_isWithinTunisia(next)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Position detectee hors Tunisie. Placez la position manuellement sur la carte.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        await _controller?.animateCamera(
          CameraUpdate.newLatLngZoom(_defaultCenter, 6.8),
        );
        return;
      }

      if (!mounted) return;
      setState(() => _selected = next);
      await _controller?.animateCamera(CameraUpdate.newLatLngZoom(next, 15));
    } catch (_) {
      // Keep silent and leave map usable for manual selection.
    } finally {
      if (mounted) {
        setState(() => _loadingCurrent = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected ?? _defaultCenter;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: widget.showAutoButton
            ? [
                TextButton.icon(
                  onPressed: _loadingCurrent ? null : _centerToCurrent,
                  icon: _loadingCurrent
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded, size: 16),
                  label: Text(widget.autoButtonLabel),
                ),
              ]
            : null,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: selected,
              zoom: 13,
            ),
            cameraTargetBounds: CameraTargetBounds(_tunisiaBounds),
            myLocationEnabled: _myLocationEnabled,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) => _controller = controller,
            markers: {
              Marker(
                markerId: const MarkerId('picked_location'),
                position: selected,
                infoWindow: InfoWindow(title: widget.markerTitle),
              ),
            },
            onTap: (latLng) {
              if (!_isWithinTunisia(latLng)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez choisir une position en Tunisie.'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              setState(() => _selected = latLng);
            },
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 18,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    '${widget.positionLabel}: ${selected.latitude.toStringAsFixed(6)} • Lng: ${selected.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        PharmacyLocationPickerResult(
                          latitude: selected.latitude,
                          longitude: selected.longitude,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.softGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.check_rounded),
                    label: Text(widget.confirmButtonLabel),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isWithinTunisia(LatLng value) {
    return value.latitude >= _tunisiaBounds.southwest.latitude &&
        value.latitude <= _tunisiaBounds.northeast.latitude &&
        value.longitude >= _tunisiaBounds.southwest.longitude &&
        value.longitude <= _tunisiaBounds.northeast.longitude;
  }
}
