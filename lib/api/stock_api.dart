import 'package:inventory_management/api/api_client.dart';

import 'package:inventory_management/api/endpoints.dart';
import 'package:inventory_management/dto/bulk_request_result_with_ids.dart';
import 'package:inventory_management/dto/single_request_result.dart';
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

  Future<Stock> createStock(Stock stock) async {
    final registeredData = await ApiClient.post('${Endpoints.stocks}/single', stock.toJson());
    return Stock.fromJson(registeredData);
  }

  Future<List<Stock>> createStocks(List<Stock> stocks) async {
    final registeredData = await ApiClient.post('${Endpoints.stocks}/bulk', stocks.map((stock) => stock.toJson()).toList());
    return (registeredData as List).map((json) => Stock.fromJson(json)).toList();
  }

  Future<SingleRequestResult> deleteStock(Stock stock) async {
    dynamic responseBody = await ApiClient.delete('${Endpoints.stocks}/single', stock.toJson());
    return SingleRequestResult(success: responseBody["success"], errorMessage: responseBody["message"]);
  }

  Future<BulkRequestResultWithIds> deleteStocks(List<Stock> stocks) async {
    dynamic responseBody = await ApiClient.delete('${Endpoints.stocks}/bulk', stocks.map((stock) => stock.toJson()).toList());
    return BulkRequestResultWithIds(successIds: List<int>.from(responseBody["successIds"]), failedIds: List<int>.from(responseBody["failedIds"]));
  }

  Future<SingleRequestResult> updateStock(Stock stock) async {
    dynamic responseBody = await ApiClient.put('${Endpoints.stocks}/single', stock.toJson());
    return SingleRequestResult(success: responseBody["success"], errorMessage: responseBody["message"]);
  }

  Future<BulkRequestResultWithIds> updateStocks(List<Stock> stocks) async {
    dynamic responseBody = await ApiClient.put('${Endpoints.stocks}/bulk', stocks.map((stock) => stock.toJson()).toList());
    return BulkRequestResultWithIds(successIds: List<int>.from(responseBody["successIds"]), failedIds: List<int>.from(responseBody["failedIds"]));
  }

  // Future<SingleRequestResult> updateStockQuantity(Stock stock) async {
  //   dynamic responseBody = await ApiClient.put('${Endpoints.stocks}/quantity', stock.toJson());
  //   return SingleRequestResult(success: responseBody["success"], errorMessage: responseBody["message"]);
  // }

  Future<SingleRequestResult> updateStockLocation(Stock stock) async {
    dynamic responseBody = await ApiClient.put('${Endpoints.stocks}/location', stock.toJson());
    return SingleRequestResult(success: responseBody["success"], errorMessage: responseBody["message"]);
  }

  Future<BulkRequestResultWithIds> updateStockLocations(List<Stock> stocks) async {
    dynamic responseBody = await ApiClient.put('${Endpoints.stocks}/locations', stocks.map((stock) => stock.toJson()).toList());
    return BulkRequestResultWithIds(successIds: List<int>.from(responseBody["successIds"]), failedIds: List<int>.from(responseBody["failedIds"]));
  }
}
