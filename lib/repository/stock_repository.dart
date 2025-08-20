import 'package:inventory_management/api/api_response_entity.dart';
import 'package:inventory_management/api/stock_api.dart';
import 'package:inventory_management/models/stock.dart';

class StockRepository {
  final _api = StockApi();

  Future<List<Stock>> getAllStocks() => _api.fetchStocks();
  Future<List<Stock>> getStocksByType(int typeId) => _api.fetchStocksByType(typeId);
  Future<List<Stock>> getStocksByMaker(int makerId) => _api.fetchStocksByMaker(makerId);
  Future<List<Stock>> getStocksBySection(int sectionId) => _api.fetchStocksBySection(sectionId);
  Future<List<Stock>> getStocksByFilter(int? typeId, int? makerId, String? spec, int? sectionId, String? number) => _api.fetchStocksByFilter(typeId, makerId, spec, sectionId, number);
  Future<Stock> addStock(Stock stock) => _api.createStock(stock);
  Future<List<Stock>> addStocks(List<Stock> stocks) => _api.createStocks(stocks);
  Future<SingleRequestResult> removeStock(Stock stock) => _api.deleteStock(stock);
  Future<SingleRequestResult> updateStockQuantity(Stock stock) => _api.updateStockQuantity(stock);
  Future<SingleRequestResult> updateStockLocation(Stock stock) => _api.updateStockLocation(stock);
}