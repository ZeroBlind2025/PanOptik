import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../services/subscription_service.dart';
import 'auth_provider.dart';

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, AsyncValue<CustomerInfo?>>((ref) {
  final service = ref.watch(subscriptionServiceProvider);
  final user = ref.watch(currentUserProvider);
  return SubscriptionNotifier(service, user?.id);
});

class SubscriptionNotifier extends StateNotifier<AsyncValue<CustomerInfo?>> {
  final SubscriptionService _service;
  final String? _userId;

  SubscriptionNotifier(this._service, this._userId)
      : super(const AsyncValue.data(null)) {
    if (_userId != null) {
      _initialize();
    }
  }

  Future<void> _initialize() async {
    if (_userId == null) return;

    try {
      await _service.initialize(_userId!);
      final customerInfo = await _service.getCustomerInfo();
      state = AsyncValue.data(customerInfo);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    try {
      final customerInfo = await _service.getCustomerInfo();
      state = AsyncValue.data(customerInfo);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> purchase(Package package) async {
    state = const AsyncValue.loading();
    try {
      final customerInfo = await _service.purchasePackage(package);
      state = AsyncValue.data(customerInfo);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> restorePurchases() async {
    state = const AsyncValue.loading();
    try {
      final customerInfo = await _service.restorePurchases();
      state = AsyncValue.data(customerInfo);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Provider for premium status
final isPremiumProvider = Provider<bool>((ref) {
  final subscription = ref.watch(subscriptionProvider).valueOrNull;
  return subscription?.entitlements.all['premium']?.isActive ?? false;
});

// Provider for offerings
final offeringsProvider = FutureProvider<Offerings>((ref) async {
  final service = ref.watch(subscriptionServiceProvider);
  return await service.getOfferings();
});
