import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../models/vehicle_model.dart';
import '../../core/map_config.dart';
import '../../widgets/map_markers.dart';
import '../../services/route_service.dart';
import '../../data/guinea_places.dart';
import '../../providers/station_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/freight_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../services/voice_service.dart';
import '../../services/location_service.dart';
import '../../services/phone_call.dart';
import '../../services/passenger_location_sharer.dart';
import '../../services/place_search_service.dart';
import '../trip_tracking_screen.dart';
import '../../widgets/booking_qr_image.dart';
import 'payment_screen.dart';
import 'passenger_profile_view.dart';
import '../notifications_screen.dart';
import '../dispute_screen.dart';
import '../../core/app_theme.dart';
import '../../widgets/app_bottom_nav.dart';

class PassengerHome extends StatefulWidget {
  const PassengerHome({super.key});

  @override
  State<PassengerHome> createState() => _PassengerHomeState();
}

class _PassengerHomeState extends State<PassengerHome> {
  int _selectedIndex = 0;
  final _voiceService = VoiceService();
  final _locationSharer = PassengerLocationSharer();
  late final BookingProvider _bookingProvider;

  @override
  void initState() {
    super.initState();
    // Le chauffeur doit pouvoir localiser le passager pendant une réservation active
    _bookingProvider = context.read<BookingProvider>();
    _bookingProvider.addListener(_syncLocationSharing);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bookingProvider.fetchBookings();
    });
  }

  void _syncLocationSharing() {
    _locationSharer.syncWith(_bookingProvider.bookings);
  }

  @override
  void dispose() {
    _bookingProvider.removeListener(_syncLocationSharing);
    _locationSharer.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AutoConnect', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          const NotificationBell(),
          IconButton(
            tooltip: 'Écouter les instructions',
            icon: const Icon(Icons.volume_up),
            onPressed: () => _voiceService.speak('Bienvenue sur AutoConnect. Recherchez un trajet ou gérez vos réservations.'),
          ),
          IconButton(
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: [
        const _SearchTripView(),
        const _MyBookingsView(),
        const PassengerProfileView(),
      ][_selectedIndex],
      bottomNavigationBar: AppBottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Rechercher'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_bus), label: 'Mes trajets'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class _SearchTripView extends StatefulWidget {
  const _SearchTripView();

  @override
  State<_SearchTripView> createState() => _SearchTripViewState();
}

/// Écran de recherche passager : carte plein écran en arrière-plan, barre de recherche
/// unique avec suggestions de lieux, résultats dans un panneau glissant.
class _SearchTripViewState extends State<_SearchTripView> {
  final _destinationController = TextEditingController();
  final _destinationFocus = FocusNode();
  final _placeSearch = PlaceSearchService();

  MapLibreMapController? _map;
  bool _styleLoaded = false;
  Symbol? _destinationMarker;
  final List<Symbol> _stationMarkers = [];
  final _routeService = RouteService();
  Line? _routeCasing;
  Line? _routeLine;

  /// Distance et durée estimées du trajet, ex. « 12,4 km · 18 min »
  String? _routeSummary;

  Position? _myPosition;
  bool _hasLocationPermission = false;
  bool _locating = true;

  List<Place> _suggestions = const [];
  bool _loadingSuggestions = false;
  Timer? _debounce;
  int _suggestionRequest = 0;

  Place? _destination;
  bool _hasSearched = false;

  /// Ville de départ choisie par le passager ; sinon déduite de sa position
  String? _manualDeparture;

  @override
  void initState() {
    super.initState();
    _destinationFocus.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StationProvider>().fetchStations().then((_) => _drawStations());
      _locate();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _destinationController.dispose();
    _destinationFocus.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    setState(() => _locating = true);
    try {
      final position = await LocationService().getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _myPosition = position;
        _hasLocationPermission = true;
        _locating = false;
      });
      _map?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(position.latitude, position.longitude), MapConfig.streetZoom),
      );
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() => _locating = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// Lieu connu le plus proche de la position GPS (ville ou commune de départ)
  Place? get _nearestPlace {
    final me = _myPosition;
    if (me == null) return null;
    Place? nearest;
    double best = double.infinity;
    for (final place in guineaPlaces) {
      final d = LocationService.distanceBetween(me.latitude, me.longitude, place.latitude, place.longitude);
      if (d < best) {
        best = d;
        nearest = place;
      }
    }
    // Au-delà de 30 km, le nom de la ville la plus proche serait trompeur
    return best <= 30000 ? nearest : null;
  }

  String get _departureValue {
    if (_manualDeparture != null && _manualDeparture!.isNotEmpty) return _manualDeparture!;
    return _nearestPlace?.name ?? 'Ma position';
  }

  // ── Suggestions pendant la frappe ──

  void _onQueryChanged(String text) {
    _destination = null;
    _routeSummary = null;
    _debounce?.cancel();

    // Villes intégrées : affichage immédiat, même hors ligne
    setState(() {
      _suggestions = _placeSearch.searchLocal(text);
      _loadingSuggestions = text.trim().length >= 2;
    });
    if (text.trim().length < 2) return;

    // Lieux précis (quartiers, rues…) : après une courte pause de frappe
    final request = ++_suggestionRequest;
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final results = await _placeSearch.search(text);
      if (!mounted || request != _suggestionRequest) return;
      setState(() {
        _suggestions = results;
        _loadingSuggestions = false;
      });
    });
  }

  Future<void> _selectPlace(Place place) async {
    _debounce?.cancel();
    _suggestionRequest++;
    _destinationController.text = place.name;
    _destinationFocus.unfocus();
    setState(() {
      _destination = place;
      _suggestions = const [];
      _loadingSuggestions = false;
    });
    _searchVehicles();
    await _showTrip(place);
  }

  /// Affiche la destination, trace l'itinéraire routier et cadre la carte.
  Future<void> _showTrip(Place place) async {
    await _drawDestination(place);
    final me = _myPosition;
    if (me == null) {
      _fitPoints([LatLng(place.latitude, place.longitude)]);
      return;
    }

    final from = LatLng(me.latitude, me.longitude);
    final to = LatLng(place.latitude, place.longitude);
    _fitPoints([from, to]);

    final route = await _routeService.drivingRoute(from, to);
    if (!mounted || _destination != place) return;
    if (route == null) {
      // Hors ligne : pas de tracé, seulement la distance à vol d'oiseau
      final km = LocationService.distanceBetween(from.latitude, from.longitude, to.latitude, to.longitude) / 1000;
      setState(() => _routeSummary = '≈ ${km.toStringAsFixed(1).replaceAll('.', ',')} km à vol d’oiseau');
      return;
    }
    setState(() => _routeSummary = route.summary);
    await _drawRoute(route.points);
    _fitPoints(route.points);
  }

  Future<void> _drawDestination(Place place) async {
    final map = _map;
    if (map == null || !_styleLoaded) return;
    final options = SymbolOptions(
      geometry: LatLng(place.latitude, place.longitude),
      iconImage: MapMarkers.destination,
      iconSize: MapMarkers.iconSize,
      iconAnchor: 'bottom',
    );
    if (_destinationMarker == null) {
      _destinationMarker = await map.addSymbol(options);
    } else {
      await map.updateSymbol(_destinationMarker!, options);
    }
  }

  /// Itinéraire bleu avec liseré blanc, comme sur les apps de navigation
  Future<void> _drawRoute(List<LatLng> points) async {
    final map = _map;
    if (map == null || !_styleLoaded || points.length < 2) return;
    final casing = LineOptions(
      geometry: points,
      lineColor: MapConfig.routeCasingColor,
      lineWidth: 9,
      lineJoin: 'round',
    );
    final line = LineOptions(
      geometry: points,
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

  /// Cadre la carte sur des points, en laissant de la place à la recherche et aux résultats
  void _fitPoints(List<LatLng> points) {
    final map = _map;
    if (map == null || points.isEmpty) return;
    if (points.length == 1) {
      map.animateCamera(CameraUpdate.newLatLngZoom(points.first, MapConfig.defaultZoom));
      return;
    }
    final lats = points.map((p) => p.latitude);
    final lngs = points.map((p) => p.longitude);
    map.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(lats.reduce(math.min), lngs.reduce(math.min)),
          northeast: LatLng(lats.reduce(math.max), lngs.reduce(math.max)),
        ),
        left: 50,
        top: 180,
        right: 50,
        bottom: MediaQuery.of(context).size.height * 0.42,
      ),
    );
  }

  Future<void> _drawStations() async {
    final map = _map;
    if (map == null || !_styleLoaded || !mounted || _stationMarkers.isNotEmpty) return;
    final stations = context.read<StationProvider>().stations;
    for (final station in stations) {
      if (station.latitude == null || station.longitude == null) continue;
      _stationMarkers.add(await map.addSymbol(SymbolOptions(
        geometry: LatLng(station.latitude!, station.longitude!),
        iconImage: MapMarkers.station,
        iconSize: MapMarkers.iconSize,
      )));
    }
  }

  Future<void> _searchVehicles() async {
    final destination = _destinationController.text.trim();
    if (destination.isEmpty) {
      _destinationFocus.requestFocus();
      return;
    }

    // Saisie validée sans choisir de suggestion : on reprend la ville correspondante si elle existe
    if (_destination == null) {
      final match = _placeSearch.searchLocal(destination, limit: 1);
      if (match.isNotEmpty && PlaceSearchService.normalize(match.first.name) == PlaceSearchService.normalize(destination)) {
        _destination = match.first;
        unawaited(_showTrip(match.first));
      }
    }

    if (!mounted) return;
    _destinationFocus.unfocus();
    setState(() {
      _hasSearched = true;
      _suggestions = const [];
    });
    await context.read<VehicleProvider>().fetchAvailableVehicles(
      departure: _departureValue,
      destination: destination,
    );
  }

  Future<void> _editDeparture() async {
    final controller = TextEditingController(text: _manualDeparture ?? '');
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ville de départ'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Laisser vide pour utiliser ma position'),
          onSubmitted: (v) => Navigator.pop(dialogContext, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: const Text('Valider')),
        ],
      ),
    );
    if (value != null && mounted) {
      setState(() => _manualDeparture = value.isEmpty ? null : value);
    }
  }

  void _showFreightSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
        ),
        child: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Service fret', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              _FreightQuickAction(),
            ],
          ),
        ),
      ),
    );
  }

  void _showBookingDialog(Vehicle vehicle) {
    final placesController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('${vehicle.marque} ${vehicle.modele}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Conducteur : ${vehicle.driverName ?? "Non renseigné"}'),
              const SizedBox(height: 8),
              Text('Places disponibles : ${vehicle.placesDisponibles}'),
              const SizedBox(height: 16),
              TextField(
                controller: placesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nombre de places',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
            FilledButton(
              onPressed: () async {
                final places = int.tryParse(placesController.text) ?? 1;
                if (places < 1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Le nombre de places doit être supérieur à 0.')),
                  );
                  return;
                }

                Navigator.pop(dialogContext);
                final success = await context.read<BookingProvider>().createBooking(
                  vehicleId: vehicle.id,
                  departure: _departureValue,
                  destination: _destinationController.text.trim(),
                  places: places,
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Réservation envoyée au conducteur.'
                            : context.read<BookingProvider>().errorMessage ?? 'La réservation n’a pas pu être créée.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Réserver'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeTrips = context.watch<BookingProvider>().bookings.where((b) => b.isTrackable).toList();
    final showSuggestions = _destinationFocus.hasFocus && (_suggestions.isNotEmpty || _loadingSuggestions);

    return Stack(
      children: [
        // ── Carte plein écran en arrière-plan ──
        Positioned.fill(
          child: MapLibreMap(
            styleString: MapConfig.styleUrl,
            initialCameraPosition: const CameraPosition(
              target: MapConfig.defaultCenter,
              zoom: MapConfig.defaultZoom,
            ),
            myLocationEnabled: _hasLocationPermission,
            compassEnabled: false,
            attributionButtonPosition: AttributionButtonPosition.bottomLeft,
            onMapCreated: (controller) => _map = controller,
            onStyleLoadedCallback: () async {
              final map = _map;
              if (map == null) return;
              await MapMarkers.register(map);
              _styleLoaded = true;
              _drawStations();
              final me = _myPosition;
              if (me != null) {
                map.moveCamera(CameraUpdate.newLatLngZoom(LatLng(me.latitude, me.longitude), MapConfig.streetZoom));
              }
            },
            onMapClick: (_, _) => _destinationFocus.unfocus(),
          ),
        ),

        // ── Barre de recherche unique + suggestions ──
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Material(
                elevation: 6,
                shadowColor: Colors.black26,
                borderRadius: BorderRadius.circular(28),
                color: Colors.white,
                child: TextField(
                  controller: _destinationController,
                  focusNode: _destinationFocus,
                  textInputAction: TextInputAction.search,
                  textCapitalization: TextCapitalization.words,
                  onChanged: _onQueryChanged,
                  onSubmitted: (_) => _searchVehicles(),
                  decoration: InputDecoration(
                    hintText: 'Où allez-vous ?',
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    suffixIcon: _destinationController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Effacer',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _destinationController.clear();
                              _onQueryChanged('');
                              _destinationFocus.requestFocus();
                            },
                          ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (showSuggestions)
                _PlaceSuggestions(
                  places: _suggestions,
                  loading: _loadingSuggestions,
                  onSelect: _selectPlace,
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      avatar: Icon(
                        _manualDeparture == null ? Icons.my_location : Icons.place,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      label: Text(_manualDeparture == null && _locating ? 'Localisation…' : 'Départ : $_departureValue'),
                      backgroundColor: Colors.white,
                      elevation: 2,
                      onPressed: _editDeparture,
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.inventory_2, size: 18, color: AppColors.primary),
                      label: const Text('Envoyer un colis'),
                      backgroundColor: Colors.white,
                      elevation: 2,
                      onPressed: _showFreightSheet,
                    ),
                    if (activeTrips.isNotEmpty)
                      ActionChip(
                        avatar: const Icon(Icons.navigation, size: 18, color: Colors.white),
                        label: const Text('Suivre mon chauffeur', style: TextStyle(color: Colors.white)),
                        backgroundColor: AppColors.successDark,
                        elevation: 2,
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TripTrackingScreen(booking: activeTrips.first, asDriver: false),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),

        // ── Recentrer sur ma position ──
        Positioned(
          right: 16,
          bottom: _hasSearched ? MediaQuery.of(context).size.height * 0.22 : 24,
          child: FloatingActionButton.small(
            heroTag: 'recenter',
            tooltip: 'Ma position',
            backgroundColor: Colors.white,
            onPressed: () {
              final me = _myPosition;
              if (me == null) {
                _locate();
              } else {
                _map?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(me.latitude, me.longitude), MapConfig.streetZoom));
              }
            },
            child: _locating
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location, color: AppColors.primary),
          ),
        ),

        // ── Résultats dans un panneau glissant au-dessus de la carte ──
        if (_hasSearched)
          DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.18,
            maxChildSize: 0.85,
            builder: (context, scrollController) => _VehicleResultsSheet(
              scrollController: scrollController,
              destination: _destinationController.text.trim(),
              routeSummary: _routeSummary,
              onSelect: _showBookingDialog,
            ),
          ),
      ],
    );
  }
}

