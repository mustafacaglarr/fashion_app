import 'package:fashion_app/data/plan_models.dart';
import 'package:fashion_app/services/purchase_service.dart';
import 'package:fashion_app/ui/viewmodels/plan_viewmodel.dart';
import 'package:fashion_app/ui/widgets/billing_toggle.dart';
import 'package:fashion_app/ui/widgets/plan_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

class PlanView extends StatelessWidget {
  const PlanView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlanViewModel>();

    // Tier etiketi (snackbar için lokalize ad)
    String tierLabel(PlanTier t) {
      switch (t) {
        case PlanTier.basic:  return tr('plans.tiers.basic');
        case PlanTier.pro:    return tr('plans.tiers.pro');
        case PlanTier.expert: return tr('plans.tiers.expert');
      }
    }

    // CTA metni: Basic için "Start free", diğerleri için "7-day trial"
    final String ctaText = switch (vm.selected) {
      null            => tr('plans.cta.select_plan'),
      PlanTier.basic  => tr('plans.cta.start_free'),
      PlanTier.pro    => tr('plans.cta.start_7day_trial'),
      PlanTier.expert => tr('plans.cta.buy_now'),
    };



    // Bullet listeleri
    final basicBullets  = List.generate(5, (i) => tr('plans.basic.bullets.$i'));
    final proBullets    = List.generate(6, (i) => tr('plans.pro.bullets.$i'));
    final expertBullets = List.generate(6, (i) => tr('plans.expert.bullets.$i'));

    return Scaffold(
      appBar: AppBar(title: Text(tr('plans.title_upgrade'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          BillingToggle(value: vm.period, onChanged: vm.setPeriod),
          const SizedBox(height: 16),

          // BASIC — FREE
          PlanCard(
            tier: PlanTier.basic,
            title: tr('plans.basic.title'),
            description: tr('plans.basic.description'),
            bullets: basicBullets,
            price: vm.priceLabel(PlanTier.basic),
            compareAt: vm.compareAt(PlanTier.basic),
            trial: vm.trialLabel(PlanTier.basic),
            monthlyEq: vm.monthlyEquivalent(PlanTier.basic),
            selected: vm.selected == PlanTier.basic,
            onTap: () => vm.select(PlanTier.basic),
          ),
          const SizedBox(height: 12),

          // PRO — highlight
          PlanCard(
            tier: PlanTier.pro,
            title: tr('plans.pro.title'),
            description: tr('plans.pro.description'),
            bullets: proBullets,
            price: vm.priceLabel(PlanTier.pro),
            compareAt: vm.compareAt(PlanTier.pro),
            trial: vm.trialLabel(PlanTier.pro),
            monthlyEq: vm.monthlyEquivalent(PlanTier.pro),
            selected: vm.selected == PlanTier.pro,
            highlight: true,
            onTap: () => vm.select(PlanTier.pro),
          ),
          const SizedBox(height: 12),

          // EXPERT
          PlanCard(
            tier: PlanTier.expert,
            title: tr('plans.expert.title'),
            description: tr('plans.expert.description'),
            bullets: expertBullets,
            price: vm.priceLabel(PlanTier.expert),
            compareAt: vm.compareAt(PlanTier.expert),
            trial: vm.trialLabel(PlanTier.expert),
            monthlyEq: vm.monthlyEquivalent(PlanTier.expert),
            selected: vm.selected == PlanTier.expert,
            onTap: () => vm.select(PlanTier.expert),
          ),

          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3,
              ),
              onPressed: vm.selected == null
                  ? null
                  : () async {
                      final chosen = vm.selected!;
                      final period = vm.period;
                      final purchase = context.read<PurchaseService>();

                      try {
                        await purchase.buyFor(chosen, period);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              tr('plans.snack.purchase_started', namedArgs: {
                                'tier': tierLabel(chosen),
                              }),
                            ),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              tr('plans.snack.purchase_error', namedArgs: {
                                'error': e.toString(),
                              }),
                            ),
                          ),
                        );
                      }
                    },
              child: Text(
                ctaText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
