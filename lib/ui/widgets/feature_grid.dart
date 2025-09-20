import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart'; // ⬅️ eklendi
import 'feature_tile.dart';
import '../style/app_colors.dart';

class FeatureGrid extends StatelessWidget {
  const FeatureGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        FeatureTile(
          title: tr('home.features.instant.title'),
          subtitle: tr('home.features.instant.subtitle'),
          icon: Icons.flash_on_rounded,
          start: AppColors.g1, end: AppColors.g2,
        ),
        FeatureTile(
          title: tr('home.features.history.title'),
          subtitle: tr('home.features.history.subtitle'),
          icon: Icons.history_rounded,
          start: const Color(0xFFFF8A65), end: const Color(0xFFFF7043),
        ),
        FeatureTile(
          title: tr('home.features.favorites.title'),
          subtitle: tr('home.features.favorites.subtitle'),
          icon: Icons.star_rounded,
          start: const Color(0xFF34D399), end: const Color(0xFF06B6D4),
        ),
        FeatureTile(
          title: tr('home.features.fast.title'),
          subtitle: tr('home.features.fast.subtitle'),
          icon: Icons.speed_rounded,
          start: const Color(0xFFFFC371), end: const Color(0xFFFF5F6D),
        ),
      ],
    );
  }
}
