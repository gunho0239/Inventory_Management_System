import 'package:flutter/material.dart';
import 'package:inventory_management/models/location.dart';
import 'package:inventory_management/models/stock.dart';


class StockDataSource extends DataTableSource {
  List<Stock> stocks;
  final List<Stock> selectedStocks;
  final void Function(Stock, bool) onSelectChanged;
  final Future<int?> Function()? onQuantityTapped;
  final Future<Location?> Function()? onLocationTapped;

  StockDataSource({
    required this.stocks,
    required this.selectedStocks,
    required this.onSelectChanged,
    this.onQuantityTapped,
    this.onLocationTapped,
  });

  void updateData(List<Stock> newStocks) {
    stocks = newStocks;
    notifyListeners();
  }

  void updateSelected() {
    notifyListeners();
  }

  Future<void> _changeQuantity(int index) async {
    int? quantity = await onQuantityTapped!();

    if (quantity != null) {
      stocks[index] = stocks[index].copyWith(quantity: quantity);
      notifyListeners();
    }
  }

  Future<void> _changeLocation(int index) async {
    Location? location = await onLocationTapped!();

    if (location != null) {
      stocks[index] = stocks[index].copyWith(location: location);
      notifyListeners();
    }
  }

  @override
  DataRow getRow(int index) {
    final stock = stocks[index];
    return DataRow.byIndex(
      index: index,
      selected: selectedStocks.contains(stock),
      onSelectChanged: (selected) {
        onSelectChanged(stock, selected ?? false);
        notifyListeners();
      },
      cells: [
        DataCell(Text(stock.part?.type.type! ?? "")),
        DataCell(Text(stock.part?.specification ?? ""), ),
        DataCell(Text(stock.part?.maker.maker! ?? ""),),
        DataCell(Align(
          alignment: Alignment.centerRight,
          child: Text("${stock.quantity?.toString() ?? ""} / ${stock.part?.unit.unit ?? ""}")),
          showEditIcon: (onQuantityTapped != null),
          onTap: (onQuantityTapped != null) ? () async {
            await _changeQuantity(index);
          } : null,
        ),
        DataCell(Text("${stock.location?.section.section! ?? ""}-${stock.location?.number.toString() ?? ""}"),
          showEditIcon: (onLocationTapped != null),
          onTap: (onLocationTapped != null) ? () async {
            await _changeLocation(index);
          } : null,
        ),
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
