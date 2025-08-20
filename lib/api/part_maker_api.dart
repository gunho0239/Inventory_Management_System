import 'package:inventory_management/api/api_client.dart';
import 'package:inventory_management/api/api_response_entity.dart';
import 'package:inventory_management/api/endpoints.dart';
import 'package:inventory_management/models/part_maker.dart';

class PartMakerApi {

  Future<List<PartMaker>> fetchPartMakers() async {
    final data = await ApiClient.get(Endpoints.partMakers);
    return (data as List).map((json) => PartMaker.fromJson(json)).toList();
  }

  Future<void> createPartMaker(PartMaker maker) async {
    await ApiClient.post(Endpoints.partMakers, maker.toJson());
  }

  Future<List<PartMaker>> createPartMakers(List<PartMaker> makers) async {
    final registeredData = await ApiClient.post('${Endpoints.partMakers}/bulk', makers.map((maker) => maker.toJson()).toList());
    return (registeredData as List).map((json) => PartMaker.fromJson(json)).toList();
  }

  Future<BulkRequestResult> deletePartMakers(List<int> makerIds) async {
    final responseBody = await ApiClient.delete('${Endpoints.partMakers}/bulk', makerIds);
    return BulkRequestResult(successCount: responseBody["successCount"], failedCount: responseBody["failedCount"]);
  }
}