import 'package:fashion_app/ui/pages/tryon_wizard_view.dart.dart';
import 'package:flutter/material.dart';
import '../style/app_colors.dart';
import '../widgets/hero_section.dart';
import '../widgets/stat_card.dart';
import '../widgets/feature_grid.dart';
import '../widgets/how_it_works.dart';
import '../widgets/cta_banner.dart';
import '../widgets/bottom_nav.dart'; // yolu sende farklıysa düzelt

class LandingView extends StatelessWidget {
  const LandingView({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            HeroSection(onPrimaryCta: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TryOnWizardView()));
            }),
            const SizedBox(height: 16),
            Row(children: const [
              Expanded(child: StatCard(icon: Icons.groups_rounded, number: "50K+", label: "Aktif Kullanıcı")),
              SizedBox(width: 10),
              Expanded(child: StatCard(icon: Icons.favorite_rounded, number: "1M+", label: "Denenen Kıyafet")),
              SizedBox(width: 10),
              Expanded(child: StatCard(icon: Icons.trending_up_rounded, number: "99%", label: "Memnuniyet")),
            ]),
            const SizedBox(height: 24),
            Text("Neler Yapabilirsiniz?", style: t.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            const FeatureGrid(),
            const SizedBox(height: 24),
            Text("Nasıl Çalışır?", style: t.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            const HowItWorks(),
            const SizedBox(height: 18),
            CtaBanner(
              title: "Hemen Dene!",
              subtitle: "İlk denemen ücretsiz. Kıyafetlerin sende nasıl duracağını gör.",
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TryOnWizardView())),
            ),
          ],
        ),
      ),
      bottomNavigationBar: LandingBottomNav(
        onTryNow: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TryOnWizardView())),
      ),
    );
  }
}
