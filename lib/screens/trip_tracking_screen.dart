import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../core/map_config.dart';
import '../models/booking_model.dart';
import '../services/location_service.dart';
import '../services/realtime_service.dart';
import '../services/phone_call.dart';
import '../services/route_service.dart';
import '../widgets/map_markers.dart';
import '../core/app_theme.dart';

/// Suivi en temps réel d'une réservation.
///
/// - Chauffeur : voit la position du passager pour aller le chercher (jusqu'à son domicile).
/// - Passager : voit son chauffeur approcher.
/// Chacun publie sa propre position tant que l'écran est ouvert.
class TripTrackingScreen extends StatefulWidget {
  final Booking booking;
  final bool asDriver;

  const TripTrackingScreen({super.key, required this.booking, required this.asDriver});

  @override
  State<TripTrackingScreen> createState() => _TripTrackingScreenState();
}

class _TripTrackingScreenState extends State<TripTrackingScreen> {
  final _realtime = RealtimeService();
  final _locationService = LocationService();

  MapLibreMapController? _map;
  bool _styleLoaded = false;
  bool _hasLocationPermission = false;
  bool _cameraFitted = false;

  Position? _me;
  LivePosition? _other;
  Symbol? _otherMarker;

  // Itinéraire entre les deux personnes, recalculé quand l'une d'elles s'est déplacée
  final _routeService = RouteService();
  Line? _routeCasing;
  Line? _routeLine;
  RouteResult? _route;
  DateTime? _routeComputedAt;
  bool _routing = false;
  String? _locationError;

  StreamSubscription<Position>? _mySub;
  StreamSubscription<LivePosition>? _otherSub;
  Timer? _ticker;

  String get _otherLabel => widget.asDriver ? 'passager' : 'chauffeur';
  String? get _otherName => widget.asDriver ? widget.booking.passengerName : widget.booking.driverName;
  String? get _otherPhone => widget.asDriver ? widget.booking.passengerPhone : widget.booking.driverPhone;

