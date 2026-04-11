import 'package:flutter/material.dart';
import 'package:flutter_spinbox/material.dart';
import 'package:inventory_management/constants/columns.dart';
import 'package:inventory_management/constants/menu_name.dart';
import 'package:inventory_management/dto/bulk_request_result_with_ids.dart';
import 'package:inventory_management/models/release_stock.dart';
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
  final List<Stock> selectedStocks;

  const ReleaseDialog({super.key, required this.selectedStocks});

  @override
  State<ReleaseDialog> createState() => _ReleaseDialogState();
}

class _ReleaseDialogState extends State<ReleaseDialog> {
  final TextEditingController _memoFieldController = TextEditingController();
  late final String _currentUserName;

  List<ReleaseStock> releaseStocks = [];
  final List<DataColumn> _columns = [
    DataColumn(label: Text(type)),
    DataColumn(label: Text(specification)),
    DataColumn(label: Text(maker)),
    DataColumn(label: Text(quantity)),
    DataColumn(label: Text(location)),
    DataColumn(label: Text(useQuantity)),
    DataColumn(label: Text(useAll)),
  ];
  late List<DataRow> _stockRow;


  Future<BulkRequestResultWithIds> updateStock() async {
    List<Stock> stocksToRemove = [];
    List<Stock> stocksToUpdate = [];

    for (final releaseStock in releaseStocks) {
      final stock = releaseStock.stock;
      final releaseQuantity = releaseStock.useQuantity;
      final totalQuantity = stock.quantity ?? 0;

      if (releaseQuantity > 0) {
        if (releaseQuantity == totalQuantity) {
          stocksToRemove.add(stock);
        }
        else {
          final modifiedStock = Stock(
            id: stock.id,
            part: stock.part,
            location: stock.location,
            quantity: totalQuantity - releaseQuantity,
            version: stock.version,
          );
          stocksToUpdate.add(modifiedStock);
        }
      }
    }
    
    final stockRepo = StockRepository();
    late final BulkRequestResultWithIds result;

    final removeResult = await stockRepo.removeStocks(stocksToRemove);
    final updateResult = await stockRepo.updateStocks(stocksToUpdate);
    
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
    
    for (final releaseStock in releaseStocks) {
      if (releaseStock.useQuantity == 0) continue;

      if (updateResult.failedIds.contains(releaseStock.stock.id)) {
        continue; // 출고 처리에 실패한 재고는 이력 생성하지 않음
      }

      final stock = releaseStock.stock;
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
        afterQuantity: beforeQuantity - releaseStock.useQuantity,
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
    List<ReleaseStock> failedReleases = releaseStocks
        .where(
          (releaseStock) => result.failedIds.contains(releaseStock.stock.id),
        )
        .toList();

    String failedReleasesInfo = failedReleases
        .map((releaseStock) {
          final stock = releaseStock.stock;

          return '${stock.part?.type.type ?? ""}  |  ${(stock.part?.specification ?? "")}  |  ${(stock.part?.maker.maker ?? "")}  |  ${(stock.part?.unit.unit ?? "")}  |  ${(stock.quantity?.toString() ?? "")}  |  ${('${stock.location?.section.section ?? ""}${stock.location?.number.toString() ?? ""}')}  |  ${releaseStock.useQuantity.toString()}';
        })
        .join('\n');

    return '성공: ${result.successIds.length}건, 실패: ${result.failedIds.length}건'
    '\n실패 사유: 작업 도중에 데이터가 다른 사용자에 의해 변경되었습니다. 최신 데이터를 다시 조회하여 작업해 주세요.'
    '\n\n<실패한 재고>'
    '\n품명  |  규격  |  제조사  |  단위  |  수량  |  위치  |  출고수량'
    '\n$failedReleasesInfo';
  }


  @override
  void initState() {
    super.initState();

    releaseStocks = widget.selectedStocks.map((stock) => ReleaseStock(stock: stock)).toList();
    _stockRow = _buildDataRows();

    _currentUserName = Provider.of<PersonProvider>(context, listen: false).currentUser!.name!;
  }

  List<DataRow> _buildDataRows() {
    return releaseStocks.map((releaseStock) {
      Stock stock = releaseStock.stock;

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
            width: 60, 
            child: SpinBox(
              keyboardType: TextInputType.number,
              value: releaseStock.useQuantity.toDouble(),
              min: 0,
              max: stock.quantity!.toDouble(),
              step: 1,
              showButtons: false,
              onChanged: (value) {
                setState(() {
                  releaseStock.useQuantity = value.toInt();
                });
              }
            ),
          )),
          DataCell(Checkbox(
            value: releaseStock.useQuantity == stock.quantity,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  releaseStock.useQuantity = stock.quantity ?? 0;
                } else {
                  releaseStock.useQuantity = 0;
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: _columns,
                rows: _stockRow,
              ),
            ),
            Row(
              spacing: 30,
              children: [
                Expanded(
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
                    style: TextStyle(fontFamily: 'monospace',)
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