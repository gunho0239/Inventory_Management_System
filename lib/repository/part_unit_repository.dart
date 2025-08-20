import 'package:inventory_management/api/api_response_entity.dart';
import 'package:inventory_management/api/part_unit_api.dart';
import 'package:inventory_management/models/part_unit.dart';

class PartUnitRepository {
  final _api = PartUnitApi();

  Future<List<PartUnit>> getAllPartUnits() => _api.fetchPartUnits();
  Future<void> addPartUnit(PartUnit unit) => _api.createPartUnit(unit);
  Future<List<PartUnit>> addPartUnits(List<PartUnit> units) => _api.createPartUnits(units);
  Future<BulkRequestResult> removePartUnits(List<int> unitIds) => _api.deletePartUnits(unitIds);
}