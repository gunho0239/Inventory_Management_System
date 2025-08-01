import 'package:flutter/material.dart';
import 'package:inventory_management/models/location_section.dart';

class LocationSectionDataSource extends DataTableSource {
  final List<LocationSection> sections;
  final Set<LocationSection> selectedSections;
  final void Function(LocationSection, bool) onSelectChanged;

  LocationSectionDataSource({
    required this.sections,
    required this.selectedSections,
    required this.onSelectChanged,
  });

  @override
  DataRow getRow(int index) {
    final section = sections[index];
    return DataRow.byIndex(
      index: index,
      selected: selectedSections.contains(section),
      onSelectChanged: (selected) => onSelectChanged(section, selected ?? false),
      cells: [
        DataCell(Text(section.section ?? '')),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => sections.length;

  @override
  int get selectedRowCount => selectedSections.length;
}
