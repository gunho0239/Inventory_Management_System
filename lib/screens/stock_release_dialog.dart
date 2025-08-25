import 'package:flutter/material.dart';
import 'package:flutter_spinbox/material.dart';
import 'package:inventory_management/api/api_response_entity.dart';
import 'package:inventory_management/constants/columns.dart';
import 'package:inventory_management/constants/menu_name.dart';
import 'package:inventory_management/models/stock.dart';
import 'package:inventory_management/models/stock_history.dart';
import 'package:inventory_management/models/stock_history_category.dart';
import 'package:inventory_management/providers/category_provider.dart';
import 'package:inventory_management/providers/person_provider.dart';
import 'package:inventory_management/repository/stock_repository.dart';
import 'package:inventory_management/repository/stock_history_repository.dart';
import 'package:inventory_management/widgets/dialogs.dart';
import 'package:inventory_management/widgets/icons.dart';
import 'package:provider/provider.dart';

class ReleaseDialog extends StatefulWidget {
  final Stock selectedStock;

  const ReleaseDialog({super.key, required this.selectedStock});

  @override
  State<ReleaseDialog> createState() => _ReleaseDialogState();
}

class _ReleaseDialogState extends State<ReleaseDialog> {
  final TextEditingController _memoFieldController = TextEditingController();
  late double _releaseQuantity;
  late final String _currentUserName;

  final List<DataColumn> _columns = [
    DataColumn(label: Text(type)),
    DataColumn(label: Text(specification)),
    DataColumn(label: Text(maker)),
    DataColumn(label: Text(unit)),
    DataColumn(label: Text(quantity)),
    DataColumn(label: Text(section)),
    DataColumn(label: Text(number)),
  ];
  late final List<DataRow> _stockRow;


  Future<SingleRequestResult> updateStock() async {
    final stockRepo = StockRepository();
    final stock = widget.selectedStock;
    late final SingleRequestResult result;
    final releaseQuantity = _releaseQuantity.toInt();
    final totalQuantity = stock.quantity ?? 0;

    if (releaseQuantity == totalQuantity) {
      result = await stockRepo.removeStock(stock);
    }
    else {
      final modifiedStock = Stock(
        id: stock.id,
        part: stock.part,
        location: stock.location,
        quantity: totalQuantity - releaseQuantity,
        version: stock.version,
      );

      result = await stockRepo.updateStock(modifiedStock);
    }

    return result;
  }

  Future<void> createStockHistory() async {
    final stockHistoryRepo = StockHistoryRepository();
    final stock = widget.selectedStock;

    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final personProvider = Provider.of<PersonProvider>(context, listen: false);
    final beforeQuantity = stock.quantity ?? 0;
    final stockLocation = '${stock.location?.section.section ?? ""} ${stock.location?.number ?? ""}';

    final stockHistory = StockHistory(
      category: categoryProvider.getCategory(StockHistoryCategoryType.release),
      memo: _memoFieldController.text.trim(),
      type: stock.part?.type.type ?? "",
      specification: stock.part?.specification ?? "",
      maker: stock.part?.maker.maker ?? "",
      unit: stock.part?.unit.unit ?? "",
      beforeQuantity: beforeQuantity,
      afterQuantity: beforeQuantity - _releaseQuantity.toInt(),
      beforeLocation: stockLocation,
      afterLocation: stockLocation,
      person: personProvider.currentUser?.name ?? "",
    );

    stockHistoryRepo.addHistory(stockHistory);
  }


  @override
  void initState() {
    super.initState();

    final stock = widget.selectedStock;
    _releaseQuantity = stock.quantity!.toDouble();
    _stockRow = [
      DataRow(cells: [
          DataCell(Text(stock.part?.type.type ?? "")),
          DataCell(Text(stock.part?.specification ?? "")),
          DataCell(Text(stock.part?.maker.maker ?? "")),
          DataCell(Text(stock.part?.unit.unit ?? "")),
          DataCell(Text(stock.quantity?.toString() ?? "")),
          DataCell(Text(stock.location?.section.section ?? "")),
          DataCell(Text(stock.location?.number.toString() ?? "")),
        ])
    ];

    _currentUserName = Provider.of<PersonProvider>(context, listen: false).currentUser!.name!;
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
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 30,
          children: [
            DataTable(
              columns: _columns,
              rows: _stockRow,
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
                    value: _releaseQuantity,
                    onChanged: (value) {
                      setState(() {
                        _releaseQuantity = value;
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: TextField(
                    controller: TextEditingController(text: _currentUserName),
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
                controller: _memoFieldController,
                maxLines: 3,
                maxLength: 150,
                decoration: InputDecoration(
                  labelText: '메모 (필수)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            if (_memoFieldController.text.trim().isEmpty) {
              showDialog(
                context: context,
                builder: (context) => ErrorDialog(message: '메모를 입력해 주세요.'),
              );
              return;
            }

            final proceed = await showDialog<bool>(
              context: context,
              builder:(context) => ConfirmDialog(message: '출고(사용) 처리 하시겠습니까?'),
            );

            if (!context.mounted) return;
            
            if (proceed == true) {
              final requestResult = await updateStock();
              if (!context.mounted) return;

              if (requestResult.isSuccess) {
                createStockHistory();
                await showDialog(
                  context: context,
                  builder: (context) => ResultDialog(message: '정상적으로 처리되었습니다.')
                );
              } else {
                await showDialog(
                  context: context,
                  builder: (context) => ErrorDialog(message: requestResult.errorMessage ?? "출고(사용) 처리에 실패하였습니다. 새로고침 후 다시 시도해 주세요.")
                );
              }
              if (!context.mounted) return;

              // updateStock() 을 수행했으면 재고조회화면 새로고침
              Navigator.of(context).pop(true);
            }
          },
          child: Text('확인'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: Text('취소'),
        ),
      ],
    );
  }
}