class _PlaceSuggestions extends StatelessWidget {
  final List<Place> places;
  final bool loading;
  final void Function(Place place) onSelect;

  const _PlaceSuggestions({required this.places, required this.loading, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 320),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          children: [
            for (final place in places)
              ListTile(
                dense: true,
                leading: const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primarySoft,
                  child: Icon(Icons.place, size: 18, color: AppColors.primary),
                ),
                title: Text(place.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(place.subtitle),
                onTap: () => onSelect(place),
              ),
            if (loading)
              const ListTile(
                dense: true,
                leading: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                title: Text('Recherche de lieux…'),
              ),
          ],
        ),
      ),
    );
  }
}

class _VehicleResultsSheet extends StatelessWidget {
  final ScrollController scrollController;
  final String destination;
  final String? routeSummary;
  final void Function(Vehicle vehicle) onSelect;

  const _VehicleResultsSheet({
    required this.scrollController,
    required this.destination,
    this.routeSummary,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final vehicleProvider = context.watch<VehicleProvider>();
    final vehicles = vehicleProvider.availableVehicles;

    return Material(
      elevation: 12,
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text(
            vehicleProvider.isLoading
                ? 'Recherche de véhicules…'
                : '${vehicles.length} véhicule(s) vers $destination',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (routeSummary != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Icon(Icons.route, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(routeSummary!, style: TextStyle(color: Colors.grey[700])),
                ],
              ),
            ),
          const SizedBox(height: 12),
          if (vehicleProvider.isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (vehicleProvider.errorMessage != null)
            Text(vehicleProvider.errorMessage!, style: const TextStyle(color: AppColors.danger))
          else if (vehicles.isEmpty)
            const Text('Aucun véhicule disponible pour l’instant. Réessayez plus tard.')
          else
            for (final vehicle in vehicles)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.directions_car)),
                  title: Text('${vehicle.marque} ${vehicle.modele}'),
                  subtitle: Text(
                    '${vehicle.driverName ?? "Conducteur à confirmer"} • ${vehicle.placesDisponibles} place(s) • ${vehicle.driverNote.toStringAsFixed(1)} ★',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onSelect(vehicle),
                ),
              ),
        ],
      ),
    );
  }
}

