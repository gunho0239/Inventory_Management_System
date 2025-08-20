import 'package:inventory_management/api/api_client.dart';
import 'package:inventory_management/api/api_response_entity.dart';
import 'package:inventory_management/api/endpoints.dart';
import 'package:inventory_management/models/person.dart';

class PersonApi {

  Future<List<Person>> fetchPersons() async {
    final data = await ApiClient.get(Endpoints.persons);
    return (data as List).map((json) => Person.fromJson(json)).toList();
  }

  Future<void> createPerson(Person person) async {
    await ApiClient.post(Endpoints.persons, person.toJson());
  }

  Future<List<Person>> createPersons(List<Person> persons) async {
    final registeredData = await ApiClient.post('${Endpoints.persons}/bulk', persons.map((person) => person.toJson()).toList());
    return (registeredData as List).map((json) => Person.fromJson(json)).toList();
  }

  Future<BulkRequestResult> deletePersons(List<int> personIds) async {
    dynamic responseBody = await ApiClient.delete('${Endpoints.persons}/bulk', personIds);
    return BulkRequestResult(successCount: responseBody["successCount"], failedCount: responseBody["failedCount"]);
  }
}