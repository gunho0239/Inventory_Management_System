import 'package:inventory_management/api/api_client.dart';
import 'package:inventory_management/api/endpoints.dart';
import 'package:inventory_management/models/location.dart';

class LocationApi {

  Future<List<Location>> fetchLocations() async {
    final data = await ApiClient.get(Endpoints.locations);
    return (data as List).map((json) => Location.fromJson(json)).toList();
  }

  Future<List<Location>> fetchLocationsBySection(int sectionId) async {
    final data = await ApiClient.get('${Endpoints.locations}/section/$sectionId');
    return (data as List).map((json) => Location.fromJson(json)).toList();
  }

  Future<Location> createLocation(Location location) async {
    final registeredData = await ApiClient.post('${Endpoints.locations}/single', location.toJson());
    return Location.fromJson(registeredData);
  }

  Future<List<Location>> createLocations(List<Location> locations) async {
    final registeredData = await ApiClient.post('${Endpoints.locations}/bulk', locations.map((loc) => loc.toJson()).toList());
    return (registeredData as List).map((json) => Location.fromJson(json)).toList();
  }

  Future<void> deleteLocation(int locationId) async {
    await ApiClient.delete('${Endpoints.locations}/$locationId', null);
  }

  Future<DeleteResult> deleteLocations(List<int> locationIds) async {
    return await ApiClient.delete('${Endpoints.locations}/bulk', locationIds);
  }

}
