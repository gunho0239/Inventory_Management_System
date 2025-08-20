import 'package:inventory_management/api/api_response_entity.dart';
import 'package:inventory_management/api/person_api.dart';
import 'package:inventory_management/models/person.dart';

class PersonRepository {
  final _api = PersonApi();

  Future<List<Person>> getAllPersons() => _api.fetchPersons();
  Future<void> addPerson(Person person) => _api.createPerson(person);
  Future<List<Person>> addPersons(List<Person> persons) => _api.createPersons(persons);
  Future<BulkRequestResult> removePersons(List<int> personIds) => _api.deletePersons(personIds);
}