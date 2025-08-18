import 'package:inventory_management/api/api_client.dart';
import 'package:inventory_management/api/endpoints.dart';
import 'package:inventory_management/models/part.dart';

class PartApi {

  Future<List<Part>> fetchParts() async {
    final data = await ApiClient.get(Endpoints.parts);
    return (data as List).map((json) => Part.fromJson(json)).toList();
  }

  Future<List<Part>> fetchPartsByType(int typeId) async {
    final data = await ApiClient.get('${Endpoints.parts}/type/$typeId');
    return (data as List).map((json) => Part.fromJson(json)).toList();
  }

  Future<List<Part>> fetchPartsByMaker(int makerId) async {
    final data = await ApiClient.get('${Endpoints.parts}/maker/$makerId');
    return (data as List).map((json) => Part.fromJson(json)).toList();
  }

  Future<List<Part>> fetchPartsByFilter(int? typeId, int? makerId, String? spec) async {
    final queryParameters = {
      'typeId': typeId?.toString(),
      'makerId': makerId?.toString(),
      'specification': spec
    }..removeWhere((key, value) => value == null);

    final data = await ApiClient.get('${Endpoints.parts}/search?${Uri(queryParameters: queryParameters).query}');
    return (data as List).map((json) => Part.fromJson(json)).toList();
  }

  // Future<List<Part>> fetchPartsBySpecification(String spec) async {
  //   final data = await ApiClient.get('${Endpoints.parts}/search?specification=$spec');
  //   return (data as List).map((json) => Part.fromJson(json)).toList();
  // }

  // Future<List<Part>> fetchPartsByTypeAndMaker(int typeId, int makerId) async {
  //   final data = await ApiClient.get('${Endpoints.parts}/search/combined?typeId=$typeId&makerId=$makerId');
  //   return (data as List).map((json) => Part.fromJson(json)).toList();
  // }

  // Future<List<Part>> fetchPartsByTypeAndSpecification(int typeId, String spec) async {
  //   final data = await ApiClient.get('${Endpoints.parts}/search/combined?typeId=$typeId&specification=$spec');
  //   return (data as List).map((json) => Part.fromJson(json)).toList();
  // }

  // Future<List<Part>> fetchPartsByMakerAndSpecification(int makerId, String spec) async {
  //   final data = await ApiClient.get('${Endpoints.parts}/search/combined?makerId=$makerId&specification=$spec');
  //   return (data as List).map((json) => Part.fromJson(json)).toList();
  // }

  // Future<List<Part>> fetchPartsByTypeAndMakerAndSpecification(int typeId, int makerId, String spec) async {
  //   final data = await ApiClient.get('${Endpoints.parts}/search/combined?typeId=$typeId&makerId=$makerId&specification=$spec');
  //   return (data as List).map((json) => Part.fromJson(json)).toList();
  // }

  Future<Part> createPart(Part part) async {
    final registeredData = await ApiClient.post('${Endpoints.parts}/single', part.toJson());
    return Part.fromJson(registeredData);
  }

  Future<List<Part>> createParts(List<Part> parts) async {
    final registeredData = await ApiClient.post('${Endpoints.parts}/bulk', parts.map((loc) => loc.toJson()).toList());
    return (registeredData as List).map((json) => Part.fromJson(json)).toList();
  }

  Future<void> deletePart(int partId) async {
    await ApiClient.delete('${Endpoints.parts}/$partId', null);
  }

  Future<DeleteResult> deleteParts(List<int> partIds) async {
    return await ApiClient.delete('${Endpoints.parts}/bulk', partIds);
  }

}
