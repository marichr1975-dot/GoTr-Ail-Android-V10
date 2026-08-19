import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/gemini_ai_service.dart';
import '../services/hiking_router.dart';

class AiSuggestionScreen extends StatefulWidget {
  final AiTrailSuggestion suggestion;
  const AiSuggestionScreen({super.key, required this.suggestion});

  @override
  State<AiSuggestionScreen> createState() => _AiSuggestionScreenState();
}

class _AiSuggestionScreenState extends State<AiSuggestionScreen> {
  static const _blue = Color(0xFF0B5FD7);
  static const _green = Color(0xFF20A85A);
  static const _ink = Color(0xFF112234);

  final MapController _mapController = MapController();
  List<LatLng> _route = const [];
  String? _routeError;
  bool _loadingRoute = true;

  AiTrailSuggestion get s => widget.suggestion;

  @override
  void initState() {
    super.initState();
    _buildRealRoute();
  }

  double _wantedKm() {
    final match = RegExp(r'(\d+(?:[.,]\d+)?)').firstMatch(s.distance);
    if (match == null) return 4;
    return double.tryParse(match.group(1)!.replaceAll(',', '.')) ?? 4;
  }

  Future<void> _buildRealRoute() async {
    final lat = s.latitude;
    final lon = s.longitude;
    if (lat == null || lon == null) {
      setState(() {
        _routeError = 'Coordinate della localita non disponibili.';
        _loadingRoute = false;
      });
      return;
    }

    final start = LatLng(lat, lon);
    final km = _wantedKm().clamp(2.0, 10.0);
    final radiusKm = math.max(0.35, km / (2 * math.pi));
    final dLat = radiusKm / 111.0;
    final dLon = radiusKm / (111.0 * math.cos(lat * math.pi / 180.0));

    final north = LatLng(lat + dLat, lon);
    final east = LatLng(lat, lon + dLon);
    final south = LatLng(lat - dLat, lon);
    final west = LatLng(lat, lon - dLon);

    final result = await HikingRouter.instance.routeThrough([
      start,
      east,
      south,
      west,
      north,
      start,
    ]);

    if (!mounted) return;
    setState(() {
      _route = result.points;
      _routeError = result.available ? null : result.message;
      _loadingRoute = false;
    });

    if (_route.length >= 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          final bounds = LatLngBounds.fromPoints(_route);
          _mapController.fitCamera(
            CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(26)),
          );
        } catch (_) {}
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = LatLng(s.latitude ?? 45.75, s.longitude ?? 11.85);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FA),
      appBar: AppBar(
        title: const Text('Percorso proposto',
            style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: _blue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * .47,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: 13.5,
                      minZoom: 7,
                      maxZoom: 18,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.gotr_ai',
                      ),
                      if (_route.length >= 2)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _route,
                              strokeWidth: 6,
                              color: _blue,
                              borderStrokeWidth: 2,
                              borderColor: Colors.white,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: center,
                            width: 48,
                            height: 48,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _green,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 3),
                              ),
                              child: const Icon(Icons.play_arrow_rounded,
                                  color: Colors.white, size: 28),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_loadingRoute)
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Color(0x66000000),
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    ),
                  if (!_loadingRoute && _routeError != null)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _routeError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                children: [
                  Text(
                    s.title,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.route_rounded,
                          label: 'Tipo',
                          value: s.routeType,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.straighten_rounded,
                          label: 'Distanza',
                          value: s.distance,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _InfoCard(
                    icon: Icons.trending_up_rounded,
                    label: 'Difficolta',
                    value: s.difficulty,
                    horizontal: true,
                  ),
                  const SizedBox(height: 10),
                  if (s.summary.trim().isNotEmpty)
                    Text(
                      s.summary,
                      style: const TextStyle(
                        color: Color(0xFF526574),
                        fontSize: 13.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: _route.length >= 2 ? () {} : null,
                      icon: const Icon(Icons.navigation_rounded),
                      label: const Text(
                        'INIZIA PERCORSO',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
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

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool horizontal;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    this.horizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E8EE)),
      ),
      child: horizontal
          ? Row(
              children: [
                Icon(icon, color: const Color(0xFF0B5FD7), size: 20),
                const SizedBox(width: 8),
                Text('$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                Flexible(
                  child: Text(value,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: const Color(0xFF0B5FD7), size: 20),
                const SizedBox(height: 7),
                Text(label,
                    style: const TextStyle(
                        color: Color(0xFF627383),
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(value,
                    style: const TextStyle(
                        color: Color(0xFF112234),
                        fontSize: 14,
                        fontWeight: FontWeight.w900)),
              ],
            ),
    );
  }
}

