import 'package:hive/hive.dart';

import '../models/asset.dart';
import 'api_service.dart';

class AssetsService {
  static final AssetsService _instance = AssetsService._internal();
  factory AssetsService() => _instance;
  AssetsService._internal();

  final _api = ApiService();
  static const _boxName = 'assets';

  Box<Asset>? _box;

  Future<void> initialize() async {
    _box = await Hive.openBox<Asset>(_boxName);
  }

  // Get all assets from API
  Future<List<Asset>> fetchAssets() async {
    final response = await _api.get('/assets');
    final List<dynamic> data = response.data;
    final assets = data.map((json) => Asset.fromJson(json)).toList();

    // Cache locally
    await _cacheAssets(assets);

    return assets;
  }

  // Get single asset
  Future<Asset> fetchAsset(String id) async {
    final response = await _api.get('/assets/$id');
    return Asset.fromJson(response.data);
  }

  // Create asset
  Future<Asset> createAsset({
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
    final response = await _api.post('/assets', data: {
      'type': type.name,
      'name': name,
      if (ticker != null) 'ticker': ticker,
      if (quantity != null) 'quantity': quantity,
      if (manualValue != null) 'manualValue': manualValue,
      if (costBasis != null) 'costBasis': costBasis,
      'currency': currency,
      if (country != null) 'country': country,
      if (sector != null) 'sector': sector,
      if (riskCategory != null) 'riskCategory': riskCategory,
      if (notes != null) 'notes': notes,
    });

    final asset = Asset.fromJson(response.data);

    // Add to cache
    await _box?.put(asset.id, asset);

    return asset;
  }

  // Update asset
  Future<Asset> updateAsset(
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
    final response = await _api.patch('/assets/$id', data: {
      if (name != null) 'name': name,
      if (ticker != null) 'ticker': ticker,
      if (quantity != null) 'quantity': quantity,
      if (manualValue != null) 'manualValue': manualValue,
      if (costBasis != null) 'costBasis': costBasis,
      if (currency != null) 'currency': currency,
      if (country != null) 'country': country,
      if (sector != null) 'sector': sector,
      if (riskCategory != null) 'riskCategory': riskCategory,
      if (notes != null) 'notes': notes,
    });

    final asset = Asset.fromJson(response.data);

    // Update cache
    await _box?.put(asset.id, asset);

    return asset;
  }

  // Delete asset
  Future<void> deleteAsset(String id) async {
    await _api.delete('/assets/$id');

    // Remove from cache
    await _box?.delete(id);
  }

  // Get cached assets
  List<Asset> getCachedAssets() {
    return _box?.values.toList() ?? [];
  }

  // Cache assets
  Future<void> _cacheAssets(List<Asset> assets) async {
    await _box?.clear();
    for (final asset in assets) {
      await _box?.put(asset.id, asset);
    }
  }
}
