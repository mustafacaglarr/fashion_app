import 'package:fashion_app/data/plan_models.dart';
import 'package:fashion_app/services/purchase_service.dart';
import 'package:fashion_app/ui/viewmodels/plan_viewmodel.dart';
import 'package:fashion_app/ui/widgets/billing_toggle.dart';
import 'package:fashion_app/ui/widgets/plan_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PlanView extends StatelessWidget {
  const PlanView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlanViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("Planını Yükselt")),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          BillingToggle(value: vm.period, onChanged: vm.setPeriod),
          const SizedBox(height: 16),

          // BASIC — Üstte ve ÜCRETSİZ etiketiyle
          PlanCard(
            tier: PlanTier.basic,
            title: "Basic",
            description: "Kişisel kullanım ve denemeler için ekonomik paket.",
            bullets: const [
              "Standart kalite",
              "Normal hız",
              "Aylık 100 deneme",
              "Kişisel kullanım",
              "E-posta desteği",
            ],
            price: vm.priceLabel(PlanTier.basic),        // ⇦ "Ücretsiz"
            compareAt: vm.compareAt(PlanTier.basic),
            trial: vm.trialLabel(PlanTier.basic),         // ⇦ "İlk 7 gün ücretsiz"
            monthlyEq: vm.monthlyEquivalent(PlanTier.basic),    // ⇦ "7 günden sonra ₺xx/ay"
            selected: vm.selected == PlanTier.basic,
            onTap: () => vm.select(PlanTier.basic),
          ),
          const SizedBox(height: 12),

          // PRO — öne çıkar
         PlanCard(
          tier: PlanTier.pro,
          title: "Pro",
          description: "Yoğun kullanıcılar için ideal orta seviye.",
          bullets: const [
            "Yüksek kalite",
            "Hızlı sonuç",
            "Aylık 500 deneme",
            "Sınırlı ticari kullanım",
            "Öncelikli destek",
          ],
          price: vm.priceLabel(PlanTier.pro),
          compareAt: vm.compareAt(PlanTier.pro),
          trial: vm.trialLabel(PlanTier.pro),
          monthlyEq: vm.monthlyEquivalent(PlanTier.pro),
          selected: vm.selected == PlanTier.pro,
          highlight: true, // 👈 Pro’yu turuncu yapar
          onTap: () => vm.select(PlanTier.pro),
        ),

          const SizedBox(height: 12),

          // EXPERT
          PlanCard(
            tier: PlanTier.expert,
            title: "Expert",
            description: "En yüksek kalite, öncelikli hız ve tam ticari haklar.",
            bullets: const [
              "En iyi kalite",
              "Çok hızlı sonuç",
              "Tüm stiller sınırsız",
              "Tam ticari kullanım",
              "5 ekip üyesi",
            ],
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
                backgroundColor: Colors.teal, // ✅ güven verici yeşil
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3, // hafif gölge
              ),
              onPressed: vm.selected == null ? null : () async {
                  final chosen = vm.selected!;
                  final period = vm.period;

                  final purchase = context.read<PurchaseService>();

                  try {
                    await purchase.buyFor(chosen, period);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("${chosen.name.toUpperCase()} için işlem başlatıldı.")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Satın alma hatası: $e")),
                    );
                  }
                },

              child: const Text(
                "Ücretsiz Denemeyi Başlat",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),

        ],
      ),
    );
  }
}
