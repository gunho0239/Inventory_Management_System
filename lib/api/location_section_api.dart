import 'package:inventory_management/api/api_client.dart';
import 'package:inventory_management/api/endpoints.dart';
import 'package:inventory_management/models/location_section.dart';

class LocationSectionApi {

  Future<List<LocationSection>> fetchLocationSections() async {
    final data = await ApiClient.get(Endpoints.locationSections);
    return (data as List).map((json) => LocationSection.fromJson(json)).toList();
  }

  Future<void> createLocationSection(LocationSection section) async {
    await ApiClient.post(Endpoints.locationSections, section.toJson());
  }

  Future<List<LocationSection>> createLocationSections(List<LocationSection> sections) async {
    final registeredData = await ApiClient.post('${Endpoints.locationSections}/bulk', sections.map((sec) => sec.toJson()).toList());
    return (registeredData as List).map((json) => LocationSection.fromJson(json)).toList();
  }

  Future<DeleteResult> deleteLocationSections(List<int> sectionIds) async {
    return await ApiClient.delete('${Endpoints.locationSections}/bulk', sectionIds);
  }
}