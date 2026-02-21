import 'package:inventory_management/dto/bulk_request_result.dart';
import 'package:inventory_management/api/location_api.dart';
import 'package:inventory_management/models/location.dart';

class LocationRepository {
  final _api = LocationApi();

  Future<List<Location>> getAllLocations() => _api.fetchLocations();
  Future<List<Location>> getLocationsBySection(int sectionId) => _api.fetchLocationsBySection(sectionId);
  Future<List<Location>> getLocationsByFilter(int? sectionId, int? number) => _api.fetchLocationsByFilter(sectionId, number);
  Future<Location> addLocation(Location location) => _api.createLocation(location);
  Future<List<Location>> addLocations(List<Location> locations) => _api.createLocations(locations);
  Future<void> removeLocation(int locationId) => _api.deleteLocation(locationId);
  Future<BulkRequestResult> removeLocations(List<int> locationIds) => _api.deleteLocations(locationIds);
}