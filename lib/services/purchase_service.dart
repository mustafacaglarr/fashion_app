// lib/services/purchase_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_app/data/plan_models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Her tier + period için AYRI productId.
/// (Play Console/App Store Connect'te birebir aynı kimliklerle oluşturulmalı)
/// Not: basic için hem 'basic_monthly' hem de eski 'basic_month' adına uyum sağlıyoruz.
const Map<(PlanTier, BillingPeriod), String> kProductIdMap = {
  (PlanTier.basic,  BillingPeriod.monthly): 'basic_monthly',
  (PlanTier.basic,  BillingPeriod.yearly):  'basic_yearly',
  (PlanTier.pro,    BillingPeriod.monthly): 'pro_monthly',
  (PlanTier.pro,    BillingPeriod.yearly):  'pro_yearly',
  (PlanTier.expert, BillingPeriod.monthly): 'expert_monthly',
  (PlanTier.expert, BillingPeriod.yearly):  'expert_yearly',
};

/// Alias desteği: mağazada farklı/eskiden kalmış id varsa da yükleyelim.
const Map<String, List<String>> kProductIdAliases = {
  'basic_monthly': ['basic_month'],
};

class PurchaseService with ChangeNotifier {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool available = false;
  bool loading = false;

  final Map<String, ProductDetails> _products = {};
  List<ProductDetails> get products => _products.values.toList(growable: false);

  /// init'in tamamlanmasını bekletmek için
  final Completer<void> _ready = Completer<void>();
  Future<void> get ready => _ready.future;

  Future<void> init() async {
    loading = true;
    notifyListeners();

    try {
      available = await _iap.isAvailable();

      if (available) {
        // Sorgulanacak tüm kimlikler: kanonik + alias’lar
        final productIds = <String>{
          ...kProductIdMap.values,
          ...kProductIdAliases.values.expand((l) => l),
        };

        final resp = await _iap.queryProductDetails(productIds);

        // Gelenleri sakla
        for (final p in resp.productDetails) {
          _products[p.id] = p;
        }

        if (resp.notFoundIDs.isNotEmpty) {
          debugPrint('Bulunamayan productId’ler: ${resp.notFoundIDs}');
        }

        // Satın alma akışı dinleyicisi
        _sub = _iap.purchaseStream.listen(
          _onPurchaseUpdated,
          onDone: () => _sub?.cancel(),
          onError: (e) => debugPrint('purchaseStream error: $e'),
        );
      }
    } finally {
      if (!_ready.isCompleted) _ready.complete();
      loading = false;
      notifyListeners();
    }
  }

  ProductDetails? _productFor(PlanTier tier, BillingPeriod period) {
    final canonicalId = kProductIdMap[(tier, period)];
    if (canonicalId == null) return null;

    // Önce kanonik id ile dene
    final direct = _products[canonicalId];
    if (direct != null) return direct;

    // Alias’ları dene (ör. basic_monthly → basic_month)
    final aliases = kProductIdAliases[canonicalId] ?? const [];
    for (final aid in aliases) {
      final pd = _products[aid];
      if (pd != null) return pd;
    }
    return null;
  }

  /// Kullanıcının seçtiği tier + period için DOĞRUDAN o productId'i satın al.
  Future<void> buyFor(PlanTier tier, BillingPeriod period) async {
    // init’in tamamlanmasını garanti et
    await ready;

    if (!available) {
      throw Exception('Mağaza şu an kullanılamıyor (InAppPurchase.available = false).');
    }

    var details = _productFor(tier, period);
    if (details == null) {
      // queryProductDetails çok yeni dönmüş olabilir; kısa bekleyip tekrar dene
      details = await _waitForProduct(tier, period, timeout: const Duration(seconds: 3));
    }

    if (details == null) {
      final canonicalId = kProductIdMap[(tier, period)];
      final aliases = kProductIdAliases[canonicalId] ?? const [];
      final tried = [if (canonicalId != null) canonicalId, ...aliases].whereType<String>().toList();
      throw Exception(
        'Ürün detayları yok ya da eşleşen productId bulunamadı. '
        'Denediğim kimlikler: $tried. Lütfen ürün kimliklerinin mağazada TANIMLI olduğundan emin olun.'
      );
    }

    final param = PurchaseParam(productDetails: details);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restore() async {
    await _iap.restorePurchases();
  }

  Future<ProductDetails?> _waitForProduct(
    PlanTier tier,
    BillingPeriod period, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      final d = _productFor(tier, period);
      if (d != null) return d;
      await Future.delayed(const Duration(milliseconds: 120));
    }
    return null;
  }

  Future<void> _onPurchaseUpdated(List<PurchaseDetails> detailsList) async {
    for (final d in detailsList) {
      try {
        switch (d.status) {
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            final tier = _resolveTierFromProductId(d.productID);

            // UI/analitik için trial etiketi (gerçek yetki mağazada)
            final nowUtc = DateTime.now().toUtc();
            final trialDays = _trialDaysFor(tier, d.productID);
            final trialEndsAt = trialDays > 0 ? nowUtc.add(Duration(days: trialDays)) : null;

            await _setEntitlementOnFirestore(
              tier: tier,
              state: trialDays > 0 ? 'trial' : 'active',
              trialEndsAt: trialEndsAt,
              // receiptRaw: d.verificationData.serverVerificationData,
              // source: defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
            );

            if (d.pendingCompletePurchase) {
              await _iap.completePurchase(d);
            }
            break;

          case PurchaseStatus.error:
            debugPrint('Purchase error: ${d.error}');
            break;

          case PurchaseStatus.pending:
            // bekle
            break;

          case PurchaseStatus.canceled:
            // kullanıcı iptal etti
            break;
        }
      } catch (e, st) {
        debugPrint('onPurchaseUpdated exception: $e\n$st');
      }
    }
  }

  /// productId → tier
  String _resolveTierFromProductId(String productId) {
    if (productId.startsWith('basic_'))  return 'basic';
    if (productId.startsWith('pro_'))    return 'pro';
    if (productId.startsWith('expert_')) return 'expert';
    return 'basic';
  }

  /// Trial günleri (mağazadaki ayarlarla birebir eşleşmeli!)
  /// İstek: YILLIKTA TRIAL YOK.
  int _trialDaysFor(String tier, String productId) {
    final isYearly = productId.endsWith('_yearly');
    if (isYearly) return 0;

    switch (tier) {
      case 'basic':  return 7;   // basic_monthly/basic_month → 7 gün
      case 'pro':    return 30;  // pro_monthly → 30 gün
      case 'expert': return 0;   // expert_monthly → trialsız
      default:       return 0;
    }
  }

  Future<void> _setEntitlementOnFirestore({
    required String tier,
    required String state, // 'trial' | 'active'
    DateTime? trialEndsAt,
    String? receiptRaw,
    String? source,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Kullanıcı oturumu yok');

    final data = <String, dynamic>{
      'plan': tier,
      'updatedAt': FieldValue.serverTimestamp(),
      'entitlement': {
        'tier': tier,
        'state': state,
        if (trialEndsAt != null) 'trialEndsAt': Timestamp.fromDate(trialEndsAt),
        if (source != null) 'platform': source,
      },
      if (receiptRaw != null) 'receipt': {'raw': receiptRaw},
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(data, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
