// lib/presentation/screens/map/map_screen.dart

import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/landmark_entity.dart';
import '../../providers/providers.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  LandmarkEntity? _selectedLandmark;
  Set<Marker> _markers = {};

  static const _initial = CameraPosition(
    target: LatLng(AppConstants.bangladeshLat, AppConstants.bangladeshLon),
    zoom: AppConstants.defaultZoom,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _buildMarkers();
  }

  Future<void> _buildMarkers() async {
    final landmarks = ref.read(filteredLandmarksProvider);
    final markers = <Marker>{};

    for (final l in landmarks) {
      final color = _markerHue(l.score);
      markers.add(Marker(
        markerId: MarkerId(l.id.toString()),
        position: LatLng(l.lat, l.lon),
        icon: BitmapDescriptor.defaultMarkerWithHue(color),
        infoWindow: InfoWindow(title: l.title, snippet: '★ ${l.score.toStringAsFixed(1)}'),
        onTap: () => setState(() => _selectedLandmark = l),
      ));
    }

    if (mounted) setState(() => _markers = markers);
  }

  double _markerHue(double score) {
    if (score >= AppConstants.scoreMid) return BitmapDescriptor.hueGreen;
    if (score >= AppConstants.scoreLow) return BitmapDescriptor.hueYellow;
    return BitmapDescriptor.hueRed;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(filteredLandmarksProvider, (_, __) => _buildMarkers());

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initial,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            onMapCreated: (ctrl) => _mapController = ctrl,
            onTap: (_) => setState(() => _selectedLandmark = null),
            style: _darkMapStyle,
          ),

          // Top bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: _MapTopBar(markerCount: _markers.length),
          ),

          // Bottom detail card
          if (_selectedLandmark != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: _LandmarkDetailCard(
                landmark: _selectedLandmark!,
                onVisit: () async {
                  final msg = await ref
                      .read(landmarkProvider.notifier)
                      .visitLandmark(_selectedLandmark!.id, _selectedLandmark!.title);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(msg)),
                    );
                  }
                },
                onClose: () => setState(() => _selectedLandmark = null),
              ),
            ),

          // My location button
          Positioned(
            bottom: _selectedLandmark != null ? 180 : 80,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'map_location',
              backgroundColor: AppTheme.surfaceCard,
              onPressed: _goToMyLocation,
              child: const Icon(Icons.my_location, color: AppTheme.accent),
            ),
          ),

          // Legend
          Positioned(
            bottom: _selectedLandmark != null ? 180 : 80,
            left: 16,
            child: const _ScoreLegend(),
          ),
        ],
      ),
    );
  }

  Future<void> _goToMyLocation() async {
    final loc = await ref.read(currentLocationProvider.future);
    if (loc != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(loc.latitude, loc.longitude),
          AppConstants.detailZoom,
        ),
      );
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

class _MapTopBar extends StatelessWidget {
  final int markerCount;
  const _MapTopBar({required this.markerCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceElevated),
      ),
      child: Row(
        children: [
          const Icon(Icons.map_rounded, color: AppTheme.accent, size: 20),
          const SizedBox(width: 10),
          Text('Landmark Map',
              style: GoogleFonts.sora(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$markerCount spots',
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 11, color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }
}

class _LandmarkDetailCard extends StatelessWidget {
  final LandmarkEntity landmark;
  final VoidCallback onVisit;
  final VoidCallback onClose;

  const _LandmarkDetailCard({
    required this.landmark,
    required this.onVisit,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceElevated),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (landmark.image != null)
              CachedNetworkImage(
                imageUrl: landmark.image!,
                height: 110,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  height: 110,
                  color: AppTheme.surfaceElevated,
                  child: const Icon(Icons.landscape, color: AppTheme.onSurfaceMuted),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(landmark.title,
                            style: GoogleFonts.sora(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.onSurface)),
                        const SizedBox(height: 4),
                        Text(
                          '${landmark.visitCount} visits · avg ${landmark.avgDistance.toStringAsFixed(1)} km',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 11, color: AppTheme.onSurfaceMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: onVisit,
                        icon: const Icon(Icons.check_circle_outline, size: 15),
                        label: const Text('Visit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: Colors.black,
                          textStyle: GoogleFonts.sora(
                              fontSize: 12, fontWeight: FontWeight.w700),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        onPressed: onClose,
                        icon: const Icon(Icons.close, size: 18),
                        style: IconButton.styleFrom(
                          foregroundColor: AppTheme.onSurfaceMuted,
                          backgroundColor: AppTheme.surfaceElevated,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreLegend extends StatelessWidget {
  const _ScoreLegend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard.withOpacity(0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceElevated),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Score',
              style: GoogleFonts.sora(fontSize: 10, color: AppTheme.onSurfaceMuted)),
          const SizedBox(height: 4),
          _LegendRow(color: AppTheme.scoreHigh, label: '≥ 6.5'),
          _LegendRow(color: AppTheme.scoreMid, label: '3–6.5'),
          _LegendRow(color: AppTheme.scoreLow, label: '< 3'),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendRow({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 10, color: AppTheme.onSurface)),
        ],
      ),
    );
  }
}

// Minimal dark map style
const String _darkMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#0d1f1f"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#8badb0"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#0d1f1f"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#1e3535"}]},
  {"featureType": "road.arterial", "elementType": "geometry", "stylers": [{"color": "#1e3535"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#094f4f"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0d2b2b"}]},
  {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#132020"}]},
  {"featureType": "administrative", "elementType": "geometry.stroke", "stylers": [{"color": "#1a3535"}]},
  {"featureType": "landscape", "elementType": "geometry", "stylers": [{"color": "#0f1c1c"}]}
]
''';
