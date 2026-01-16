import 'package:hive/hive.dart';

import '../models/price.dart';
import 'api_service.dart';

class PricesService {
  static final PricesService _instance = PricesService._internal();
  factory PricesService() => _instance;
  PricesService._internal();

  final _api = ApiService();
  static const _boxName = 'prices';

  Box<Price>? _box;

  Future<void> initialize() async {
    _box = await Hive.openBox<Price>(_boxName);
  }

  // Fetch price for a ticker
  Future<Price> fetchPrice(String ticker) async {
    final response = await _api.get('/prices/$ticker');
    final price = Price.fromJson(response.data);

    // Cache locally
    await _cachePrice(price);

    return price;
  }

  // Search tickers
  Future<List<TickerSearchResult>> searchTickers(String query) async {
    if (query.isEmpty) return [];

    final response = await _api.get('/search/ticker', queryParameters: {
      'q': query,
    });

    final List<dynamic> data = response.data;
    return data.map((json) => TickerSearchResult.fromJson(json)).toList();
  }

  // Get cached price
  Price? getCachedPrice(String ticker) {
    return _box?.get(ticker);
  }

  // Cache price
  Future<void> _cachePrice(Price price) async {
    await _box?.put(price.ticker, price);
  }
}
