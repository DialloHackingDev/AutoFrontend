import 'package:maplibre_gl/maplibre_gl.dart';

/// Configuration cartographique de l'application.
///
/// Moteur : MapLibre (open source, BSD) — rendu vectoriel fluide.
/// Fond de carte : OpenFreeMap (open source, gratuit, sans clé ni limite,
/// usage commercial autorisé) — données © OpenStreetMap.
class MapConfig {
  /// Styles OpenFreeMap disponibles : positron (épuré, clair), liberty (coloré), bright.
  static const String styleUrl = 'https://tiles.openfreemap.org/styles/positron';

  /// Centre par défaut tant que le GPS n'a pas répondu (Conakry).
  static const LatLng defaultCenter = LatLng(9.5370, -13.6773);
  static const double defaultZoom = 12;

  /// Zoom « quartier » : assez large pour se repérer, assez proche pour voir les rues.
  static const double streetZoom = 14;

  /// Couleurs de la charte AutoConnect (format attendu par MapLibre).
  static const String primaryColor = '#E41824';
  static const String routeColor = '#E41824';
  static const String routeCasingColor = '#FFFFFF';
}
