import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/reel.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

/// Map of resolved food spots. Pins come from reels that have coordinates.
class MapTab extends StatelessWidget {
  final AppState state;
  const MapTab({super.key, required this.state});

  // Kerala center — the map is locked to Kerala.
  static const _fallbackCenter = LatLng(10.5, 76.2);

  // Hard pan/zoom bounds around Kerala.
  static final _keralaBounds = LatLngBounds(
    const LatLng(8.0, 74.7),
    const LatLng(12.95, 77.6),
  );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final located = state.located;
        final markers = located
            .map(
              (reel) => Marker(
                point: LatLng(reel.restaurant!.lat!, reel.restaurant!.lng!),
                width: 46,
                height: 46,
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  onTap: () => _showSpot(context, reel),
                  child: const Icon(Icons.location_pin, color: accent, size: 42),
                ),
              ),
            )
            .toList();

        final center = located.isNotEmpty
            ? LatLng(
                located.first.restaurant!.lat!,
                located.first.restaurant!.lng!,
              )
            : _fallbackCenter;

        return Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: located.isEmpty ? 7 : 11,
                minZoom: 6,
                maxZoom: 18,
                cameraConstraint: CameraConstraint.contain(
                  bounds: _keralaBounds,
                ),
              ),
              children: [
                TileLayer(
                  // Stylised, illustrative basemap (CARTO Voyager) — no API key.
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'in.theeta.app',
                ),
                MarkerLayer(markers: markers),
              ],
            ),
            Positioned(
              left: 16,
              top: 16,
              child: ShadowCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Text(
                  located.isEmpty
                      ? 'No located spots yet'
                      : '${located.length} spot${located.length == 1 ? '' : 's'} on map',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            if (located.isEmpty)
              const Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: ShadowCard(
                  child: Text(
                    'Spots appear here once AI resolves a saved reel to a '
                    'restaurant with a location.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showSpot(BuildContext context, Reel reel) {
    final spot = reel.restaurant;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: paper,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: ink, width: 2),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Kicker('Food spot'),
            const SizedBox(height: 8),
            Text(
              spot?.name ?? 'Unnamed spot',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            if (spot?.address != null || spot?.city != null) ...[
              const SizedBox(height: 6),
              Text(
                [spot?.address, spot?.city].whereType<String>().join(', '),
                style: const TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(reel.url),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open reel'),
              ),
            ),
            if (spot?.lat != null && spot?.lng != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse(
                      'https://www.google.com/maps/search/?api=1&query=${spot!.lat},${spot.lng}',
                    ),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Open in Google Maps'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
