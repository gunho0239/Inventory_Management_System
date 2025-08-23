import 'package:inventory_management/api/stock_history_api.dart';
import 'package:inventory_management/models/stock_history.dart';

class StockHistoryRepository {
  final _api = StockHistoryApi();

  Future<List<StockHistory>> getAllHistories() => _api.fetchHistories();
  Future<List<StockHistory>> getHistoriesByCategory(int categoryId) => _api.fetchHistoriesByCategory(categoryId);
  Future<List<StockHistory>> getHistoriesByFilter(DateTime? startDate, DateTime? endDate, int? categoryId, String? type, String? spec, String? maker, String? memo) 
                      => _api.fetchHistoriesByFilter(startDate, endDate, categoryId, type, spec, maker, memo);
  Future<StockHistory> addHistory(StockHistory stockHistory) => _api.createHistory(stockHistory);
  Future<List<StockHistory>> addHistories(List<StockHistory> stockHistories) => _api.createHistories(stockHistories);
}