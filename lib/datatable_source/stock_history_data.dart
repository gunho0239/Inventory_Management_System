import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/models/stock_history.dart';


class StockHistoryDataSource extends DataTableSource {
  final List<StockHistory> stockHistories;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  StockHistoryDataSource({
    required this.stockHistories,
  });

  @override
  DataRow getRow(int index) {
    final stockHistory = stockHistories[index];

    final String createdDate = stockHistory.date != null ? _dateFormat.format(stockHistory.date!) : '-';
    final String memo = stockHistory.memo != "" ? stockHistory.memo.length > 15 ? '${stockHistory.memo.substring(0, 15)}...' : stockHistory.memo : '-';
    late final String quantity;
    late final String location;

    if (stockHistory.category.isRelease) {
      quantity = '${stockHistory.beforeQuantity - stockHistory.afterQuantity}';
      location = stockHistory.beforeLocation;
    }
    else if (stockHistory.category.isQuantityChange) {
      quantity = '${stockHistory.beforeQuantity} -> ${stockHistory.afterQuantity}';
      location = stockHistory.beforeLocation;
    }
    else if (stockHistory.category.isLocationChange) {
      quantity = stockHistory.beforeQuantity.toString();
      location = '${stockHistory.beforeLocation} -> ${stockHistory.afterLocation}';
    }
    else { // stockHistory.category.isRegister
      quantity = stockHistory.afterQuantity.toString();
      location = stockHistory.afterLocation;
    }

    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text(createdDate)),
        DataCell(Text(stockHistory.category.category)),
        DataCell(Text(memo)),
        DataCell(Text(stockHistory.type)),
        DataCell(Text(stockHistory.specification)),
        DataCell(Text(stockHistory.maker)),
        DataCell(Text(stockHistory.unit)),
        DataCell(Text(quantity)),
        DataCell(Text(location)),
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
