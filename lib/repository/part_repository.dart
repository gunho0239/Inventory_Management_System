import 'package:inventory_management/api/api_client.dart';
import 'package:inventory_management/api/part_api.dart';
import 'package:inventory_management/models/part.dart';

class PartRepository {
  final _api = PartApi();

  Future<List<Part>> getAllParts() => _api.fetchParts();
  Future<List<Part>> getPartsByType(int typeId) => _api.fetchPartsByType(typeId);
  Future<List<Part>> getPartsByMaker(int makerId) => _api.fetchPartsByMaker(makerId);
  Future<List<Part>> getPartsByFilter(int? typeId, int? makerId, String? spec) => _api.fetchPartsByFilter(typeId, makerId, spec);
  // Future<List<Part>> getPartsBySpecification(String spec) => _api.fetchPartsBySpecification(spec);
  // Future<List<Part>> getPartsByTypeAndMaker(int typeId, int makerId) => _api.fetchPartsByTypeAndMaker(typeId, makerId);
  // Future<List<Part>> getPartsByTypeAndSpecification(int typeId, String spec) => _api.fetchPartsByTypeAndSpecification(typeId, spec);
  // Future<List<Part>> getPartsByMakerAndSpecification(int makerId, String spec) => _api.fetchPartsByMakerAndSpecification(makerId, spec);
  // Future<List<Part>> getPartsByTypeAndMakerAndSpecification(int typeId, int makerId, String spec) => _api.fetchPartsByTypeAndMakerAndSpecification(typeId, makerId, spec);
  Future<Part> addPart(Part part) => _api.createPart(part);
  Future<List<Part>> addParts(List<Part> parts) => _api.createParts(parts);
  Future<void> removePart(int partId) => _api.deletePart(partId);
  Future<DeleteResult> removeParts(List<int> partIds) => _api.deleteParts(partIds);
}