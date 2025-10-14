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
    PlanTier.basic:  PlanPrice(monthly: 89.90, yearly: 949.90, yearlyCompareAt: 1078.0),
    PlanTier.pro:    PlanPrice(monthly: 249.90, yearly: 2399.90, yearlyCompareAt: 2998.0),
    PlanTier.expert: PlanPrice(monthly: 499.90, yearly: 4799.90, yearlyCompareAt: 5998.0),
  };

  /// 🇪🇺 Avrupa fiyatları (€)
  static const Map<PlanTier, PlanPrice> _pricesEn = {
    PlanTier.basic:  PlanPrice(monthly: 5.99, yearly: 59.99, yearlyCompareAt: 71.88),
    PlanTier.pro:    PlanPrice(monthly: 11.99, yearly: 119.99, yearlyCompareAt: 143.88),
    PlanTier.expert: PlanPrice(monthly: 23.99, yearly: 239.99, yearlyCompareAt: 287.88),
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
