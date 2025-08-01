import 'package:inventory_management/api/api_client.dart';
import 'package:inventory_management/api/part_type_api.dart';
import 'package:inventory_management/models/part_type.dart';

class PartTypeRepository {
  final _api = PartTypeApi();

  Future<List<PartType>> getAllPartTypes() => _api.fetchPartTypes();
  Future<void> addPartType(PartType type) => _api.createPartType(type);
  Future<List<PartType>> addPartTypes(List<PartType> types) => _api.createPartTypes(types);
  Future<DeleteResult> removePartTypes(List<int> typeIds) => _api.deletePartTypes(typeIds);
}