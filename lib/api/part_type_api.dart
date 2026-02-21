import 'package:inventory_management/api/api_client.dart';
import 'package:inventory_management/dto/bulk_request_result.dart';
import 'package:inventory_management/api/endpoints.dart';
import 'package:inventory_management/models/part_type.dart';

class PartTypeApi {

  Future<List<PartType>> fetchPartTypes() async {
    final data = await ApiClient.get(Endpoints.partTypes);
    return (data as List).map((json) => PartType.fromJson(json)).toList();
  }

  Future<void> createPartType(PartType type) async {
    await ApiClient.post(Endpoints.partTypes, type.toJson());
  }

  Future<List<PartType>> createPartTypes(List<PartType> types) async {
    final registeredData = await ApiClient.post('${Endpoints.partTypes}/bulk', types.map((type) => type.toJson()).toList());
    return (registeredData as List).map((json) => PartType.fromJson(json)).toList();
  }

  Future<BulkRequestResult> deletePartTypes(List<int> typeIds) async {
    final responseBody = await ApiClient.delete('${Endpoints.partTypes}/bulk', typeIds);
    return BulkRequestResult(successCount: responseBody["successCount"], failedCount: responseBody["failedCount"]);
  }
}