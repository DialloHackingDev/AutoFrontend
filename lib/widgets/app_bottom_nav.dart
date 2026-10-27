import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Barre d'onglets du bas, toujours au-dessus de la zone système du téléphone.
///
/// Avec la navigation par gestes (Huawei, Android 10+), le système déclare une marge
/// basse quasi nulle : la barre se retrouvait collée à la zone de glissement. On garantit
/// donc un espace minimal, en plus de la marge déclarée par le système.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavigationBarItem> items;

  const AppBottomNav({super.key, required this.currentIndex, required this.onTap, required this.items});

  @override
  Widget build(BuildContext context) {
    final gestureInset = MediaQuery.systemGestureInsetsOf(context).bottom;
    return Material(
      color: AppColors.surface,
      elevation: 8,
      shadowColor: Colors.black26,
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.only(bottom: gestureInset > 0 ? 6 : 10),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          items: items,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}
