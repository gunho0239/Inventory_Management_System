import 'package:flutter/material.dart';
import 'package:flutter_spinbox/material.dart';
import 'package:inventory_management/constants/columns.dart';
import 'package:inventory_management/constants/menu_name.dart';
import 'package:inventory_management/dto/bulk_request_result_with_ids.dart';
import 'package:inventory_management/models/quantity_change_stock.dart';
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
  final List<Stock> selectedStocks;

  const QuantityChangeDialog({super.key, required this.selectedStocks});

  @override
  State<QuantityChangeDialog> createState() => _QuantityChangeDialogState();
}

class _QuantityChangeDialogState extends State<QuantityChangeDialog> {
  final TextEditingController memoFieldController = TextEditingController();
  late final String currentUserName;

  List<QuantityChangedStock> changedStocks = [];
  final List<DataColumn> columns = [
    DataColumn(label: Text(type)),
    DataColumn(label: Text(specification)),
    DataColumn(label: Text(maker)),
    DataColumn(label: Text(quantity)),
    DataColumn(label: Text(location)),
    DataColumn(label: Text(newQuantity)),
    DataColumn(label: Text(deleteStock)),
  ];
  late List<DataRow> _stockRow;


  Future<BulkRequestResultWithIds> updateStock() async {
    List<Stock> stocksToUpdate = [];
    List<Stock> stocksToRemove = [];

    for (final changedStock in changedStocks) {
      final stock = changedStock.stock;

      if (changedStock.newQuantity > 0) {
        final modifiedStock = Stock(
          id: stock.id,
          part: stock.part,
          location: stock.location,
          quantity: changedStock.newQuantity,
          version: stock.version,
        );

        stocksToUpdate.add(modifiedStock);
      }
      else {
        stocksToRemove.add(stock);
      }
    }

    final stockRepo = StockRepository();
    late final BulkRequestResultWithIds result;

    final updateResult = await stockRepo.updateStocks(stocksToUpdate);
    final removeResult = await stockRepo.removeStocks(stocksToRemove);

    result = BulkRequestResultWithIds(
      successIds: List<int>.from(removeResult.successIds)..addAll(updateResult.successIds),
      failedIds: List<int>.from(removeResult.failedIds)..addAll(updateResult.failedIds),
    );

    return result;
  }

  Future<void> createStockHistory(BulkRequestResultWithIds updateResult) async {
    List<StockHistory> stockHistories = [];

    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final personProvider = Provider.of<PersonProvider>(context, listen: false);
    
    for (final changedStock in changedStocks) {
      if (changedStock.newQuantity == changedStock.stock.quantity) {
        continue; // 수량 변경이 없는 경우 기록하지 않음
      }

      if (updateResult.failedIds.contains(changedStock.stock.id)) {
        continue; // 재고 수량 변경에 실패한 재고는 이력 생성하지 않음
      }

      final stock = changedStock.stock;
      final afterQuantity = changedStock.newQuantity;
      final stockLocation = '${stock.location?.section.section ?? ""}-${stock.location?.number ?? ""}';

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
      stockHistories.add(stockHistory);
    }

    final stockHistoryRepo = StockHistoryRepository();
    stockHistoryRepo.addHistories(stockHistories);
  }

  String getFailedMessage(BulkRequestResultWithIds result) {
    List<QuantityChangedStock> failedChanges = changedStocks
        .where(
          (changedStock) => result.failedIds.contains(changedStock.stock.id),
        )
        .toList();

    String failedChangesInfo = failedChanges
        .map((changedStock) {
          final stock = changedStock.stock;

          return '${stock.part?.type.type ?? ""}  |  ${(stock.part?.specification ?? "")}  |  ${(stock.part?.maker.maker ?? "")}  |  ${(stock.part?.unit.unit ?? "")}  |  ${(stock.quantity?.toString() ?? "")}  |  ${('${stock.location?.section.section ?? ""}${stock.location?.number.toString() ?? ""}')}  |  ${changedStock.newQuantity.toString()}';
        })
        .join('\n');

    return '성공: ${result.successIds.length}건, 실패: ${result.failedIds.length}건'
    '\n실패 사유: 작업 도중에 데이터가 다른 사용자에 의해 변경되었습니다. 최신 데이터를 다시 조회하여 작업해 주세요.'
    '\n\n<실패한 재고>'
    '\n품명  |  규격  |  제조사  |  단위  |  수량  |  위치  |  변경수량'
    '\n$failedChangesInfo';
  }

  @override
  void initState() {
    super.initState();

    changedStocks = widget.selectedStocks.map((stock) => QuantityChangedStock(stock: stock)).toList();
    _stockRow = _buildDataRows();

    currentUserName = Provider.of<PersonProvider>(context, listen: false).currentUser!.name!;
  }

  List<DataRow> _buildDataRows() {
    return changedStocks.map((changedStock) {
      Stock stock = changedStock.stock;

      return DataRow(
        cells: [
          DataCell(Text(stock.part?.type.type ?? "")),
          DataCell(Text(stock.part?.specification ?? "")),
          DataCell(Text(stock.part?.maker.maker ?? "")),
          DataCell(Align(
            alignment: Alignment.centerRight,
            child: Text("${stock.quantity?.toString() ?? ""} / ${stock.part?.unit.unit ?? ""}"))),
          DataCell(Text("${stock.location?.section.section ?? ""}-${stock.location?.number.toString() ?? ""}")),
          DataCell(SizedBox(
            width: 90, 
            child: SpinBox(
              keyboardType: TextInputType.number,
              value: changedStock.newQuantity.toDouble(),
              min: 0,
              max: 100000,
              step: 1,
              showButtons: false,
              onChanged: (value) {
                setState(() {
                  changedStock.newQuantity = value.toInt();
                });
              }
            ),
          )),
          DataCell(Checkbox(
            value: changedStock.newQuantity == 0,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  changedStock.newQuantity = 0;
                } else {
                  changedStock.newQuantity = stock.quantity ?? 0;
                }
              });
            },
          )),
        ]);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    _stockRow = _buildDataRows();

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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: columns,
                rows: _stockRow,
              ),
            ),
            Row(
              spacing: 30,
              children: [
                Expanded(
                  child: TextField(
                    controller: memoFieldController,
                    maxLines: 3,
                    maxLength: 150,
                    decoration: InputDecoration(
                      labelText: '메모 (선택)',
                      hintText: '필요 시 입력',
                      border: OutlineInputBorder(),
                    ),
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
              
              createStockHistory(requestResult);

              if (requestResult.failedIds.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('정상적으로 처리되었습니다.')),
                );
              } else {
                await showDialog(
                  context: context,
                  builder: (context) => ErrorDialog(
                    message: getFailedMessage(requestResult),
                    style: TextStyle(fontFamily: 'monospace',),
                  ),
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