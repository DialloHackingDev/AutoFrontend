import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Icônes de marqueurs dessinées par l'app et enregistrées dans le style de la carte.
/// Utilisation : `SymbolOptions(iconImage: MapMarkers.car, ...)`.
class MapMarkers {
  static const destination = 'ac-destination';
  static const car = 'ac-car';
  static const passenger = 'ac-passenger';
  static const station = 'ac-station';

  /// Taille d'affichage recommandée pour [SymbolOptions.iconSize].
  static const double iconSize = 0.55;

  /// À appeler dans `onStyleLoadedCallback` (le style recharge ses images à chaque chargement).
  static Future<void> register(MapLibreMapController controller) async {
    await controller.addImage(destination, await _pin(const Color(0xFFDC2626), Icons.flag));
    await controller.addImage(car, await _badge(const Color(0xFF1E3A8A), Icons.directions_car));
    await controller.addImage(passenger, await _badge(const Color(0xFF16A34A), Icons.person));
    await controller.addImage(station, await _badge(const Color(0xFF1E3A8A), Icons.directions_bus, size: 72));
  }

  /// Rond coloré avec icône blanche, contour blanc et ombre douce.
  static Future<Uint8List> _badge(Color color, IconData icon, {double size = 96}) {
    return _render(size, size, (canvas) {
      final center = Offset(size / 2, size / 2);
      final radius = size * 0.38;
      canvas.drawCircle(
        center.translate(0, size * 0.03),
        radius + 4,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(center, radius + 4, Paint()..color = Colors.white);
      canvas.drawCircle(center, radius, Paint()..color = color);
      _drawIcon(canvas, icon, center, radius * 1.1);
    });
  }

  /// Épingle (goutte) pour la destination, pointe en bas.
  static Future<Uint8List> _pin(Color color, IconData icon) {
    const width = 88.0;
    const height = 112.0;
    return _render(width, height, (canvas) {
      const headCenter = Offset(width / 2, width / 2);
      const radius = width * 0.4;
      final path = Path()
        ..addArc(Rect.fromCircle(center: headCenter, radius: radius), math.pi * 0.75, math.pi * 1.5)
        ..lineTo(width / 2, height - 4)
        ..close();

      canvas.drawPath(
        path.shift(const Offset(0, 3)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawPath(path, Paint()..color = color);
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
      _drawIcon(canvas, icon, headCenter, radius * 1.05);
    });
  }

  static void _drawIcon(Canvas canvas, IconData icon, Offset center, double size) {
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
  }

  static Future<Uint8List> _render(double width, double height, void Function(Canvas canvas) draw) async {
    final recorder = ui.PictureRecorder();
    draw(Canvas(recorder));
    final image = await recorder.endRecording().toImage(width.ceil(), height.ceil());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }
}
