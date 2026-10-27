import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/station_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/passenger_wallet_provider.dart';
import 'providers/vehicle_provider.dart';
import 'providers/driver_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/freight_provider.dart';
import 'providers/dispute_provider.dart';
import 'services/voice_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/passenger/passenger_home.dart';
import 'screens/driver/driver_home.dart';
import 'models/user_model.dart';
import 'models/notification_model.dart';
import 'screens/notifications_screen.dart';
import 'services/local_notification_service.dart';
import 'core/app_theme.dart';

/// Navigation globale : ouvre l'écran des notifications quand on touche une notification système
final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Dates et mois en français (historique, reçus, portefeuille)
  await initializeDateFormatting('fr');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => StationProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => PassengerWalletProvider()),
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
        ChangeNotifierProvider(create: (_) => DriverProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => DisputeProvider()),
        ChangeNotifierProvider(create: (_) => FreightProvider()),
        Provider(create: (_) => VoiceService()),
      ],
      child: const AutoConnectApp(),
    ),
  );
}

class AutoConnectApp extends StatelessWidget {
  const AutoConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'AutoConnect',
      debugShowCheckedModeBanner: false,
      // Charte graphique issue du logo (lib/core/app_theme.dart)
      theme: AppTheme.light(),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/passenger_home': (context) => const PassengerHome(),
        '/driver_home': (context) => const DriverHome(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final AuthProvider _authProvider;
  late final NotificationProvider _notificationProvider;
  StreamSubscription<NotificationModel>? _incomingSub;

  @override
  void initState() {
    super.initState();
    _authProvider = context.read<AuthProvider>();
    _notificationProvider = context.read<NotificationProvider>();
    _authProvider.addListener(_syncNotifications);
    _incomingSub = _notificationProvider.incoming.listen(_refreshAfterNotification);
    LocalNotificationService.onTap = (_) => navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_authProvider.isAuthenticated) {
        _authProvider.syncProfile();
      }
      _syncNotifications();
    });
  }

  /// Notifications actives uniquement pendant une session
  void _syncNotifications() {
    if (_authProvider.isAuthenticated) {
      _notificationProvider.start();
    } else {
      _notificationProvider.stop();
    }
  }

  /// Une notification signale un changement : on recharge les données concernées
  void _refreshAfterNotification(NotificationModel notification) {
    final type = notification.type;
    if (notification.bookingId != null || type.startsWith('BOOKING') || type.startsWith('RESERVATION') ||
        type.startsWith('TRIP') || type.startsWith('PAYMENT') || type == 'PASSENGER_BOARDING') {
      context.read<BookingProvider>().fetchBookings();
    }
    if (type.startsWith('DRIVER_')) {
      context.read<DriverProvider>().loadProfile();
    }
    if (type.startsWith('WITHDRAWAL') || type.startsWith('PAYMENT') || type == 'TRIP_COMPLETED') {
      if (_authProvider.user?.role == UserRole.CHAUFFEUR) {
        context.read<WalletProvider>().fetchWalletData();
      }
    }
  }

  @override
  void dispose() {
    _authProvider.removeListener(_syncNotifications);
    _incomingSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isAuthenticated) {
      if (authProvider.user?.role == UserRole.CHAUFFEUR) {
        return const DriverHome();
      } else {
        return const PassengerHome();
      }
    }

    return const LoginScreen();
  }
}
