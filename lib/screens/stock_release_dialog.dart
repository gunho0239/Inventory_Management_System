import 'package:flutter/material.dart';
import 'package:flutter_spinbox/material.dart';
import 'package:inventory_management/api/api_response_entity.dart';
import 'package:inventory_management/constants/columns.dart';
import 'package:inventory_management/constants/menu_name.dart';
import 'package:inventory_management/models/stock.dart';
import 'package:inventory_management/providers/person_provider.dart';
import 'package:inventory_management/repository/stock_repository.dart';
import 'package:inventory_management/widgets/icons.dart';
import 'package:provider/provider.dart';

class ReleaseDialog extends StatefulWidget {
  final Stock selectedStock;

  const ReleaseDialog({super.key, required this.selectedStock});

  @override
  State<ReleaseDialog> createState() => _ReleaseDialogState();
}

class _ReleaseDialogState extends State<ReleaseDialog> {
  final TextEditingController memoFieldController = TextEditingController();
  late double releaseQuantity;
  late final String currentUserName;

  final List<DataColumn> columns = [
    DataColumn(label: Text(type)),
    DataColumn(label: Text(specification)),
    DataColumn(label: Text(maker)),
    DataColumn(label: Text(unit)),
    DataColumn(label: Text(quantity)),
    DataColumn(label: Text(location)),
    DataColumn(label: Text(number)),
  ];
  late final List<DataRow> stockRow;

  updateStock() async {
    final stockRepo = StockRepository();
    late final SingleRequestResult result;

    if (releaseQuantity == widget.selectedStock.quantity?.toDouble()) {
      result = await stockRepo.removeStock(widget.selectedStock);
    }
    else {
      final modifiedStock = Stock(
        id: widget.selectedStock.id,
        part: widget.selectedStock.part,
        location: widget.selectedStock.location,
        quantity: releaseQuantity.toInt(),
      );

      result = await stockRepo.updateStockQuantity(modifiedStock);
    }

    if (result.success) {
      
    }
  }

  @override
  void initState() {
    super.initState();

    releaseQuantity = widget.selectedStock.quantity!.toDouble();
    stockRow = [
      DataRow(cells: [
          DataCell(Text(widget.selectedStock.part?.type.type ?? "")),
          DataCell(Text(widget.selectedStock.part?.specification ?? "")),
          DataCell(Text(widget.selectedStock.part?.maker.maker ?? "")),
          DataCell(Text(widget.selectedStock.part?.unit.unit ?? "")),
          DataCell(Text(widget.selectedStock.quantity?.toString() ?? "")),
          DataCell(Text(widget.selectedStock.location?.section.section ?? "")),
          DataCell(Text(widget.selectedStock.location?.number.toString() ?? "")),
        ])
    ];

    currentUserName = Provider.of<PersonProvider>(context, listen: false).currentUser!.name!;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        spacing: 5,
        children: [
          Icon(MenuIcons.release, size: 30),
          Text(release, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 30,
        children: [
          DataTable(
            columns: columns,
            rows: stockRow,
          ),
          Row(
            spacing: 30,
            children: [
              SizedBox(
                width: 200,
                child: SpinBox(
                  min: 1,
                  max: widget.selectedStock.quantity!.toDouble(),
                  step: 1,
                  decoration: InputDecoration(
                    labelText: '출고(사용) 수량',
                  ),
                  value: releaseQuantity,
                  onChanged: (value) {
                    setState(() {
                      releaseQuantity = value;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 180,
                child: TextField(
                  controller: TextEditingController(text: currentUserName),
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: '시스템 사용자',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            width: 700,
            child: TextField(
              controller: memoFieldController,
              maxLines: 4,
              maxLength: 300,
              decoration: InputDecoration(
                labelText: '메모',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            final value = memoFieldController.text.trim();
            if (value != "") {
              Navigator.of(context).pop(int.parse(value));
            }
          },
          child: Text('확인'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('취소'),
        ),
      ],
    );
  }
}