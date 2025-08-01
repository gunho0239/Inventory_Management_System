import 'package:flutter/material.dart';
import 'package:inventory_management/models/part.dart';


class PartDataSource extends DataTableSource {
  final List<Part> parts;
  final Set<Part> selectedParts;
  final void Function(Part, bool) onSelectChanged;

  PartDataSource({
    required this.parts,
    required this.selectedParts,
    required this.onSelectChanged,
  });

  @override
  DataRow getRow(int index) {
    final part = parts[index];
    return DataRow.byIndex(
      index: index,
      selected: selectedParts.contains(part),
      onSelectChanged: (selected) => onSelectChanged(part, selected ?? false),
      cells: [
        DataCell(Text(part.type.type ?? '')),
        DataCell(Text(part.specification)),
        DataCell(Text(part.maker.maker ?? '')),
        DataCell(Text(part.unit.unit ?? '')),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => parts.length;

  @override
  int get selectedRowCount => selectedParts.length;
}
