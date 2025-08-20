import 'package:inventory_management/api/api_client.dart';
import 'package:inventory_management/api/api_response_entity.dart';
import 'package:inventory_management/api/endpoints.dart';
import 'package:inventory_management/models/part_unit.dart';

class PartUnitApi {

  Future<List<PartUnit>> fetchPartUnits() async {
    final data = await ApiClient.get(Endpoints.partUnits);
    return (data as List).map((json) => PartUnit.fromJson(json)).toList();
  }

  Future<void> createPartUnit(PartUnit unit) async {
    await ApiClient.post(Endpoints.partUnits, unit.toJson());
  }

  Future<List<PartUnit>> createPartUnits(List<PartUnit> units) async {
    final registeredData = await ApiClient.post('${Endpoints.partUnits}/bulk', units.map((unit) => unit.toJson()).toList());
    return (registeredData as List).map((json) => PartUnit.fromJson(json)).toList();
  }

  Future<BulkRequestResult> deletePartUnits(List<int> unitIds) async {
    final responseBody = await ApiClient.delete('${Endpoints.partUnits}/bulk', unitIds);
    return BulkRequestResult(successCount: responseBody["successCount"], failedCount: responseBody["failedCount"]);
  }
}