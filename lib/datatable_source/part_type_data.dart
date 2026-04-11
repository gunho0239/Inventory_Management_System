import 'package:flutter/material.dart';
import 'package:inventory_management/models/part_type.dart';

class PartTypeDataSource extends DataTableSource {
  List<PartType> types;
  final Set<PartType> selectedTypes;
  final void Function(PartType, bool) onSelectChanged;

  PartTypeDataSource({
    required this.types,
    required this.selectedTypes,
    required this.onSelectChanged,
  });

  @override
  DataRow getRow(int index) {
    final type = types[index];
    return DataRow.byIndex(
      index: index,
      selected: selectedTypes.contains(type),
      onSelectChanged: (selected) => onSelectChanged(type, selected ?? false),
      cells: [
        DataCell(Text(type.type ?? '')),
      ],
    );
  }

  void updateData(List<PartType> newTypes) {
    types = newTypes;
    notifyListeners(); 
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => types.length;

  @override
  int get selectedRowCount => selectedTypes.length;
}
