import 'package:flutter/material.dart';
import 'package:inventory_management/models/stock_history.dart';


class StockHistoryDataSource extends DataTableSource {
  final List<StockHistory> stockHistories;
  final Set<StockHistory> selectedStockHistories;
  final void Function(StockHistory, bool) onSelectChanged;

  StockHistoryDataSource({
    required this.stockHistories,
    required this.selectedStockHistories,
    required this.onSelectChanged,
  });

  @override
  DataRow getRow(int index) {
    final stockHistory = stockHistories[index];
    return DataRow.byIndex(
      index: index,
      selected: selectedStockHistories.contains(stockHistory),
      onSelectChanged: (selected) => onSelectChanged(stockHistory, selected ?? false),
      cells: [
        DataCell(Text(stockHistory.date.toString())),
        DataCell(Text(stockHistory.category.category)),
        DataCell(Text(stockHistory.note)),
        DataCell(Text(stockHistory.type)),
        DataCell(Text(stockHistory.specification)),
        DataCell(Text(stockHistory.maker)),
        DataCell(Text(stockHistory.unit)),
        DataCell(Text('${stockHistory.beforeQuantity} (${stockHistory.afterQuantity - stockHistory.beforeQuantity}) ${stockHistory.afterQuantity}')),
        DataCell(Text('${stockHistory.beforeLocation} -> ${stockHistory.afterLocation}')),
        DataCell(Text(stockHistory.person)),
      ],
    );
  }

  // DataCell _buildDateCell(DateTime date) {
  //   final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(date);
  //   return DataCell(Text(formattedDate));
  // }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => stockHistories.length;

  @override
  int get selectedRowCount => selectedStockHistories.length;
}
