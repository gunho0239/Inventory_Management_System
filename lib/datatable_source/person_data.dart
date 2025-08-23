import 'package:flutter/material.dart';
import 'package:inventory_management/models/person.dart';

class PersonDataSource extends DataTableSource {
  final List<Person> persons;
  final Set<Person> selectedPersons;
  final void Function(Person, bool) onSelectChanged;

  PersonDataSource({
    required this.persons,
    required this.selectedPersons,
    required this.onSelectChanged,
  });

  @override
  DataRow getRow(int index) {
    final person = persons[index];
    return DataRow.byIndex(
      index: index,
      selected: selectedPersons.contains(person),
      onSelectChanged: (selected) => onSelectChanged(person, selected ?? false),
      cells: [
        DataCell(Text(person.name ?? '')),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => persons.length;

  @override
  int get selectedRowCount => selectedPersons.length;
}
