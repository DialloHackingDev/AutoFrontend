import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/app_bottom_nav.dart';

Widget _app({required EdgeInsets padding, required EdgeInsets gestures}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: const Size(390, 844), padding: padding, viewPadding: padding, systemGestureInsets: gestures),
      child: Scaffold(
        body: const SizedBox.expand(),
        bottomNavigationBar: AppBottomNav(
          currentIndex: 0,
          onTap: (_) {},
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Rechercher'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
      ),
    ),
  );
}

double _gapBelowLabels(WidgetTester tester) {
  final bar = tester.getRect(find.byType(BottomNavigationBar));
  return 844 - bar.bottom;
}

void main() {
  testWidgets('keeps a gap above the gesture area when the system declares no inset', (tester) async {
    await tester.pumpWidget(_app(padding: EdgeInsets.zero, gestures: const EdgeInsets.only(bottom: 24)));
    expect(_gapBelowLabels(tester), greaterThanOrEqualTo(6));
  });

  testWidgets('keeps a gap with classic navigation buttons too', (tester) async {
    await tester.pumpWidget(_app(padding: EdgeInsets.zero, gestures: EdgeInsets.zero));
    expect(_gapBelowLabels(tester), greaterThanOrEqualTo(10));
  });

  testWidgets('respects the system inset when one is declared', (tester) async {
    await tester.pumpWidget(_app(padding: const EdgeInsets.only(bottom: 34), gestures: EdgeInsets.zero));
    expect(_gapBelowLabels(tester), greaterThanOrEqualTo(34));
  });
}
