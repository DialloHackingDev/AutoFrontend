import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Liseré tricolore (rouge, orange, vert) repris du logo AutoConnect.
class BrandStripe extends StatelessWidget {
  final double width;
  final double height;

  const BrandStripe({super.key, this.width = 72, this.height = 4});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(height),
        ),
      ),
    );
  }
}