class _MyBookingsView extends StatelessWidget {
  const _MyBookingsView();

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();

    if (bookingProvider.isLoading && bookingProvider.bookings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (bookingProvider.bookings.isEmpty) {
      return const Center(child: Text('Aucune réservation en cours'));
    }

    return RefreshIndicator(
      onRefresh: bookingProvider.fetchBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookingProvider.bookings.length,
        itemBuilder: (context, index) {
          final booking = bookingProvider.bookings[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text('${booking.departure} → ${booking.destination}'),
              subtitle: Text(
                '${_statusLabel(booking.statut)} • ${DateFormat('dd/MM/yyyy').format(booking.createdAt)}',
                style: TextStyle(color: _getStatusColor(booking.statut)),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showBookingDetails(context, booking),
            ),
          );
        },
      ),
    );
  }

  void _showBookingDetails(BuildContext context, Booking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${booking.departure} → ${booking.destination}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Statut : ${_statusLabel(booking.statut)}'),
              Text('Places : ${booking.places}'),
              Text('Prix : ${booking.prix.toStringAsFixed(0)} GNF'),
              const SizedBox(height: 12),
              const Text('Validation embarquement', style: TextStyle(fontWeight: FontWeight.bold)),
              if (booking.qrCode != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: BookingQrImage(qrCode: booking.qrCode!),
                  ),
                ),
              // L'OTP reste affiché à côté du QR : le chauffeur peut le saisir si le scan échoue
              if (booking.otpCode != null)
                Center(
                  child: Text('Code OTP : ${booking.otpCode}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                ),
              if (booking.qrCode == null && booking.otpCode == null)
                const Text('Le QR/OTP sera affiché dès que la réservation sera payée et validée.'),
              const SizedBox(height: 20),
              // Contact direct avec le chauffeur dès qu'il a accepté, jusqu'à la fin du trajet
              if (booking.driverPhone != null &&
                  const {
                    BookingStatus.CONFIRMED,
                    BookingStatus.PAID,
                    BookingStatus.BOARDING,
                    BookingStatus.IN_PROGRESS,
                  }.contains(booking.statut))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => callPhone(context, booking.driverPhone),
                      icon: const Icon(Icons.call),
                      label: Text('Appeler le chauffeur${booking.driverName != null ? ' (${booking.driverName})' : ''}'),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                    ),
                  ),
                ),
              if (booking.isTrackable)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => TripTrackingScreen(booking: booking, asDriver: false)),
                        );
                      },
                      icon: const Icon(Icons.navigation),
                      label: const Text('Suivre mon chauffeur en direct'),
                    ),
                  ),
                ),
              // 1re validation de l'embarquement : le passager confirme sa présence avec son GPS
              if (booking.statut == BookingStatus.PAID || booking.statut == BookingStatus.BOARDING)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmBoarding(context, sheetContext, booking),
                    icon: const Icon(Icons.how_to_reg),
                    label: Text(
                      booking.statut == BookingStatus.BOARDING
                          ? 'Renouveler ma confirmation de présence'
                          : 'Je suis au point de départ',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              if (booking.statut == BookingStatus.BOARDING)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Présence confirmée : présentez votre QR Code ou votre code OTP au chauffeur.'),
                ),
              const SizedBox(height: 12),
              if (booking.statut == BookingStatus.CONFIRMED)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      final success = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentScreen(
                            bookingId: booking.id,
                            amount: booking.prix,
                          ),
                        ),
                      );
                      if (success == true && context.mounted) {
                        context.read<BookingProvider>().fetchBookings();
                      }
                    },
                    icon: const Icon(Icons.payment),
                    label: const Text('Payer la réservation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              if (booking.statut != BookingStatus.CANCELLED &&
                  booking.statut != BookingStatus.COMPLETED &&
                  booking.statut != BookingStatus.IN_PROGRESS)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final success = await context.read<BookingProvider>().cancelBooking(booking.id);
                      if (context.mounted) {
                        Navigator.pop(sheetContext);
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Réservation annulée.')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.cancel),
                    label: const Text('Annuler la réservation'),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => DisputeScreen(bookingId: booking.id)));
                  },
                  icon: const Icon(Icons.warning, color: AppColors.warning),
                  label: const Text('Signaler un problème', style: TextStyle(color: AppColors.warning)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmBoarding(BuildContext context, BuildContext sheetContext, Booking booking) async {
    final messenger = ScaffoldMessenger.of(context);
    final bookingProvider = context.read<BookingProvider>();
    Navigator.pop(sheetContext);

    try {
      final position = await LocationService().getCurrentPosition();
      final success = await bookingProvider.confirmBoarding(
        bookingId: booking.id,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Présence confirmée. Présentez votre QR Code au chauffeur.'
                : bookingProvider.errorMessage ?? 'La confirmation a échoué.',
          ),
        ),
      );
    } on LocationException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.PAID:
        return AppColors.success;
      case BookingStatus.PENDING:
      case BookingStatus.CONFIRMED:
        return AppColors.warning;
      case BookingStatus.CANCELLED:
        return AppColors.danger;
      case BookingStatus.IN_PROGRESS:
      case BookingStatus.COMPLETED:
        return AppColors.primary;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.PENDING:
        return 'En attente';
      case BookingStatus.CONFIRMED:
        return 'Confirmée';
      case BookingStatus.PAID:
        return 'Payée';
      case BookingStatus.BOARDING:
        return 'Embarquement';
      case BookingStatus.IN_PROGRESS:
        return 'En cours';
      case BookingStatus.COMPLETED:
        return 'Terminée';
      case BookingStatus.FUNDS_RELEASED:
        return 'Fonds libérés';
      case BookingStatus.CANCELLED:
        return 'Annulée';
      case BookingStatus.DISPUTE:
        return 'Litige';
      case BookingStatus.INCIDENT:
        return 'Incident';
    }
  }
}