  @override
  void initState() {
    super.initState();
    // Rafraîchit « mis à jour il y a … »
    _ticker = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
    });
    _start();
  }

  Future<void> _start() async {
    try {
      await _locationService.ensurePermission();
      if (!mounted) return;
      setState(() => _hasLocationPermission = true);
    } on LocationException catch (e) {
      if (mounted) setState(() => _locationError = e.message);
    }

    await _realtime.connect();
    _realtime.followBooking(widget.booking.id);
    if (!widget.asDriver && widget.booking.driverId != null) {
      _realtime.followDriver(widget.booking.driverId!);
    }

    _otherSub = (widget.asDriver ? _realtime.passengerPositions : _realtime.driverPositions)
        .listen(_onOtherPosition);

    if (_hasLocationPermission) {
      _mySub = _locationService.positionStream().listen(_onMyPosition);
      try {
        _onMyPosition(await _locationService.getCurrentPosition());
      } on LocationException catch (_) {}
    }
  }

  void _onMyPosition(Position position) {
    if (!mounted) return;
    setState(() => _me = position);
    if (widget.asDriver) {
      _realtime.sendDriverLocation(position.latitude, position.longitude);
    } else {
      _realtime.sendPassengerLocation(widget.booking.id, position.latitude, position.longitude);
    }
    _fitCameraOnce();
    _refreshRoute();
  }

  Future<void> _onOtherPosition(LivePosition position) async {
    if (!mounted) return;
    setState(() => _other = position);
    await _drawOtherMarker();
    _fitCameraOnce();
  }

  Future<void> _drawOtherMarker() async {
    final map = _map;
    final other = _other;
    if (map == null || !_styleLoaded || other == null) return;

    final options = SymbolOptions(
      geometry: LatLng(other.latitude, other.longitude),
      iconImage: widget.asDriver ? MapMarkers.passenger : MapMarkers.car,
      iconSize: MapMarkers.iconSize,
    );
    if (_otherMarker == null) {
      _otherMarker = await map.addSymbol(options);
    } else {
      await map.updateSymbol(_otherMarker!, options);
    }
    _refreshRoute();
  }

  /// Recalcule l'itinéraire au plus toutes les 30 s (évite de surcharger le service)
  Future<void> _refreshRoute() async {
    final me = _me;
    final other = _other;
    final map = _map;
    if (me == null || other == null || map == null || !_styleLoaded || _routing) return;
    final last = _routeComputedAt;
    if (last != null && DateTime.now().difference(last).inSeconds < 30) return;

    _routing = true;
    final route = await _routeService.drivingRoute(
      LatLng(me.latitude, me.longitude),
      LatLng(other.latitude, other.longitude),
    );
    _routing = false;
    _routeComputedAt = DateTime.now();
    if (!mounted || route == null) return;

    setState(() => _route = route);
    final casing = LineOptions(
      geometry: route.points,
      lineColor: MapConfig.routeCasingColor,
      lineWidth: 9,
      lineJoin: 'round',
    );
    final line = LineOptions(
      geometry: route.points,
      lineColor: MapConfig.routeColor,
      lineWidth: 5,
      lineJoin: 'round',
    );
    if (_routeLine == null) {
      _routeCasing = await map.addLine(casing);
      _routeLine = await map.addLine(line);
    } else {
      await map.updateLine(_routeCasing!, casing);
      await map.updateLine(_routeLine!, line);
    }
  }

  /// Cadre la carte une fois que les deux positions sont connues.
  void _fitCameraOnce() {
    final map = _map;
    if (_cameraFitted || map == null || _me == null || _other == null) return;
    _cameraFitted = true;
    _fitBoth();
  }

  void _fitBoth() {
    final map = _map;
    final me = _me;
    final other = _other;
    if (map == null) return;
    if (me == null || other == null) {
      final target = other != null
          ? LatLng(other.latitude, other.longitude)
          : me != null
              ? LatLng(me.latitude, me.longitude)
              : null;
      if (target != null) map.animateCamera(CameraUpdate.newLatLngZoom(target, MapConfig.streetZoom));
      return;
    }
    map.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(math.min(me.latitude, other.latitude), math.min(me.longitude, other.longitude)),
          northeast: LatLng(math.max(me.latitude, other.latitude), math.max(me.longitude, other.longitude)),
        ),
        left: 60,
        top: 80,
        right: 60,
        bottom: 260,
      ),
    );
  }

  String? get _distanceLabel {
    final route = _route;
    if (route != null) return route.summary;
    final me = _me;
    final other = _other;
    if (me == null || other == null) return null;
    final meters = LocationService.distanceBetween(me.latitude, me.longitude, other.latitude, other.longitude);
    return meters < 1000 ? '${meters.round()} m' : '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String get _freshnessLabel {
    final other = _other;
    if (other == null) return 'En attente de la position du $_otherLabel…';
    final seconds = DateTime.now().difference(other.receivedAt).inSeconds;
    if (seconds < 10) return 'Position en direct';
    if (seconds < 60) return 'Mise à jour il y a $seconds s';
    return 'Mise à jour il y a ${seconds ~/ 60} min';
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _mySub?.cancel();
    _otherSub?.cancel();
    _realtime.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.asDriver ? 'Aller chercher le passager' : 'Suivre mon chauffeur'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: MapLibreMap(
              styleString: MapConfig.styleUrl,
              initialCameraPosition: const CameraPosition(
                target: MapConfig.defaultCenter,
                zoom: MapConfig.defaultZoom,
              ),
              myLocationEnabled: _hasLocationPermission,
              compassEnabled: true,
              attributionButtonPosition: AttributionButtonPosition.bottomLeft,
              onMapCreated: (controller) => _map = controller,
              onStyleLoadedCallback: () async {
                final map = _map;
                if (map == null) return;
                await MapMarkers.register(map);
                _styleLoaded = true;
                _drawOtherMarker();
                _fitBoth();
              },
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            // Au-dessus de la zone système (navigation par gestes ou boutons)
            bottom: 16 + MediaQuery.paddingOf(context).bottom + (MediaQuery.systemGestureInsetsOf(context).bottom > 0 ? 8 : 0),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: widget.asDriver ? AppColors.successSoft : AppColors.primarySoft,
                          child: Icon(
                            widget.asDriver ? Icons.person_pin_circle : Icons.directions_car,
                            color: widget.asDriver ? AppColors.successDark : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _otherName ?? (widget.asDriver ? 'Passager' : 'Chauffeur'),
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${booking.departure} → ${booking.destination}',
                                style: const TextStyle(color: AppColors.inkMuted),
                              ),
                            ],
                          ),
                        ),
                        if (_distanceLabel != null)
                          Text(
                            _distanceLabel!,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          _other == null ? Icons.hourglass_empty : Icons.circle,
                          size: 12,
                          color: _other == null ? AppColors.warning : AppColors.success,
                        ),
                        const SizedBox(width: 6),
                        Expanded(child: Text(_freshnessLabel, style: const TextStyle(color: AppColors.inkMuted))),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _otherPhone == null ? null : () => callPhone(context, _otherPhone),
                            icon: const Icon(Icons.call),
                            label: Text(widget.asDriver ? 'Appeler le passager' : 'Appeler le chauffeur'),
                            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: _fitBoth,
                          style: OutlinedButton.styleFrom(minimumSize: const Size(52, 52), padding: EdgeInsets.zero),
                          child: const Tooltip(
                            message: 'Centrer la carte',
                            child: Icon(Icons.center_focus_strong, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    if (_otherPhone == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text('Numéro de téléphone indisponible.',
                            style: TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                      ),
                    if (_locationError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(_locationError!, style: const TextStyle(color: AppColors.danger)),
                      ),
                    if (!widget.asDriver)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Votre position est partagée avec le chauffeur jusqu’au départ.',
                          style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
