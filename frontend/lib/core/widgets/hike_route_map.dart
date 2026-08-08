import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../features/hikes/data/models/waypoint.dart';
import '../theme/app_colors.dart';
import '../theme/app_shapes.dart';

const _tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const _userAgent = 'com.blablacamp.app';

/// Inline route preview (non-interactive) that opens a full-screen interactive
/// map on tap. Renders a polyline through [waypoints] with numbered markers.
class HikeRouteMap extends StatelessWidget {
  const HikeRouteMap({super.key, required this.waypoints, this.height = 240});

  final List<Waypoint> waypoints;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (waypoints.isEmpty) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: AppShapes.leaf,
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            _MapBody(waypoints: waypoints, interactive: false),
            // Tap veil → open full-screen interactive map.
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openFull(context),
                ),
              ),
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: _Pill(
                icon: Icons.open_in_full,
                label: 'Відкрити карту',
                onTap: () => _openFull(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFull(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: AppColors.ink,
        appBar: AppBar(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.cream,
          elevation: 0,
          title: Text('Маршрут',
              style: GoogleFonts.manrope(
                  fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        body: _MapBody(waypoints: waypoints, interactive: true),
      ),
    ));
  }
}

class _MapBody extends StatelessWidget {
  const _MapBody({required this.waypoints, required this.interactive});
  final List<Waypoint> waypoints;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final points = waypoints.map((w) => LatLng(w.lat, w.lng)).toList();
    return FlutterMap(
      options: MapOptions(
        initialCameraFit: points.length > 1
            ? CameraFit.coordinates(
                coordinates: points,
                padding: const EdgeInsets.all(48),
              )
            : null,
        initialCenter: points.first,
        initialZoom: points.length > 1 ? 11 : 13,
        interactionOptions: InteractionOptions(
          flags: interactive
              ? InteractiveFlag.all & ~InteractiveFlag.rotate
              : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: _tileUrl,
          userAgentPackageName: _userAgent,
        ),
        if (points.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: points,
                strokeWidth: 4,
                color: AppColors.accent,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            for (var i = 0; i < waypoints.length; i++)
              Marker(
                point: points[i],
                width: 30,
                height: 30,
                child: _Pin(
                  index: i,
                  isStart: i == 0,
                  isEnd: i == waypoints.length - 1,
                ),
              ),
          ],
        ),
        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution('© OpenStreetMap'),
          ],
        ),
      ],
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({required this.index, required this.isStart, required this.isEnd});
  final int index;
  final bool isStart;
  final bool isEnd;

  @override
  Widget build(BuildContext context) {
    final color = isStart
        ? const Color(0xFF47725B)
        : isEnd
            ? AppColors.accent
            : AppColors.ink;
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.cream, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        isStart
            ? Icons.flag
            : isEnd
                ? Icons.terrain
                : Icons.circle,
        size: isStart || isEnd ? 15 : 8,
        color: AppColors.cream,
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 16, color: AppColors.textPrimary),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ]),
        ),
      ),
    );
  }
}
