import 'package:flutter/material.dart';
import 'package:inventory_management/models/part_unit.dart';

class PartUnitDataSource extends DataTableSource {
  List<PartUnit> units;
  final Set<PartUnit> selectedUnits;
  final void Function(PartUnit, bool) onSelectChanged;

  PartUnitDataSource({
    required this.units,
    required this.selectedUnits,
    required this.onSelectChanged,
  });

  @override
  DataRow getRow(int index) {
    final unit = units[index];
    return DataRow.byIndex(
      index: index,
      selected: selectedUnits.contains(unit),
      onSelectChanged: (selected) => onSelectChanged(unit, selected ?? false),
      cells: [
        DataCell(Text(unit.unit ?? '')),
      ],
    );
  }

  void updateData(List<PartUnit> newUnits) {
    units = newUnits; // 내부 데이터 리스트 갱신 (final 키워드가 없어야 함)
    notifyListeners(); // DataTable 갱신 트리거
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => units.length;

  @override
  int get selectedRowCount => selectedUnits.length;
}
