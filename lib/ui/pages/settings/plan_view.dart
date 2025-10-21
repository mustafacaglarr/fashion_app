import 'package:fashion_app/data/plan_models.dart';
import 'package:fashion_app/services/purchase_service.dart';
import 'package:fashion_app/ui/viewmodels/plan_viewmodel.dart';
import 'package:fashion_app/ui/widgets/billing_toggle.dart';
import 'package:fashion_app/ui/widgets/plan_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

// ⬇️ Global navigator key için ekle
import 'package:fashion_app/app_keys.dart';

class PlanView extends StatelessWidget {
  const PlanView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlanViewModel>();
    final purchase = context.watch<PurchaseService>(); // <-- PurchaseService state’i dinle

    // ⬇️ Her geri aksiyonunda gidilecek yer
    void goLanding() {
      // Route adını projendeki landing route’u ile eşleştir.
      // Eğer named route kullanmıyorsan:
      // appNavigatorKey.currentState?.pushAndRemoveUntil(
      //   MaterialPageRoute(builder: (_) => const LandingView()),
      //   (_) => false,
      // );
      appNavigatorKey.currentState?.pushNamedAndRemoveUntil('/home', (_) => false);
    }

    // Tier etiketi (snackbar için lokalize ad)
    String tierLabel(PlanTier t) {
      switch (t) {
        case PlanTier.basic:  return tr('plans.tiers.basic');
        case PlanTier.pro:    return tr('plans.tiers.pro');
        case PlanTier.expert: return tr('plans.tiers.expert');
      }
    }

    // Seçilen tier+period için ürünün yüklenip yüklenmediğini kontrol et
    bool _productLoadedFor(PlanTier t, BillingPeriod p) {
      final canonicalId = kProductIdMap[(t, p)];
      if (canonicalId == null) return false;
      final aliases = kProductIdAliases[canonicalId] ?? const <String>[];
      final loadedIds = purchase.products.map((e) => e.id).toSet();
      if (loadedIds.contains(canonicalId)) return true;
      for (final a in aliases) {
        if (loadedIds.contains(a)) return true;
      }
      return false;
    }

    // CTA metni: period + tier'a göre
    final String ctaText = () {
      if (vm.selected == null) return tr('plans.cta.select_plan');

      final t = vm.selected!;
      final p = vm.period;

      if (p == BillingPeriod.yearly) {
        // Yıllıkta trial yok → buy now
        return tr('plans.cta.buy_now');
      }

      // Monthly
      switch (t) {
        case PlanTier.basic:
          return tr('plans.cta.start_7day_trials');   // "Start 7-day free trial"
        case PlanTier.pro:
          return tr('plans.cta.start_14day_trial');   // "Start 30-day free trial" (14 değil, 30)
        case PlanTier.expert:
          return tr('plans.cta.buy_now');             // Expert'te trial yok
      }
    }();

    // Buton aktif/pasif koşulu
    final bool hasSelection = vm.selected != null;
    final bool productReady = hasSelection && _productLoadedFor(vm.selected!, vm.period);
    final bool serviceReady = purchase.available && !purchase.loading;
    final bool canPress = hasSelection && serviceReady && productReady;

    // Bullet listeleri
    final basicBullets  = List.generate(5, (i) => tr('plans.basic.bullets.$i'));
    final proBullets    = List.generate(6, (i) => tr('plans.pro.bullets.$i'));
    final expertBullets = List.generate(6, (i) => tr('plans.expert.bullets.$i'));

    return PopScope(
      // Geri hareketini biz yöneteceğiz (Android back, iOS swipe, AppBar back)
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return; // sistem zaten pop ettiyse dokunma
        goLanding();        // aksi halde landing’e yönlendir
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr('plans.title_upgrade')),
          // AppBar geri oku: her zaman landing’e götür
          leading: BackButton(onPressed: goLanding),
        ),
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

            // Bilgi satırı (isteğe bağlı): mağaza ve ürün durumunu kullanıcıya göster
            if (purchase.loading || !purchase.available || (hasSelection && !productReady))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  purchase.loading
                      ? tr('plans.info.store_loading')            // "Mağaza yükleniyor…"
                      : (!purchase.available
                          ? tr('plans.info.store_unavailable')     // "Mağaza şu anda kullanılamıyor."
                          : tr('plans.info.product_preparing')),   // "Seçtiğiniz plan hazırlanıyor…"
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ),

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
                onPressed: !canPress
                    ? null
                    : () async {
                        final chosen = vm.selected!;
                        final period = vm.period;

                        try {
                          // init’in tamamlanmış olduğundan emin ol
                          await purchase.ready;
                          await purchase.buyFor(chosen, period);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  tr('plans.snack.purchase_started', namedArgs: {
                                    'tier': tierLabel(chosen),
                                  }),
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
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
                        }
                      },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (purchase.loading) ...[
                      const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      ctaText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
