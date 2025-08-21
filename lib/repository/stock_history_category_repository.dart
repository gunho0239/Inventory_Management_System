import 'package:inventory_management/api/stock_history_category_api.dart';
import 'package:inventory_management/models/stock_history_category.dart';

class StockHistoryCategoryRepository {
  final _api = StockHistoryCategoryApi();

  Future<List<StockHistoryCategory>> getAllStockHistoryCategories() => _api.fetchStockHistoryCategories();
  
}