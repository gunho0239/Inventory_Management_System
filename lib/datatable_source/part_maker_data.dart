import 'package:flutter/material.dart';
import 'package:inventory_management/models/part_maker.dart';

class PartMakerDataSource extends DataTableSource {
  List<PartMaker> makers;
  final Set<PartMaker> selectedMakers;
  final void Function(PartMaker, bool) onSelectChanged;

  PartMakerDataSource({
    required this.makers,
    required this.selectedMakers,
    required this.onSelectChanged,
  });

  @override
  DataRow getRow(int index) {
    final maker = makers[index];
    return DataRow.byIndex(
      index: index,
      selected: selectedMakers.contains(maker),
      onSelectChanged: (selected) => onSelectChanged(maker, selected ?? false),
      cells: [
        DataCell(Text(maker.maker ?? '')),
      ],
    );
  }

  void updateData(List<PartMaker> newMakers) {
    makers = newMakers; // 변수명이 makers인지 확인하세요.
    notifyListeners(); 
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => makers.length;

  @override
  int get selectedRowCount => selectedMakers.length;
}
