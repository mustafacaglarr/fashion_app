import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_app/data/plan_models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';


/// ⬇️ BU HARİTA: Play Console’daki productId’lerle birebir eşleşmeli.
/// Önerilen ID’ler:
/// pro_monthly, pro_yearly, expert_monthly, expert_yearly
/// Basic ücretsiz olduğu için satın alma açmıyoruz.
const Map<(PlanTier, BillingPeriod), String> kProductIdMap = {
  (PlanTier.pro, BillingPeriod.monthly): 'pro_monthly',
  (PlanTier.pro, BillingPeriod.yearly):  'pro_yearly',
  (PlanTier.expert, BillingPeriod.monthly): 'expert_monthly',
  (PlanTier.expert, BillingPeriod.yearly):  'expert_yearly',
};

class PurchaseService with ChangeNotifier {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool available = false;
  bool loading = false;

  /// Sorgulanan ürünler
  final Map<String, ProductDetails> _products = {};

  Future<void> init() async {
    loading = true; notifyListeners();

    available = await _iap.isAvailable();
    if (available) {
      // Olası tüm productId’leri çıkar
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

  /// UI’dan çağır: Basic (aylık) ise doğrudan planı set et,
  /// Pro/Expert için Play satın alma aç.
  Future<void> buyFor(PlanTier tier, BillingPeriod period) async {
    // Basic ücretsiz senaryo
    if (tier == PlanTier.basic && period == BillingPeriod.monthly) {
      await _setPlanOnFirestore('basic');
      return;
    }

    final details = _productFor(tier, period);
    if (details == null) {
      throw Exception('Ürün detayları yüklenmedi ya da eşleşen productId yok.');
    }

    final param = PurchaseParam(productDetails: details);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restore() async {
    await _iap.restorePurchases();
  }

  Future<void> _onPurchaseUpdated(List<PurchaseDetails> detailsList) async {
    for (final d in detailsList) {
      switch (d.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // Firestore’a plan yaz
          final tier = _resolveTierFromProductId(d.productID);
          await _setPlanOnFirestore(tier);

          // Satın almayı tamamla (ack)
          if (d.pendingCompletePurchase) {
            await _iap.completePurchase(d);
          }
          break;

        case PurchaseStatus.error:
          debugPrint('Purchase error: ${d.error}');
          break;

        case PurchaseStatus.pending:
          // istersen loading gösterebilirsin
          break;

        case PurchaseStatus.canceled:
          // kullanıcı iptal etti
          break;
      }
    }
  }

  String _resolveTierFromProductId(String productId) {
    // productId → plan
    if (productId.startsWith('pro_')) return 'pro';
    if (productId.startsWith('expert_')) return 'expert';
    // güvenli varsayılan
    return 'basic';
  }

  Future<void> _setPlanOnFirestore(String plan) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Kullanıcı oturumu yok');

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'plan': plan, // 'basic' | 'pro' | 'expert'
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
      // ileride backend doğrulaması için saklayabilirsin:
      // 'lastReceipt': {...}
    }, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
