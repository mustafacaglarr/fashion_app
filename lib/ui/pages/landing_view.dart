import 'package:fashion_app/ui/pages/tryon_wizard_view.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart'; // ⬅️ eklendi
import '../style/app_colors.dart';
import '../widgets/hero_section.dart';
import '../widgets/stat_card.dart';
import '../widgets/feature_grid.dart';
import '../widgets/how_it_works.dart';
import '../widgets/cta_banner.dart';
import '../widgets/bottom_nav.dart';

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
            HeroSection(
              onPrimaryCta: () => TryOnWizardView.open(context),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: StatCard(
                  icon: Icons.groups_rounded,
                  number: "10K+",
                  label: tr('home.stats.active_users'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  icon: Icons.favorite_rounded,
                  number: "700K+",
                  label: tr('home.stats.outfits_tried'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  icon: Icons.trending_up_rounded,
                  number: "99%",
                  label: tr('home.stats.satisfaction'),
                ),
              ),
            ]),
            const SizedBox(height: 24),
            Text(
              tr('home.sections.what_can_you_do'),
              style: t.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            const FeatureGrid(),
            const SizedBox(height: 24),
            Text(
              tr('home.sections.how_it_works'),
              style: t.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            const HowItWorks(),
            const SizedBox(height: 18),
            CtaBanner(
              title: tr('home.cta.title'),
              subtitle: tr('home.cta.subtitle'),
              onTap: () => TryOnWizardView.open(context),
            ),
          ],
        ),
      ),
      bottomNavigationBar: LandingBottomNav(
        onTryNow: () => TryOnWizardView.open(context),
      ),
    );
  }
}
