import 'package:flutter/material.dart';
import 'package:inventory_management/models/stock.dart';


class StockDataSource extends DataTableSource {
  final List<Stock> stocks;
  final Set<Stock> selectedStocks;
  final void Function(Stock, bool) onSelectChanged;

  StockDataSource({
    required this.stocks,
    required this.selectedStocks,
    required this.onSelectChanged,
  });

  @override
  DataRow getRow(int index) {
    final stock = stocks[index];
    return DataRow.byIndex(
      index: index,
      selected: selectedStocks.contains(stock),
      onSelectChanged: (selected) => onSelectChanged(stock, selected ?? false),
      cells: [
        DataCell(Text(stock.part?.type.type! ?? "")),
        DataCell(Text(stock.part?.specification ?? "")),
        DataCell(Text(stock.part?.maker.maker! ?? "")),
        DataCell(Text(stock.part?.unit.unit! ?? "")),
        DataCell(Text(stock.quantity?.toString() ?? "")),
        DataCell(Text(stock.location?.section.section! ?? "")),
        DataCell(Text(stock.location?.number.toString() ?? "")),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => stocks.length;

  @override
  int get selectedRowCount => selectedStocks.length;
}
