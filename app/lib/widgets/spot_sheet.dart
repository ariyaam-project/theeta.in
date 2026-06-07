import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/reel.dart';
import '../state/app_state.dart';
import '../theme.dart';

const _purple = Color(0xFF8B80D6);
const _soft = Color(0xFFECE9FB);

String spotName(Reel r) =>
    r.restaurant?.name ?? r.locationExtraction?.restaurantName ?? 'Spot pending';

String spotPlace(Reel r) =>
    [r.restaurant?.area, r.restaurant?.city].whereType<String>().join(', ');

bool spotLocated(Reel r) =>
    r.restaurant?.lat != null && r.restaurant?.lng != null;

Future<void> _openReel(Reel r) =>
    launchUrl(Uri.parse(r.url), mode: LaunchMode.externalApplication);

Future<void> _openMaps(Reel r) async {
  final lat = r.restaurant?.lat, lng = r.restaurant?.lng;
  // Use exact coords when resolved, else search by name + area.
  final query = (lat != null && lng != null)
      ? '$lat,$lng'
      : [spotName(r), spotPlace(r)].where((s) => s.isNotEmpty).join(' ');
  if (query.isEmpty) return;
  await launchUrl(
    Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    ),
    mode: LaunchMode.externalApplication,
  );
}

/// Action sheet for a saved spot — open reel, open in maps, remove.
void showSpotSheet(BuildContext context, AppState state, Reel r) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        20 + MediaQuery.of(ctx).viewPadding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            spotName(r),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: ink,
            ),
          ),
          if (spotPlace(r).isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 16, color: Colors.black45),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    spotPlace(r),
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          _btn(Icons.open_in_new, 'Open reel', _purple, () {
            Navigator.pop(ctx);
            _openReel(r);
          }),
          const SizedBox(height: 10),
          _btn(Icons.directions_outlined, 'Directions', peach, () {
            Navigator.pop(ctx);
            _openMaps(r);
          }),
          const SizedBox(height: 10),
          _btn(Icons.delete_outline, 'Remove', _soft, () {
            Navigator.pop(ctx);
            state.remove(r);
          }),
        ],
      ),
    ),
  );
}

Widget _btn(IconData icon, String label, Color color, VoidCallback onTap) {
  final fg = color == _purple ? Colors.white : ink;
  return SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: fg,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: onTap,
      icon: Icon(icon, color: fg, size: 20),
      label: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 15),
      ),
    ),
  );
}
