import 'package:fashion_app/data/plan_models.dart';
import 'package:flutter/foundation.dart';


class PlanPrice {
  final double monthly;       // Aylık abonelik ücreti
  final double yearly;        // Yıllık toplam (tek çekim)
  final double? yearlyCompareAt;

  const PlanPrice({
    required this.monthly,
    required this.yearly,
    this.yearlyCompareAt,
  });
}

class PlanViewModel extends ChangeNotifier {
  BillingPeriod period = BillingPeriod.monthly;
  PlanTier? selected;

  // ÖRNEK fiyatlar — istediğin gibi düzenleyebilirsin
  final Map<PlanTier, PlanPrice> prices = const {
    PlanTier.basic:  PlanPrice(monthly: 11.9, yearly: 96,  yearlyCompareAt: 120),
    PlanTier.pro:    PlanPrice(monthly: 24.0, yearly: 216, yearlyCompareAt: 288),
    PlanTier.expert: PlanPrice(monthly: 39.0, yearly: 360, yearlyCompareAt: 468),
  };

  void setPeriod(BillingPeriod p) { period = p; notifyListeners(); }
  void select(PlanTier t) { selected = t; notifyListeners(); }

  // Ana fiyat etiketi
  String priceLabel(PlanTier t) {
   
    final p = prices[t]!;
    if (period == BillingPeriod.yearly) {
      return "₺${_fmt(p.yearly)}";
    } else {
      return "₺${_fmt(p.monthly)}/ay";
    }
  }

 

  // Yıllık ek etiket (aylık karşılığı)
  String? monthlyEquivalent(PlanTier t) {
    if (period != BillingPeriod.yearly) return null;
    final p = prices[t]!;
    final perMonth = p.yearly / 12;
    return "₺${_fmt(perMonth)}/ay";
  }

  String? compareAt(PlanTier t) {
    final p = prices[t]!;
    if (period == BillingPeriod.yearly && p.yearlyCompareAt != null) {
      return "₺${_fmt(p.yearlyCompareAt!)}";
    }
    return null;
  }

  // Aylık tarafta rozet metni
  String? trialLabel(PlanTier t) {
    if (period == BillingPeriod.yearly) return null;
    switch (t) {
      case PlanTier.basic:  return "İlk 7 gün ücretsiz";
      case PlanTier.pro:
      case PlanTier.expert: return "İlk 1 ay ücretsiz";
    }
  }

  String _fmt(double v) => v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1);
}
