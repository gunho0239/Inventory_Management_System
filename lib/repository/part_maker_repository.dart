import 'package:inventory_management/api/api_response_entity.dart';
import 'package:inventory_management/api/part_maker_api.dart';
import 'package:inventory_management/models/part_maker.dart';

class PartMakerRepository {
  final _api = PartMakerApi();

  Future<List<PartMaker>> getAllPartMakers() => _api.fetchPartMakers();
  Future<void> addPartMaker(PartMaker maker) => _api.createPartMaker(maker);
  Future<List<PartMaker>> addPartMakers(List<PartMaker> makers) => _api.createPartMakers(makers);
  Future<BulkRequestResult> removePartMakers(List<int> makerIds) => _api.deletePartMakers(makerIds);
}