import 'package:flutter/material.dart';
import 'package:flutter_spinbox/material.dart';
import 'package:inventory_management/constants/columns.dart';
import 'package:inventory_management/constants/menu_name.dart';
import 'package:inventory_management/dto/bulk_request_result_with_ids.dart';
import 'package:inventory_management/models/location.dart';
import 'package:inventory_management/models/location_change_stock.dart';
import 'package:inventory_management/models/location_section.dart';
import 'package:inventory_management/models/stock.dart';
import 'package:inventory_management/models/stock_history.dart';
import 'package:inventory_management/models/stock_history_category.dart';
import 'package:inventory_management/providers/category_provider.dart';
import 'package:inventory_management/providers/person_provider.dart';
import 'package:inventory_management/providers/section_provider.dart';
import 'package:inventory_management/repository/stock_repository.dart';
import 'package:inventory_management/repository/stock_history_repository.dart';
import 'package:inventory_management/screens/location_select_with_section_dialog.dart';
import 'package:inventory_management/widgets/dialogs.dart';
import 'package:inventory_management/widgets/icon_label.dart';
import 'package:inventory_management/widgets/icons.dart';
import 'package:provider/provider.dart';

import '../enums/label_type.dart';

class LocationChangeDialog extends StatefulWidget {
  final List<Stock> selectedStocks;

  const LocationChangeDialog({super.key, required this.selectedStocks});

  @override
  State<LocationChangeDialog> createState() => _LocationChangeDialogState();
}

class _LocationChangeDialogState extends State<LocationChangeDialog> {
  final TextEditingController memoFieldController = TextEditingController();
  late final String currentUserName;

  List<LocationChangedStock> changedStocks = [];
  Set<Stock> selectedStocks = {};
  final List<DataColumn> columns = [
    DataColumn(label: Text(type)),
    DataColumn(label: Text(specification)),
    DataColumn(label: Text(maker)),
    DataColumn(label: Text(quantity)),
    DataColumn(label: Text(originalLocation)),
    DataColumn(label: Text(moveLocation)),
    DataColumn(label: Text(moveQuantity)),
  ];
  late List<DataRow> stockRow;

  Future<BulkRequestResultWithIds> updateStock() async {
    List<Stock> stocksToUpdate = [];

    for (final changedStock in changedStocks) {
      final stock = changedStock.stock;

      final relocatedStock = Stock(
        id: stock.id,
        part: stock.part,
        location: changedStock.moveLocation,
        quantity: changedStock.moveQuantity,
        version: stock.version,
      );

      stocksToUpdate.add(relocatedStock);
    }

    final stockRepo = StockRepository();
    final requestResult = await stockRepo.updateStockLocations(stocksToUpdate);

    return requestResult;
  }

  Future<void> createStockHistory(BulkRequestResultWithIds updateResult) async {
    List<StockHistory> stockHistories = [];

    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final personProvider = Provider.of<PersonProvider>(context, listen: false);
    
    for (final changedStock in changedStocks) {
      if (changedStock.moveQuantity == 0 || changedStock.moveLocation == changedStock.stock.location) {
        continue; // 이동 수량이 0이거나 위치가 변경되지 않은 경우 건너뜀
      }

      if (updateResult.failedIds.contains(changedStock.stock.id)) {
        continue; // 재고 수량 변경에 실패한 재고는 이력 생성하지 않음
      }

      final stock = changedStock.stock;
      final beforeLocation = '${stock.location?.section.section ?? ""}-${stock.location?.number ?? ""}';
      final afterLocation = '${changedStock.moveLocation?.section.section ?? ""}-${changedStock.moveLocation?.number ?? ""}';

      final stockHistory = StockHistory(
        category: categoryProvider.getCategory(StockHistoryCategoryType.locationChange),
        memo: memoFieldController.text.trim(),
        type: stock.part?.type.type ?? "",
        specification: stock.part?.specification ?? "",
        maker: stock.part?.maker.maker ?? "",
        unit: stock.part?.unit.unit ?? "",
        beforeQuantity: stock.quantity ?? 0,
        afterQuantity: changedStock.moveQuantity.toInt(),
        beforeLocation: beforeLocation,
        afterLocation: afterLocation,
        person: personProvider.currentUser?.name ?? "",
      );
      stockHistories.add(stockHistory);
    }
    
    final stockHistoryRepo = StockHistoryRepository();
    stockHistoryRepo.addHistories(stockHistories);
  }

  String getFailedMessage(BulkRequestResultWithIds result) {
    List<LocationChangedStock> failedChanges = changedStocks
        .where(
          (changedStock) => result.failedIds.contains(changedStock.stock.id),
        )
        .toList();

    String failedChangesInfo = failedChanges
        .map((changedStock) {
          final stock = changedStock.stock;

          return '${stock.part?.type.type ?? ""}  |  ${(stock.part?.specification ?? "")}  |  ${(stock.part?.maker.maker ?? "")}  |  ${(stock.quantity?.toString() ?? "")}${(stock.part?.unit.unit ?? "")}  |  ${('${stock.location?.section.section ?? ""}${stock.location?.number.toString() ?? ""}')}  |  ${changedStock.moveLocation?.section.section ?? ""}${changedStock.moveLocation?.number.toString() ?? ""}  |  ${changedStock.moveQuantity.toString()}';
        })
        .join('\n');

    return '성공: ${result.successIds.length}건, 실패: ${result.failedIds.length}건'
    '\n실패 사유: 작업 도중에 데이터가 다른 사용자에 의해 변경되었습니다. 최신 데이터를 다시 조회하여 작업해 주세요.'
    '\n\n<실패한 재고>'
    '\n품명  |  규격  |  제조사  |  수량  |  기존위치  |  이동위치  |  이동수량'
    '\n$failedChangesInfo';
  }

