import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One-time (non-consumable) product. Create this EXACT ID in
/// Play Console > Monetize > In-app products, price P490.
/// Change the string here if you pick a different ID.
const String kLifetimeProductId = 'bigasan_lifetime';

/// Length of the free trial.
const int kTrialDays = 30;

/// Shown if the store price can't be loaded yet.
const String kFallbackPrice = '₱490';

class BillingProvider extends ChangeNotifier {
  static const _kTrialStart = 'trial_start_ms';
  static const _kLastSeen = 'trial_last_seen_ms';
  static const _kPurchased = 'lifetime_purchased';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool loaded = false;
  bool purchased = false;
  bool storeAvailable = false;
  bool busy = false;
  String? error;
  ProductDetails? product;
  DateTime? _trialStart;

  /// In-app purchases don't exist on web, so the purchase is Android-only.
  bool get canPurchase => !kIsWeb && storeAvailable && product != null;

  String get priceLabel => product?.price ?? kFallbackPrice;

  int get daysLeft {
    if (_trialStart == null) return kTrialDays;
    final used = DateTime.now().difference(_trialStart!).inDays;
    final left = kTrialDays - used;
    return left < 0 ? 0 : left;
  }

  bool get trialActive => !purchased && daysLeft > 0;
  bool get hasAccess => purchased || trialActive;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;

    purchased = prefs.getBool(_kPurchased) ?? false;

    // Start the trial on first launch.
    var startMs = prefs.getInt(_kTrialStart);
    if (startMs == null) {
      startMs = now;
      await prefs.setInt(_kTrialStart, startMs);
    }

    // Basic clock-rollback protection: never let "now" go backwards.
    final lastSeen = prefs.getInt(_kLastSeen) ?? now;
    if (now < lastSeen) {
      // Clock was turned back: shift the start back by the same amount.
      startMs -= (lastSeen - now);
    } else {
      await prefs.setInt(_kLastSeen, now);
    }
    _trialStart = DateTime.fromMillisecondsSinceEpoch(startMs);

    loaded = true;
    notifyListeners();

    if (!kIsWeb) await _initStore();
  }

  Future<void> _initStore() async {
    try {
      storeAvailable = await _iap.isAvailable();
      if (!storeAvailable) {
        notifyListeners();
        return;
      }
      _sub = _iap.purchaseStream.listen(
        _onPurchases,
        onError: (e) {
          error = e.toString();
          busy = false;
          notifyListeners();
        },
      );
      final res = await _iap.queryProductDetails({kLifetimeProductId});
      if (res.productDetails.isNotEmpty) {
        product = res.productDetails.first;
      }
      notifyListeners();
      // Re-detect an earlier purchase after reinstall / new phone.
      await _iap.restorePurchases();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> buy() async {
    if (!canPurchase || busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product!),
      );
    } catch (e) {
      error = e.toString();
      busy = false;
      notifyListeners();
    }
  }

  Future<void> restore() async {
    if (kIsWeb || !storeAvailable) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await _iap.restorePurchases();
    } catch (e) {
      error = e.toString();
    }
    // Give the stream a moment; if nothing arrives, stop the spinner.
    Future.delayed(const Duration(seconds: 4), () {
      if (busy) {
        busy = false;
        if (!purchased) error = 'No previous purchase found for this Google account.';
        notifyListeners();
      }
    });
  }

  Future<void> _onPurchases(List<PurchaseDetails> list) async {
    for (final p in list) {
      if (p.productID != kLifetimeProductId) continue;
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _unlock();
          break;
        case PurchaseStatus.error:
          error = p.error?.message ?? 'Purchase failed.';
          busy = false;
          break;
        case PurchaseStatus.canceled:
          busy = false;
          break;
        case PurchaseStatus.pending:
          busy = true;
          break;
      }
      // Required: acknowledge the purchase or Google refunds it after 3 days.
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
    }
    notifyListeners();
  }

  Future<void> _unlock() async {
    purchased = true;
    busy = false;
    error = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPurchased, true);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
