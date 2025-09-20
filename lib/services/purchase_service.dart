// lib/services/purchase_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_app/data/plan_models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Mağazadaki abonelik productId’lerinle birebir aynı olmalı.
/// Örnek: Play Console / App Store Connect’te oluşturdukların:
/// - basic_monthly  (7 gün trial)
/// - pro_monthly    (30 gün trial)
/// - pro_yearly     (30 gün trial)  → istersen
/// - expert_monthly (trialsız)
/// - expert_yearly  (trialsız)      → istersen
const Map<(PlanTier, BillingPeriod), String> kProductIdMap = {
  (PlanTier.basic,  BillingPeriod.monthly): 'basic_monthly',
  // (PlanTier.basic,  BillingPeriod.yearly):  'basic_yearly', // varsa aç
  (PlanTier.pro,    BillingPeriod.monthly): 'pro_monthly',
  (PlanTier.pro,    BillingPeriod.yearly):  'pro_yearly',
  (PlanTier.expert, BillingPeriod.monthly): 'expert_monthly',
  (PlanTier.expert, BillingPeriod.yearly):  'expert_yearly',
};

class PurchaseService with ChangeNotifier {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool available = false;
  bool loading = false;

  /// Sorgulanan ürünler (id -> details)
  final Map<String, ProductDetails> _products = {};
  List<ProductDetails> get products => _products.values.toList(growable: false);

  Future<void> init() async {
    loading = true; notifyListeners();

    available = await _iap.isAvailable();
    if (available) {
      final productIds = kProductIdMap.values.toSet();
      final resp = await _iap.queryProductDetails(productIds);

      for (final p in resp.productDetails) {
        _products[p.id] = p;
      }
      if (resp.notFoundIDs.isNotEmpty) {
        debugPrint('Bulunamayan productId’ler: ${resp.notFoundIDs}');
      }

      _sub = _iap.purchaseStream.listen(
        _onPurchaseUpdated,
        onDone: () => _sub?.cancel(),
        onError: (e) => debugPrint('purchaseStream error: $e'),
      );
    }

    loading = false; notifyListeners();
  }

  ProductDetails? _productFor(PlanTier tier, BillingPeriod period) {
    final id = kProductIdMap[(tier, period)];
    if (id == null) return null;
    return _products[id];
  }

  /// Hepsi ücretli: Basic/Pro/Expert için mağaza akışını aç.
  Future<void> buyFor(PlanTier tier, BillingPeriod period) async {
    final details = _productFor(tier, period);
    if (details == null) {
      throw Exception('Ürün detayları yüklenmedi ya da eşleşen productId yok.');
    }

    final param = PurchaseParam(productDetails: details);
    // Aboneliklerde de in_app_purchase şu anda buyNonConsumable kullanıyor (SDK tasarımı böyle).
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restore() async {
    await _iap.restorePurchases();
  }

  Future<void> _onPurchaseUpdated(List<PurchaseDetails> detailsList) async {
    for (final d in detailsList) {
      try {
        switch (d.status) {
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored: {
            final tier = _resolveTierFromProductId(d.productID); // 'basic' | 'pro' | 'expert'

            // UI/analitik için trial bitişini yaz (gerçek yetki mağazada)
            final nowUtc = DateTime.now().toUtc();
            final trialDays = _trialDaysFor(tier);
            final trialEndsAt = trialDays > 0 ? nowUtc.add(Duration(days: trialDays)) : null;

            await _setEntitlementOnFirestore(
              tier: tier,
              state: trialDays > 0 ? 'trial' : 'active',
              trialEndsAt: trialEndsAt,
              // İstersen makbuz verisini de saklayabilirsin:
              // receiptRaw: d.verificationData.serverVerificationData,
              // source: defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
            );

            if (d.pendingCompletePurchase) {
              await _iap.completePurchase(d);
            }
            break;
          }

          case PurchaseStatus.error:
            debugPrint('Purchase error: ${d.error}');
            break;

          case PurchaseStatus.pending:
            // İstersen loading gösterebilirsin
            break;

          case PurchaseStatus.canceled:
            // Kullanıcı iptal etti
            break;
        }
      } catch (e, st) {
        debugPrint('onPurchaseUpdated exception: $e\n$st');
      }
    }
  }

  /// productId -> tier
  String _resolveTierFromProductId(String productId) {
    if (productId.startsWith('basic_'))  return 'basic';
    if (productId.startsWith('pro_'))    return 'pro';
    if (productId.startsWith('expert_')) return 'expert';
    // güvenli varsayılan: basic
    return 'basic';
  }

  /// Trial günleri (UI/analitik için). Mağazadaki trial ile eşleşmeli!
  int _trialDaysFor(String tier) {
    switch (tier) {
      case 'basic':  return 7;   // Basic → 7 gün
      case 'pro':    return 30;  // Pro   → 30 gün
      case 'expert': return 0;   // Expert→ trialsız
      default:       return 0;
    }
  }

  /// Firestore'a plan + entitlement yaz.
  Future<void> _setEntitlementOnFirestore({
    required String tier,             // 'basic' | 'pro' | 'expert'
    required String state,            // 'trial' | 'active'
    DateTime? trialEndsAt,
    String? receiptRaw,
    String? source,                   // 'android' | 'ios' (opsiyonel)
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Kullanıcı oturumu yok');

    final data = <String, dynamic>{
      'plan': tier,
      'updatedAt': FieldValue.serverTimestamp(),
      'entitlement': {
        'tier': tier,
        'state': state, // 'trial' veya 'active'
        if (trialEndsAt != null) 'trialEndsAt': Timestamp.fromDate(trialEndsAt),
        if (source != null) 'platform': source,
      },
      if (receiptRaw != null) 'receipt': {'raw': receiptRaw},
    };

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      data,
      SetOptions(merge: true),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
