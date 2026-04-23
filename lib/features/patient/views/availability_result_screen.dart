import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class AvailabilityResultScreen extends StatelessWidget {
  final String medicationName;
  final double patientLatitude;
  final double patientLongitude;
  final List<Map<String, dynamic>> pharmacies;

  const AvailabilityResultScreen({
    super.key,
    required this.medicationName,
    required this.patientLatitude,
    required this.patientLongitude,
    required this.pharmacies,
  });

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
      case 'accepted':
        return Colors.green;
      case 'unavailable':
      case 'declined':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return 'Disponible';
      case 'unavailable':
        return 'Non disponible';
      case 'declined':
        return 'Refusee';
      default:
        return 'En attente';
    }
  }

  double? _latitude(Map<String, dynamic> p) {
    final value = p['latitude'];
    if (value is num) return value.toDouble();

    final coords = p['pharmacyCoordinates'];
    if (coords is List && coords.length >= 2) {
      final lat = coords[1];
      if (lat is num) return lat.toDouble();
    }

    return null;
  }

  double? _longitude(Map<String, dynamic> p) {
    final value = p['longitude'];
    if (value is num) return value.toDouble();

    final coords = p['pharmacyCoordinates'];
    if (coords is List && coords.length >= 2) {
      final lng = coords[0];
      if (lng is num) return lng.toDouble();
    }

    return null;
  }

  Future<void> _openGoogleMaps(
    BuildContext context,
    Map<String, dynamic> pharmacy,
  ) async {
    final lat = _latitude(pharmacy);
    final lng = _longitude(pharmacy);

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coordonnees indisponibles pour cette pharmacie.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );

    final launched = await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir Google Maps.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showNavigationOptions(
    BuildContext context,
    Map<String, dynamic> pharmacy,
  ) async {
    final name = pharmacy['pharmacyName']?.toString() ?? 'Pharmacie';

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Itineraire vers $name',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choisissez votre application de navigation.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.map_rounded,
                    color: AppColors.softGreen,
                  ),
                  title: const Text('Ouvrir Google Maps'),
                  subtitle: const Text('Navigation externe sur le telephone'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _openGoogleMaps(context, pharmacy);
                  },
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      foregroundColor: AppColors.textPrimary,
                    ),
                    child: const Text('Annuler'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientMarker = Marker(
      markerId: const MarkerId('patient'),
      position: LatLng(patientLatitude, patientLongitude),
      infoWindow: const InfoWindow(title: 'Votre position'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    );

    final pharmacyMarkers = pharmacies.map((p) {
      final lat = _latitude(p);
      final lng = _longitude(p);
      if (lat == null || lng == null) return null;

      final name = p['pharmacyName']?.toString() ?? 'Pharmacie';
      final status = p['status']?.toString() ?? 'pending';
      final distance = p['distanceKm'];
      final distanceLabel = distance is num
          ? '${distance.toStringAsFixed(1)} km'
          : 'Distance inconnue';

      return Marker(
        markerId: MarkerId('pharmacy_${p['pharmacyId']}'),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(
          title: name,
          snippet: '${_statusLabel(status)} • $distanceLabel',
        ),
      );
    }).whereType<Marker>().toSet();

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Pharmacies contactées'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppColors.cardShadow,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.medication_liquid_rounded,
                  color: AppColors.softGreen,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    medicationName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 260,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(patientLatitude, patientLongitude),
                zoom: 12.5,
              ),
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              markers: {patientMarker, ...pharmacyMarkers},
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: pharmacies.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off_rounded,
                            size: 56,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Aucune pharmacie trouvee dans le rayon configure.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Essayez a nouveau plus tard ou augmentez le rayon de recherche.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: pharmacies.length,
                    itemBuilder: (_, i) {
                      final p = pharmacies[i];
                      final name = p['pharmacyName']?.toString() ?? 'Pharmacie';
                      final address = p['pharmacyAddress']?.toString() ?? '';
                      final status = p['status']?.toString() ?? 'pending';
                      final distanceValue = p['distanceKm'];
                      final distanceLabel = distanceValue is num
                          ? '${distanceValue.toStringAsFixed(1)} km'
                          : 'Distance inconnue';
                      final badgeColor = _statusColor(status);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: AppColors.cardShadow,
                          border: Border.all(color: AppColors.border.withOpacity(0.6)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _statusLabel(status),
                                    style: TextStyle(
                                      color: badgeColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              address.isNotEmpty ? address : 'Adresse indisponible',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.near_me_rounded,
                                  size: 16,
                                  color: AppColors.softGreen,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$distanceLabel away',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                const Spacer(),
                                TextButton.icon(
                                  onPressed: () => _showNavigationOptions(context, p),
                                  icon: const Icon(
                                    Icons.alt_route_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('Itineraire'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.softGreen,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
