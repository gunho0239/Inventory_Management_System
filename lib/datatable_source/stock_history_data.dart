import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/models/stock_history.dart';


class StockHistoryDataSource extends DataTableSource {
  final List<StockHistory> stockHistories;
  final void Function(StockHistory, bool) onSelectChanged;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  StockHistoryDataSource({
    required this.stockHistories,
    required this.onSelectChanged,
  });

  @override
  DataRow getRow(int index) {
    final stockHistory = stockHistories[index];

    final String createdDate = stockHistory.date != null ? _dateFormat.format(stockHistory.date!) : '-';
    final String memo = stockHistory.memo != "" ? stockHistory.memo.length > 15 ? '${stockHistory.memo.substring(0, 15)}...' : stockHistory.memo : '-';

    return DataRow.byIndex(
      index: index,
      onSelectChanged: (selected) => onSelectChanged(stockHistory, selected ?? false),
      cells: [
        DataCell(Text(createdDate)),
        DataCell(Text(stockHistory.category.category)),
        DataCell(Text(memo)),
        DataCell(Text(stockHistory.type)),
        DataCell(Text(stockHistory.specification)),
        DataCell(Text(stockHistory.maker)),
        DataCell(Text(stockHistory.unit)),
        DataCell(Text(stockHistory.formattedQuantity)),
        DataCell(Text(stockHistory.formattedLocation)),
        DataCell(Text(stockHistory.person)),
      ],
    );
  }


  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => stockHistories.length;

  @override
  int get selectedRowCount => 0;
}
