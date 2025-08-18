import 'package:inventory_management/api/api_client.dart';
import 'package:inventory_management/api/endpoints.dart';
import 'package:inventory_management/models/stock.dart';

class StockApi {

  Future<List<Stock>> fetchStocks() async {
    final data = await ApiClient.get(Endpoints.stocks);
    return (data as List).map((json) => Stock.fromJson(json)).toList();
  }

  Future<List<Stock>> fetchStocksByType(int typeId) async {
    final data = await ApiClient.get('${Endpoints.stocks}/type/$typeId');
    return (data as List).map((json) => Stock.fromJson(json)).toList();
  }

  Future<List<Stock>> fetchStocksByMaker(int makerId) async {
    final data = await ApiClient.get('${Endpoints.stocks}/maker/$makerId');
    return (data as List).map((json) => Stock.fromJson(json)).toList();
  }

  Future<List<Stock>> fetchStocksBySection(int sectionId) async {
    final data = await ApiClient.get('${Endpoints.stocks}/section/$sectionId');
    return (data as List).map((json) => Stock.fromJson(json)).toList();
  }

  Future<List<Stock>> fetchStocksByFilter(int? typeId, int? makerId, String? spec, int? sectionId, String? number) async {
    final queryParameters = {
      'typeId': typeId?.toString(),
      'makerId': makerId?.toString(),
      'specification': spec,
      'sectionId': sectionId?.toString(),
      'number': number
    }..removeWhere((key, value) => value == null);

    final data = await ApiClient.get('${Endpoints.stocks}/search?${Uri(queryParameters: queryParameters).query}');
    return (data as List).map((json) => Stock.fromJson(json)).toList();
  }

  // Future<List<Stock>> fetchStocksBySpecification(String spec) async {
  //   final data = await ApiClient.get('${Endpoints.stocks}/search?specification=$spec');
  //   return (data as List).map((json) => Stock.fromJson(json)).toList();
  // }

  // Future<List<Stock>> fetchStocksByTypeAndSpecification(int typeId, String spec) async {
  //   final data = await ApiClient.get('${Endpoints.stocks}/search/combined?typeId=$typeId&specification=$spec');
  //   return (data as List).map((json) => Stock.fromJson(json)).toList();
  // }

  Future<Stock> createStock(Stock stock) async {
    final registeredData = await ApiClient.post('${Endpoints.stocks}/single', stock.toJson());
    return Stock.fromJson(registeredData);
  }

  Future<List<Stock>> createStocks(List<Stock> stocks) async {
    final registeredData = await ApiClient.post('${Endpoints.stocks}/bulk', stocks.map((stock) => stock.toJson()).toList());
    return (registeredData as List).map((json) => Stock.fromJson(json)).toList();
  }

  Future<void> deleteStock(int stockId) async {
    await ApiClient.delete('${Endpoints.stocks}/$stockId', null);
  }

  Future<DeleteResult> deleteStocks(List<int> stockIds) async {
    return await ApiClient.delete('${Endpoints.stocks}/bulk', stockIds);
  }

}
