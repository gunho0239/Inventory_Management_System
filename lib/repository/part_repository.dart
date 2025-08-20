import 'package:inventory_management/api/api_response_entity.dart';
import 'package:inventory_management/api/part_api.dart';
import 'package:inventory_management/models/part.dart';

class PartRepository {
  final _api = PartApi();

  Future<List<Part>> getAllParts() => _api.fetchParts();
  Future<List<Part>> getPartsByType(int typeId) => _api.fetchPartsByType(typeId);
  Future<List<Part>> getPartsByMaker(int makerId) => _api.fetchPartsByMaker(makerId);
  Future<List<Part>> getPartsByFilter(int? typeId, int? makerId, String? spec) => _api.fetchPartsByFilter(typeId, makerId, spec);
  Future<Part> addPart(Part part) => _api.createPart(part);
  Future<List<Part>> addParts(List<Part> parts) => _api.createParts(parts);
  Future<void> removePart(int partId) => _api.deletePart(partId);
  Future<BulkRequestResult> removeParts(List<int> partIds) => _api.deleteParts(partIds);
}