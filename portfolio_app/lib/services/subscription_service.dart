import 'package:purchases_flutter/purchases_flutter.dart';

import '../config/environment.dart';
import 'api_service.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final _api = ApiService();
  bool _initialized = false;

  Future<void> initialize(String userId) async {
    if (_initialized) return;

    await Purchases.configure(
      PurchasesConfiguration(Environment.revenueCatApiKey)
        ..appUserID = userId,
    );

    _initialized = true;
  }

  // Get available offerings
  Future<Offerings> getOfferings() async {
    return await Purchases.getOfferings();
  }

  // Purchase a package
  Future<CustomerInfo> purchasePackage(Package package) async {
    final customerInfo = await Purchases.purchasePackage(package);

    // Sync with backend
    await _syncEntitlementWithBackend(customerInfo);

    return customerInfo;
  }

  // Restore purchases
  Future<CustomerInfo> restorePurchases() async {
    final customerInfo = await Purchases.restorePurchases();

    // Sync with backend
    await _syncEntitlementWithBackend(customerInfo);

    return customerInfo;
  }

  // Check if user has premium entitlement
  Future<bool> checkPremiumEntitlement() async {
    final customerInfo = await Purchases.getCustomerInfo();
    return customerInfo.entitlements.all['premium']?.isActive ?? false;
  }

  // Get customer info
  Future<CustomerInfo> getCustomerInfo() async {
    return await Purchases.getCustomerInfo();
  }

  // Sync entitlement status with backend
  Future<void> _syncEntitlementWithBackend(CustomerInfo customerInfo) async {
    final isPremium = customerInfo.entitlements.all['premium']?.isActive ?? false;

    try {
      await _api.post('/subscriptions/sync', data: {
        'revenuecatId': customerInfo.originalAppUserId,
        'isPremium': isPremium,
        'expiresAt': customerInfo.entitlements.all['premium']?.expirationDate,
      });
    } catch (e) {
      // Log error but don't fail - backend webhook will eventually sync
    }
  }
}
