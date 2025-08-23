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

class QuantityChangeDialog extends StatefulWidget {
  final Stock selectedStock;

  const QuantityChangeDialog({super.key, required this.selectedStock});

  @override
  State<QuantityChangeDialog> createState() => _QuantityChangeDialogState();
}

class _QuantityChangeDialogState extends State<QuantityChangeDialog> {
  final TextEditingController memoFieldController = TextEditingController();
  late double resetQuantity;
  bool deleteStock = false;
  late final String currentUserName;

  final List<DataColumn> columns = [
    DataColumn(label: Text(type)),
    DataColumn(label: Text(specification)),
    DataColumn(label: Text(maker)),
    DataColumn(label: Text(unit)),
    DataColumn(label: Text(quantity)),
    DataColumn(label: Text(section)),
    DataColumn(label: Text(number)),
  ];
  late final List<DataRow> stockRow;


  Future<SingleRequestResult> updateStock() async {
    final stockRepo = StockRepository();
    final stock = widget.selectedStock;
    late final SingleRequestResult result;
    final resetQuantity = this.resetQuantity.toInt();

    if (deleteStock == false) {
      final modifiedStock = Stock(
        id: stock.id,
        part: stock.part,
        location: stock.location,
        quantity: resetQuantity,
        version: stock.version,
      );

      result = await stockRepo.updateStock(modifiedStock);
    }
    else {
      result = await stockRepo.removeStock(stock);
    }

    return result;
  }

  Future<void> createStockHistory() async {
    final stockHistoryRepo = StockHistoryRepository();
    final stock = widget.selectedStock;

    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final personProvider = Provider.of<PersonProvider>(context, listen: false);
    
    final afterQuantity = (deleteStock) ? 0 : resetQuantity.toInt();
    final stockLocation = '${stock.location?.section.section ?? ""} ${stock.location?.number ?? ""}';

    final stockHistory = StockHistory(
      category: categoryProvider.getCategory(StockHistoryCategoryType.quantityChange),
      memo: memoFieldController.text.trim(),
      type: stock.part?.type.type ?? "",
      specification: stock.part?.specification ?? "",
      maker: stock.part?.maker.maker ?? "",
      unit: stock.part?.unit.unit ?? "",
      beforeQuantity: stock.quantity ?? 0,
      afterQuantity: afterQuantity,
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
    resetQuantity = stock.quantity!.toDouble();
    stockRow = [
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

    currentUserName = Provider.of<PersonProvider>(context, listen: false).currentUser!.name!;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        spacing: 5,
        children: [
          Icon(MenuIcons.quantityChange, size: 30),
          Text(quantityChange, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
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
                    step: 1,
                    enabled: !deleteStock,
                    decoration: InputDecoration(
                      labelText: '변경 수량',
                    ),
                    value: resetQuantity,
                    onChanged: (value) {
                      setState(() {
                        resetQuantity = value;
                      });
                    },
                  ),
                ),
                Flexible(
                  child: CheckboxListTile(
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text('재고 삭제', ),
                    value: deleteStock,  
                    onChanged: (value) {  
                      setState(() {  
                        deleteStock = value!;  
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
                maxLines: 3,
                maxLength: 150,
                decoration: InputDecoration(
                  labelText: '메모',
                  hintText: '필요 시 입력',
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
            final proceed = await showDialog<bool>(
              context: context,
              builder:(context) => ConfirmDialog(message: '재고의 수량을 변경 하시겠습니까?'),
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
                  builder: (context) => ErrorDialog(message: requestResult.errorMessage ?? "재고 수량 변경에 실패하였습니다. 새로고침 후 다시 시도해 주세요.")
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