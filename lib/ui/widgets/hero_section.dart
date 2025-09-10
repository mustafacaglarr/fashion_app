import 'package:flutter/material.dart';
import '../style/app_colors.dart';

class HeroSection extends StatelessWidget {
  final VoidCallback onPrimaryCta;
  const HeroSection({super.key, required this.onPrimaryCta});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.g1, AppColors.g2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Hoş geldin! ✨",
              style: t.labelLarge?.copyWith(color: Colors.white70, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text("Kıyafetini Sanal Olarak Dene",
              style: t.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text("AI teknolojisi ile kıyafetlerin sende nasıl duracağını anında gör",
              style: t.bodyMedium?.copyWith(color: Colors.white70)),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.cta1, AppColors.cta2]),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(.15), blurRadius: 14, offset: Offset(0, 6))],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onPrimaryCta,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.auto_awesome_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Text("Hemen Başla", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