class _FreightQuickAction extends StatefulWidget {
  const _FreightQuickAction();

  @override
  State<_FreightQuickAction> createState() => _FreightQuickActionState();
}

class _FreightQuickActionState extends State<_FreightQuickAction> {
  final _poidsController = TextEditingController(text: '10');
  final _destinationController = TextEditingController();
  final _typeController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _poidsController.dispose();
    _destinationController.dispose();
    _typeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitFreight(BuildContext context) async {
    final poids = double.tryParse(_poidsController.text.trim()) ?? 0;
    final destination = _destinationController.text.trim();
    if (poids <= 0 || destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le poids et la destination sont requis pour créer un fret.')),
      );
      return;
    }

    final success = await context.read<FreightProvider>().createFreight(
      poids: poids,
      destination: destination,
      type: _typeController.text.trim().isEmpty ? null : _typeController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Demande de fret enregistrée.' : 'Impossible d’enregistrer le fret.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Envoyez un colis ou du fret de manière sécurisée.'),
            const SizedBox(height: 12),
            TextField(
              controller: _poidsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Poids (kg)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _destinationController,
              decoration: const InputDecoration(labelText: 'Destination', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _typeController,
              decoration: const InputDecoration(labelText: 'Type de marchandise', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _submitFreight(context),
                child: const Text('Créer une demande de fret'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
