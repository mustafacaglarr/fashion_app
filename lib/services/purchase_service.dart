import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

// Play Console ürün ID'lerinizle eşleştirin:
const kProductIds = <String>{
  'yearly_premium',  // yıllık
  'monthly_premium', // aylık
  'weekly_premium',  // haftalık
};

class PurchaseService with ChangeNotifier {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool available = false;
  bool loading = false;

  // Sorgulanan ürünler:
  Map<String, ProductDetails> products = {};

  Future<void> init() async {
    loading = true; notifyListeners();

    available = await _iap.isAvailable();

    if (available) {
      final resp = await _iap.queryProductDetails(kProductIds);
      products = { for (var p in resp.productDetails) p.id : p };

      _sub = _iap.purchaseStream.listen(_onPurchaseUpdated, onDone: () {
        _sub?.cancel();
      }, onError: (e) {
        debugPrint("purchaseStream error: $e");
      });
    }

    loading = false; notifyListeners();
  }

  ProductDetails? getById(String id) => products[id];

  Future<void> buy(ProductDetails p) async {
    final param = PurchaseParam(productDetails: p);
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
          if (!d.pendingCompletePurchase) {
            await _iap.completePurchase(d);
          }
          // TODO: Sunucu tarafında doğrulama + kullanıcıya premium atama
          break;
        case PurchaseStatus.error:
          debugPrint("Purchase error: ${d.error}");
          break;
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.canceled:
          break;
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
