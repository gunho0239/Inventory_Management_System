import 'package:flutter/material.dart';
import 'package:inventory_management/models/person.dart';
import 'package:inventory_management/repository/person_repository.dart';

class PersonProvider extends ChangeNotifier {
  Person? currentUser;
  List<Person> _persons = [];
  List<DropdownMenuEntry<Person>> _personsDropdown = [];

  List<Person> get persons => _persons;
  List<DropdownMenuEntry<Person>> get personsDropdown => _personsDropdown;

  Future<void> reloadPersons() async {
    _persons = await PersonRepository().getAllPersons();

    _personsDropdown = _persons.map((person) => DropdownMenuEntry<Person>(
        value: person,
        label: person.name!,
      )).toList();

    notifyListeners();
  }
}