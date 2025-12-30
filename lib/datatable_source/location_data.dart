import 'package:flutter/material.dart';
import 'package:inventory_management/models/location.dart';


class LocationDataSource extends DataTableSource {
  List<Location> locations;
  final Set<Location> selectedLocations;
  final void Function(Location, bool) onSelectChanged;

  LocationDataSource({
    required this.locations,
    required this.selectedLocations,
    required this.onSelectChanged,
  });

  void updateData(List<Location> newLocations) {
    locations = newLocations;
    notifyListeners();
  }

  void updateSelected() {
    notifyListeners();
  }

  @override
  DataRow getRow(int index) {
    final location = locations[index];
    return DataRow.byIndex(
      index: index,
      selected: selectedLocations.contains(location),
      onSelectChanged: (selected) => onSelectChanged(location, selected ?? false),
      cells: [
        DataCell(Text(location.section.section ?? '')),
        DataCell(Text(location.number.toString())),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => locations.length;

  @override
  int get selectedRowCount => selectedLocations.length;
}
