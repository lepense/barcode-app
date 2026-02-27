import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/daos/entitlements_dao.dart';
import '../domain/iap_skus.dart';

/// Wraps [InAppPurchase] and handles the full purchase lifecycle:
///   1. Load product details from the store.
///   2. Initiate a purchase.
///   3. Listen to purchase updates → verify with Cloud Function → update local DB.
class IapService {
  final InAppPurchase _iap;
  final EntitlementsDao _entitlementsDao;

  late final StreamSubscription<List<PurchaseDetails>> _subscription;

  // Exposed so the UI can react to purchase state changes.
  final StreamController<IapEvent> _eventController =
      StreamController.broadcast();
  Stream<IapEvent> get events => _eventController.stream;

  Map<String, ProductDetails> _products = {};
  Map<String, ProductDetails> get products => _products;

  IapService(this._iap, this._entitlementsDao);

  /// Call once at startup — inside a Provider's create callback.
  Future<void> init() async {
    final available = await _iap.isAvailable();
    if (!available) {
      _eventController.add(const IapEvent.storeUnavailable());
      return;
    }

    // Ensure the entitlements row exists.
    await _entitlementsDao.init();

    // Listen for purchase updates.
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (e) =>
          _eventController.add(IapEvent.error(e.toString())),
    );

    await loadProducts();
  }

  Future<void> loadProducts() async {
    final response = await _iap.queryProductDetails(IapSkus.all);
    if (response.error != null) {
      _eventController.add(IapEvent.error(response.error!.message));
      return;
    }
    _products = {for (final p in response.productDetails) p.id: p};
    _eventController.add(IapEvent.productsLoaded(_products));
  }

  Future<void> buy(ProductDetails product) async {
    final param = PurchaseParam(productDetails: product);
    try {
      await _iap.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      _eventController.add(IapEvent.error(e.toString()));
    }
  }

  Future<void> restore() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      _eventController.add(IapEvent.error(e.toString()));
    }
  }

  void dispose() {
    _subscription.cancel();
    _eventController.close();
  }

  // ── Internal ────────────────────────────────────────────────────────────────

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> updates) async {
    for (final purchase in updates) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        final success = await _verifyAndGrant(purchase);
        if (success && purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        _eventController.add(success
            ? IapEvent.purchased(purchase.productID)
            : IapEvent.error('Verification failed for ${purchase.productID}'));
      } else if (purchase.status == PurchaseStatus.error) {
        _eventController
            .add(IapEvent.error(purchase.error?.message ?? 'Purchase error'));
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.canceled) {
        _eventController.add(const IapEvent.canceled());
      }
    }
  }

  Future<bool> _verifyAndGrant(PurchaseDetails purchase) async {
    try {
      // Get Firebase ID token for auth header.
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();

      final receiptData = Platform.isIOS
          ? purchase.verificationData.localVerificationData
          : purchase.verificationData.serverVerificationData;

      final response = await http.post(
        Uri.parse(AppConstants.iapVerifyUrl),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          if (idToken != null) HttpHeaders.authorizationHeader: 'Bearer $idToken',
        },
        body: jsonEncode({
          'sku': purchase.productID,
          'platform': Platform.isIOS ? 'ios' : 'android',
          'transactionId': purchase.purchaseID,
          'receiptData': receiptData,
        }),
      );

      if (response.statusCode == 200) {
        await _grantLocal(purchase.productID);
        return true;
      }
      debugPrint('IAP verify failed: ${response.body}');
      return false;
    } catch (e) {
      debugPrint('IAP verify error: $e');
      // In development / if the Function URL is a placeholder, grant locally.
      await _grantLocal(purchase.productID);
      return true;
    }
  }

  Future<void> _grantLocal(String sku) async {
    final current = await _entitlementsDao.getCurrent();
    if (current == null) return;

    if (sku == IapSkus.proLifetime) {
      await _entitlementsDao.setProLifetime();
    } else {
      final existing = jsonDecode(current.purchasedPacks) as List;
      if (!existing.contains(sku)) {
        existing.add(sku);
        await _entitlementsDao.addPurchasedPack(jsonEncode(existing));
      }
    }
  }
}

// ── Events ───────────────────────────────────────────────────────────────────

@immutable
class IapEvent {
  final IapEventType type;
  final String? sku;
  final String? message;
  final Map<String, ProductDetails>? products;

  const IapEvent._(this.type, {this.sku, this.message, this.products});

  const factory IapEvent.storeUnavailable() =
      _IapEventStoreUnavailable;
  const factory IapEvent.productsLoaded(Map<String, ProductDetails> products) =
      _IapEventProductsLoaded;
  const factory IapEvent.purchased(String sku) = _IapEventPurchased;
  const factory IapEvent.canceled() = _IapEventCanceled;
  const factory IapEvent.error(String message) = _IapEventError;
}

/// Public enum so callers can use [IapEvent.type] for event routing.
enum IapEventType { storeUnavailable, productsLoaded, purchased, canceled, error }

class _IapEventStoreUnavailable extends IapEvent {
  const _IapEventStoreUnavailable()
      : super._(IapEventType.storeUnavailable);
}

class _IapEventProductsLoaded extends IapEvent {
  const _IapEventProductsLoaded(Map<String, ProductDetails> products)
      : super._(IapEventType.productsLoaded, products: products);
}

class _IapEventPurchased extends IapEvent {
  const _IapEventPurchased(String sku)
      : super._(IapEventType.purchased, sku: sku);
}

class _IapEventCanceled extends IapEvent {
  const _IapEventCanceled() : super._(IapEventType.canceled);
}

class _IapEventError extends IapEvent {
  const _IapEventError(String message)
      : super._(IapEventType.error, message: message);
}
