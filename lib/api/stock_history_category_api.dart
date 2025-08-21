import 'package:inventory_management/api/api_client.dart';
import 'package:inventory_management/api/endpoints.dart';
import 'package:inventory_management/models/stock_history_category.dart';

class StockHistoryCategoryApi {

  Future<List<StockHistoryCategory>> fetchStockHistoryCategories() async {
    final data = await ApiClient.get(Endpoints.stockHistoryCategories);
    return (data as List).map((json) => StockHistoryCategory.fromJson(json)).toList();
  }
}