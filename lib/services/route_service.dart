import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';

/// Itinéraire routier calculé entre deux points.
class RouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  const RouteResult({required this.points, required this.distanceMeters, required this.durationSeconds});

  /// Ex. « 12,4 km · 18 min »
  String get summary {
    final distance = distanceMeters < 1000
        ? '${distanceMeters.round()} m'
        : '${(distanceMeters / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
    final minutes = (durationSeconds / 60).round();
    final duration = minutes < 60 ? '$minutes min' : '${minutes ~/ 60} h ${(minutes % 60).toString().padLeft(2, '0')}';
    return '$distance · $duration';
  }
}

/// Calcul d'itinéraire avec OSRM (open source, données OpenStreetMap).
///
/// Le serveur public de démonstration convient aux tests ; en production,
/// héberger sa propre instance OSRM (gratuite) et changer [baseUrl].
class RouteService {
  static const baseUrl = 'https://router.project-osrm.org';

  final http.Client _client;

  RouteService({http.Client? client}) : _client = client ?? http.Client();

  /// Retourne null hors ligne ou si aucun itinéraire n'existe.
  Future<RouteResult?> drivingRoute(LatLng from, LatLng to) async {
    final uri = Uri.parse(
      '$baseUrl/route/v1/driving/${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
      '?overview=full&geometries=geojson',
    );

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = body['routes'] as List?;
      if (body['code'] != 'Ok' || routes == null || routes.isEmpty) return null;

      final route = routes.first as Map<String, dynamic>;
      final coordinates = (route['geometry'] as Map<String, dynamic>)['coordinates'] as List;
      return RouteResult(
        points: coordinates
            .map((c) => LatLng(((c as List)[1] as num).toDouble(), (c[0] as num).toDouble()))
            .toList(),
        distanceMeters: (route['distance'] as num).toDouble(),
        durationSeconds: (route['duration'] as num).toDouble(),
      );
    } catch (e) {
      debugPrint('Itinéraire indisponible : $e');
      return null;
    }
  }
}
