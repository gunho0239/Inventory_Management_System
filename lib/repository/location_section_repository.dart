import 'package:inventory_management/api/api_response_entity.dart';
import 'package:inventory_management/api/location_section_api.dart';
import 'package:inventory_management/models/location_section.dart';

class LocationSectionRepository {
  final _api = LocationSectionApi();

  Future<List<LocationSection>> getAllLocationSections() => _api.fetchLocationSections();
  Future<void> addLocationSection(LocationSection section) => _api.createLocationSection(section);
  Future<List<LocationSection>> addLocationSections(List<LocationSection> sections) => _api.createLocationSections(sections);
  Future<BulkRequestResult> removeLocationSections(List<int> sectionIds) => _api.deleteLocationSections(sectionIds);
}