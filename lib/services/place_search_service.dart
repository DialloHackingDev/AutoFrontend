import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../data/guinea_places.dart';

/// Recherche de lieux avec suggestions pendant la frappe.
///
/// 1. Villes de Guinée intégrées à l'app : résultats instantanés, même hors ligne.
/// 2. Photon (open source, données OpenStreetMap) : quartiers, rues, lieux précis,
///    limité à la Guinée, quand le réseau est disponible.
class PlaceSearchService {
  static const _photonUrl = 'https://photon.komoot.io/api/';

  /// Emprise de la Guinée (ouest, sud, est, nord)
  static const _guineaBbox = '-15.1,7.1,-7.6,12.7';

  final http.Client _client;

  PlaceSearchService({http.Client? client}) : _client = client ?? http.Client();

  /// Suggestions locales, triées : début de nom d'abord, puis contenu.
  List<Place> searchLocal(String query, {int limit = 5}) {
    final q = normalize(query);
    if (q.isEmpty) return const [];

    final startsWith = <Place>[];
    final contains = <Place>[];
    for (final place in guineaPlaces) {
      final name = normalize(place.name);
      if (name.startsWith(q)) {
        startsWith.add(place);
      } else if (name.contains(q) || normalize(place.subtitle).startsWith(q)) {
        contains.add(place);
      }
    }
    return [...startsWith, ...contains].take(limit).toList();
  }

  /// Suggestions en ligne (Photon). Retourne une liste vide en cas d'erreur réseau.
  Future<List<Place>> searchOnline(String query, {int limit = 6}) async {
    final q = query.trim();
    if (q.length < 2) return const [];

    final uri = Uri.parse(_photonUrl).replace(queryParameters: {
      'q': q,
      'limit': '$limit',
      'lang': 'fr',
      'bbox': _guineaBbox,
    });

    try {
      final response = await _client
          .get(uri, headers: {'User-Agent': 'AutoConnect/1.0 (com.example.frontend)'})
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return const [];

      final features = (jsonDecode(response.body)['features'] as List?) ?? const [];
      return features.map(_placeFromFeature).whereType<Place>().toList();
    } catch (e) {
      debugPrint('Recherche de lieux hors ligne ou indisponible : $e');
      return const [];
    }
  }

  /// Fusionne local + en ligne, sans doublons (même nom), local en premier.
  Future<List<Place>> search(String query) async {
    final local = searchLocal(query);
    final online = await searchOnline(query);
    final seen = local.map((p) => normalize(p.name)).toSet();
    return [
      ...local,
      ...online.where((p) => seen.add(normalize(p.name))),
    ];
  }

  Place? _placeFromFeature(dynamic feature) {
    if (feature is! Map<String, dynamic>) return null;
    final props = feature['properties'] as Map<String, dynamic>? ?? const {};
    final coords = (feature['geometry'] as Map<String, dynamic>?)?['coordinates'] as List?;
    final name = props['name']?.toString();
    if (name == null || coords == null || coords.length < 2) return null;

    final context = [props['district'], props['city'], props['state']]
        .whereType<String>()
        .where((part) => part != name)
        .toSet()
        .join(', ');

    return Place(
      name: name,
      subtitle: context.isEmpty ? 'Guinée' : context,
      latitude: (coords[1] as num).toDouble(),
      longitude: (coords[0] as num).toDouble(),
    );
  }

  /// Minuscules sans accents, pour comparer « labe » et « Labé ».
  static String normalize(String input) {
    const accents = {
      'à': 'a', 'â': 'a', 'ä': 'a', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'î': 'i', 'ï': 'i', 'ô': 'o', 'ö': 'o', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ç': 'c',
    };
    final lower = input.trim().toLowerCase();
    final buffer = StringBuffer();
    for (final char in lower.split('')) {
      buffer.write(accents[char] ?? char);
    }
    return buffer.toString();
  }
}
