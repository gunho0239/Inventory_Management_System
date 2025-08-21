import 'package:inventory_management/api/api_client.dart';
import 'package:inventory_management/api/endpoints.dart';
import 'package:inventory_management/models/stock_history.dart';

class StockHistoryApi {

  Future<List<StockHistory>> fetchHistories() async {
    final data = await ApiClient.get(Endpoints.stockHistories);
    return (data as List).map((json) => StockHistory.fromJson(json)).toList();
  }

  Future<List<StockHistory>> fetchHistoriesByCategory(int categoryId) async {
    final data = await ApiClient.get('${Endpoints.stockHistories}/category/$categoryId');
    return (data as List).map((json) => StockHistory.fromJson(json)).toList();
  }

  Future<StockHistory> createHistory(StockHistory stockHistory) async {
    final registeredData = await ApiClient.post('${Endpoints.stockHistories}/single', stockHistory.toJson());
    return StockHistory.fromJson(registeredData);
  }

  Future<List<StockHistory>> createHistories(List<StockHistory> stockHistories) async {
    final registeredData = await ApiClient.post('${Endpoints.stockHistories}/bulk', stockHistories.map((history) => history.toJson()).toList());
    return (registeredData as List).map((json) => StockHistory.fromJson(json)).toList();
  }

}
