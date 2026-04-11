import 'package:flutter/material.dart';
import 'package:inventory_management/models/part.dart';

class PartDataSource extends DataTableSource {
  // final을 제거하여 내부에서 리스트를 교체할 수 있도록 변경합니다.
  List<Part> parts;
  Set<Part> selectedParts;
  final void Function(Part, bool) onSelectChanged;

  PartDataSource({
    required this.parts,
    required this.selectedParts,
    required this.onSelectChanged,
  });

  // 1. [추가] 새로운 데이터 리스트를 받아 테이블을 갱신하는 메서드
  void updateData(List<Part> newParts) {
    parts = newParts;
    // 선택 상태 초기화가 필요하다면 여기서 selectedParts.clear()를 호출할 수 있습니다.
    notifyListeners(); // DataTable에 데이터가 변경되었음을 알리고 화면을 다시 그리게 함
  }

  // 2. [추가] 선택된 항목만 변경되었을 때 (예: 삭제 후) 갱신하는 메서드
  void updateSelected() {
    notifyListeners();
  }

  @override
  DataRow getRow(int index) {
    // 안전 장치: 인덱스 초과 에러 방지
    if (index >= parts.length) return const DataRow(cells: []);

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