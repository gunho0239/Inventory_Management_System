import 'package:flutter/material.dart';
import 'package:inventory_management/models/location_section.dart';

class LocationSectionDataSource extends DataTableSource {
  List<LocationSection> sections;
  Set<LocationSection> selectedSections;
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

  void updateData(List<LocationSection> newSections) {
    sections = newSections; // 내부 데이터 리스트 교체 (final 키워드 제거 필요)
    notifyListeners(); // 화면 갱신 트리거
  }

  void updateSelected() {
    notifyListeners();
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => sections.length;

  @override
  int get selectedRowCount => selectedSections.length;
}
