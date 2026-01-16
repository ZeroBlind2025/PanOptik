import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/asset.dart';
import '../services/assets_service.dart';

final assetsServiceProvider = Provider<AssetsService>((ref) {
  return AssetsService();
});

final assetsProvider =
    StateNotifierProvider<AssetsNotifier, AsyncValue<List<Asset>>>((ref) {
  return AssetsNotifier(ref.watch(assetsServiceProvider));
});

class AssetsNotifier extends StateNotifier<AsyncValue<List<Asset>>> {
  final AssetsService _service;

  AssetsNotifier(this._service) : super(const AsyncValue.loading()) {
    _loadCachedAssets();
    fetchAssets();
  }

  void _loadCachedAssets() {
    final cached = _service.getCachedAssets();
    if (cached.isNotEmpty) {
      state = AsyncValue.data(cached);
    }
  }

  Future<void> fetchAssets() async {
    try {
      final assets = await _service.fetchAssets();
      state = AsyncValue.data(assets);
    } catch (e, st) {
      // Keep cached data if available
      if (state.hasValue) {
        return;
      }
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createAsset({
    required AssetType type,
    required String name,
    String? ticker,
    double? quantity,
    double? manualValue,
    double? costBasis,
    String currency = 'USD',
    String? country,
    String? sector,
    String? riskCategory,
    String? notes,
  }) async {
    final asset = await _service.createAsset(
      type: type,
      name: name,
      ticker: ticker,
      quantity: quantity,
      manualValue: manualValue,
      costBasis: costBasis,
      currency: currency,
      country: country,
      sector: sector,
      riskCategory: riskCategory,
      notes: notes,
    );

    state = AsyncValue.data([...state.valueOrNull ?? [], asset]);
  }

  Future<void> updateAsset(
    String id, {
    String? name,
    String? ticker,
    double? quantity,
    double? manualValue,
    double? costBasis,
    String? currency,
    String? country,
    String? sector,
    String? riskCategory,
    String? notes,
  }) async {
    final asset = await _service.updateAsset(
      id,
      name: name,
      ticker: ticker,
      quantity: quantity,
      manualValue: manualValue,
      costBasis: costBasis,
      currency: currency,
      country: country,
      sector: sector,
      riskCategory: riskCategory,
      notes: notes,
    );

    state = AsyncValue.data(
      state.valueOrNull
              ?.map((a) => a.id == id ? asset : a)
              .toList() ??
          [asset],
    );
  }

  Future<void> deleteAsset(String id) async {
    await _service.deleteAsset(id);

    state = AsyncValue.data(
      state.valueOrNull?.where((a) => a.id != id).toList() ?? [],
    );
  }
}

// Provider for a single asset by ID
final assetProvider = Provider.family<Asset?, String>((ref, id) {
  final assets = ref.watch(assetsProvider).valueOrNull;
  if (assets == null) return null;
  try {
    return assets.firstWhere((a) => a.id == id);
  } catch (_) {
    return null;
  }
});

// Provider for asset count
final assetCountProvider = Provider<int>((ref) {
  return ref.watch(assetsProvider).valueOrNull?.length ?? 0;
});

// Provider for total portfolio value
final totalPortfolioValueProvider = Provider<double>((ref) {
  final assets = ref.watch(assetsProvider).valueOrNull ?? [];
  return assets.fold(0.0, (sum, asset) => sum + asset.currentValue);
});
