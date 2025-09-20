import 'package:fashion_app/data/plan_models.dart';
import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';

class PlanPrice {
  final double monthly;
  final double yearly;
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

  /// 🇹🇷 Türkiye fiyatları (₺)
  static const Map<PlanTier, PlanPrice> _pricesTr = {
    PlanTier.basic:  PlanPrice(monthly: 99.0, yearly: 949.0, yearlyCompareAt: 1188.0),
    PlanTier.pro:    PlanPrice(monthly: 249.0, yearly: 2399.0, yearlyCompareAt: 2988.0),
    PlanTier.expert: PlanPrice(monthly: 499.0, yearly: 4799.0, yearlyCompareAt: 5988.0),
  };

  /// 🇪🇺 Avrupa fiyatları (€)
  static const Map<PlanTier, PlanPrice> _pricesEn = {
    PlanTier.basic:  PlanPrice(monthly: 4.99, yearly: 49.9, yearlyCompareAt: 59.88),
    PlanTier.pro:    PlanPrice(monthly: 9.99, yearly: 99.9, yearlyCompareAt: 119.88),
    PlanTier.expert: PlanPrice(monthly: 19.99, yearly: 199.9, yearlyCompareAt: 239.88),
  };

  /// Aktif locale’e göre doğru fiyat tablosunu seç
  Map<PlanTier, PlanPrice> get prices {
    final locale = Intl.getCurrentLocale();
    return locale.startsWith('tr') ? _pricesTr : _pricesEn;
  }

  void setPeriod(BillingPeriod p) {
    period = p;
    notifyListeners();
  }

  void select(PlanTier t) {
    selected = t;
    notifyListeners();
  }

  String priceLabel(PlanTier t) {
    final p = prices[t]!;
    final currency = tr('plans.currency');
    if (period == BillingPeriod.yearly) {
      return "$currency${_fmt(p.yearly)} ${tr('plans.period.year')}";
    } else {
      return "$currency${_fmt(p.monthly)} ${tr('plans.period.month')}";
    }
  }

  String? monthlyEquivalent(PlanTier t) {
    if (period != BillingPeriod.yearly) return null;
    final p = prices[t]!;
    final perMonth = p.yearly / 12;
    final currency = tr('plans.currency');
    return "$currency${_fmt(perMonth)} ${tr('plans.period.month')}";
  }

  String? compareAt(PlanTier t) {
    final p = prices[t]!;
    if (period == BillingPeriod.yearly && p.yearlyCompareAt != null) {
      final currency = tr('plans.currency');
      return "$currency${_fmt(p.yearlyCompareAt!)}";
    }
    return null;
  }

    String? trialLabel(PlanTier t) {
    if (period == BillingPeriod.yearly) return null;
    switch (t) {
      case PlanTier.basic:
        return tr('plans.trial.basic'); // 7 gün free
      case PlanTier.pro:
        return tr('plans.trial.pro');   // 1 ay free
      case PlanTier.expert:
        return null; // ❌ Expert için etiket yok
    }
  }


  String _fmt(double v) =>
      v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);
}
