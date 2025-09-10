import 'package:flutter/material.dart';
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
      children: const [
        FeatureTile(
          title: "Anında Dene",
          subtitle: "Fotoğrafını çek, kıyafeti seç ve sonucu gör",
          icon: Icons.flash_on_rounded,
          start: AppColors.g1, end: AppColors.g2,
        ),
        FeatureTile(
          title: "Geçmişini İncele",
          subtitle: "Daha önce denediklerine tekrar göz at",
          icon: Icons.history_rounded,
          start: Color(0xFFFF8A65), end: Color(0xFFFF7043),
        ),
        FeatureTile(
          title: "Favorilerin",
          subtitle: "Beğendiğin kombinleri kaydet",
          icon: Icons.star_rounded,
          start: Color(0xFF34D399), end: Color(0xFF06B6D4),
        ),
        FeatureTile(
          title: "Hızlı Sonuç",
          subtitle: "3 saniyede AI ile gerçekçi sonuç",
          icon: Icons.speed_rounded,
          start: Color(0xFFFFC371), end: Color(0xFFFF5F6D),
        ),
      ],
    );
  }
}
