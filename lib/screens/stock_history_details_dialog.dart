import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/constants/columns.dart';
import 'package:inventory_management/models/stock_history.dart';
import 'package:inventory_management/widgets/icons.dart';

class HistoryDetailsDialog extends StatelessWidget {
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  
  final StockHistory selectedHistory;

  final List<DataColumn> _detailsColumns = [
      DataColumn(label: Text(date)),
      DataColumn(label: Text(systemUser)),
  ];
  late final List<DataRow> _detailsRow;

  final List<DataColumn> _stockColumns = [
    DataColumn(label: Text(type)),
    DataColumn(label: Text(specification)),
    DataColumn(label: Text(maker)),
    DataColumn(label: Text(unit)),
    DataColumn(label: Text(quantity)),
    DataColumn(label: Text(location)),
  ];
  late final List<DataRow> _stockRow;

  HistoryDetailsDialog({super.key, required this.selectedHistory}) {
    _detailsRow = [
      DataRow(cells: [
          DataCell(Text(_dateFormat.format(selectedHistory.date!))),
          DataCell(Text(selectedHistory.person)),
        ])
    ];

    _stockRow = [
      DataRow(cells: [
          DataCell(Text(selectedHistory.type)),
          DataCell(Text(selectedHistory.specification)),
          DataCell(Text(selectedHistory.maker)),
          DataCell(Text(selectedHistory.unit)),
          DataCell(Text(selectedHistory.formattedQuantity)),
          DataCell(Text(selectedHistory.formattedLocation)),
        ])
    ];
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        spacing: 5,
        children: [
          Icon(MenuIcons.history, size: 30),
          Text(selectedHistory.category.category, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 30,
          children: [
            DataTable(
              columns: _detailsColumns,
              rows: _detailsRow,
            ),
            DataTable(
              columns: _stockColumns,
              rows: _stockRow,
            ),
            SizedBox(
              width: 600,
              child: TextField(
                controller: TextEditingController(text: selectedHistory.memo),
                readOnly: true,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: '메모',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('닫기'),
        ),
      ],
    );
  }
}