  @override
  void initState() {
    super.initState();

    changedStocks = widget.selectedStocks.map((stock) => LocationChangedStock(stock: stock)).toList();
    stockRow = _buildDataRows();

    currentUserName = Provider.of<PersonProvider>(context, listen: false).currentUser!.name!;
  }

  List<DataRow> _buildDataRows() {
    return changedStocks.map((changedStock) {
      Stock stock = changedStock.stock;

      return DataRow(
        selected: selectedStocks.contains(stock),
        onSelectChanged: (selected) {
          setState(() {
            if (selected == true) {
              selectedStocks.add(stock);
            } else {
              selectedStocks.remove(stock);
            }
          });
        },
        cells: [
          DataCell(Text(stock.part?.type.type ?? "")),
          DataCell(Text(stock.part?.specification ?? "")),
          DataCell(Text(stock.part?.maker.maker ?? "")),
          DataCell(Align(
            alignment: Alignment.centerRight,
            child: Text("${stock.quantity?.toString() ?? ""} / ${stock.part?.unit.unit ?? ""}"))),
          DataCell(Text("${stock.location?.section.section ?? ""}-${stock.location?.number.toString() ?? ""}")),
          DataCell(Text("${changedStock.moveLocation?.section.section ?? ""}-${changedStock.moveLocation?.number.toString() ?? ""}")),
          DataCell(SizedBox(
            width: 90, 
            child: SpinBox(
              keyboardType: TextInputType.number,
              value: changedStock.moveQuantity.toDouble(),
              min: 1,
              max: changedStock.stock.quantity?.toDouble() ?? 0,
              step: 1,
              showButtons: false,
              onChanged: (value) {
                setState(() {
                  changedStock.moveQuantity = value.toInt();
                });
              }
            ),
          )),
        ]);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    stockRow = _buildDataRows();
    final sectionProvider = Provider.of<SectionProvider>(context);

    return AlertDialog(
      title: Row(
        spacing: 5,
        children: [
          Icon(MenuIcons.locationChange, size: 30),
          Text(locationChange, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 20,
            children: [
              Text('재고 선택 후 적용',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              DropdownMenu<LocationSection>(
                label: IconLabel(labelType: LabelType.section),
                enableFilter: true,
                menuHeight: 400,
                width: 150,
                onSelected: (section) async {
                  if (selectedStocks.isEmpty) {
                    showDialog(
                      context: context,
                      builder: (context) => ErrorDialog(
                        message: '위치를 적용할 재고를 하나 이상 선택해 주세요.',
                      ),
                    );
                    return;
                  }

                  if (section != null) {
                    final selectedLocation = await showDialog<Location>(
                      context: context,
                      builder: (context) => LocationSelectWithSectionDialog(section: section),
                    );

                    setState(() {
                      for (final stock in selectedStocks) {
                        final changedStock = changedStocks.firstWhere((cs) => cs.stock.id == stock.id);
                        changedStock.moveLocation = selectedLocation;
                      }
                      selectedStocks.clear();
                    });
                  }
                },
                dropdownMenuEntries: sectionProvider.sectionsDropdownWithAll,
              ),
            ],
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 30,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: columns,
                      rows: stockRow,
                      showCheckboxColumn: true,
                    ),
                  ),
                  Row(
                    spacing: 40,
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
                        width: 150,
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
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            bool allLocationSelected = true;

            for (final changedStock in changedStocks) {
              if (changedStock.moveLocation == null) {
                allLocationSelected = false;
                break;
              }
            }
            
            if (!allLocationSelected) {
              showDialog(
                context: context,
                builder: (context) => ErrorDialog(
                  message: '모든 재고의 위치 설정이 완료되지 않았습니다.',
                ),
              );
              return;
            }

            final proceed = await showDialog<bool>(
              context: context,
              builder:(context) => ConfirmDialog(message: '위치를 변경 하시겠습니까?'),
            );

            if (!context.mounted) return;
            
            if (proceed == true) {
              final requestResult = await updateStock();
              if (!context.mounted) return;

              createStockHistory(requestResult);

              if (requestResult.failedIds.isEmpty) {
                await showDialog(
                  context: context,
                  builder: (context) => ResultDialog(message: '정상적으로 처리되었습니다.')
                );
              } else {
                await showDialog(
                  context: context,
                  builder: (context) => ErrorDialog(
                    message: getFailedMessage(requestResult),
                    style: TextStyle(fontFamily: 'monospace'),
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