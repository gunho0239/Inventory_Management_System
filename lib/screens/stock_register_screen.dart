import 'package:flutter/material.dart';
import 'package:inventory_management/constants/columns.dart';
import 'package:inventory_management/datatable_source/stock_data.dart';
import 'package:inventory_management/enums/inventory_menu.dart';
import 'package:inventory_management/models/location.dart';
import 'package:inventory_management/models/part.dart';
import 'package:inventory_management/models/part_maker.dart';
import 'package:inventory_management/models/part_type.dart';
import 'package:inventory_management/models/person.dart';
import 'package:inventory_management/models/stock.dart';
import 'package:inventory_management/models/stock_history.dart';
import 'package:inventory_management/models/stock_history_category.dart';
import 'package:inventory_management/providers/category_provider.dart';
import 'package:inventory_management/providers/data_table_options_provider.dart';
import 'package:inventory_management/providers/maker_provider.dart';
import 'package:inventory_management/providers/person_provider.dart';
import 'package:inventory_management/providers/type_provider.dart';
import 'package:inventory_management/repository/stock_history_repository.dart';
import 'package:inventory_management/repository/stock_repository.dart';
import 'package:inventory_management/screens/location_select_dialog.dart';
import 'package:inventory_management/screens/part_select_with_condition_dialog.dart';
import 'package:inventory_management/screens/user_management_dialog.dart';
import 'package:inventory_management/widgets/buttons.dart';
import 'package:inventory_management/widgets/icon_label.dart';
import 'package:inventory_management/widgets/title.dart';
import 'package:inventory_management/widgets/dialogs.dart';
import 'package:provider/provider.dart';

import '../enums/label_type.dart';

class StockRegisterScreen extends StatefulWidget {
  const StockRegisterScreen({super.key});

  @override
  State<StockRegisterScreen> createState() => _StockRegisterScreenState();
}

class _StockRegisterScreenState extends State<StockRegisterScreen> {
  bool refresh = false;

  final TextEditingController _typeFieldController = TextEditingController();
  final TextEditingController _makerFieldController = TextEditingController();
  final TextEditingController _specFieldController = TextEditingController();
  final TextEditingController _memoFieldController = TextEditingController();

  final List<DataColumn> _columns = [
    DataColumn(label: Text(type)),
    DataColumn(label: Text(specification)),
    DataColumn(label: Text(maker)),
    DataColumn(label: Text(quantity)),
    DataColumn(label: Text(location)),
  ];
  Stock? _newStock;
  late StockDataSource _dataSource;
  Key _dataTableKey = UniqueKey();
  final List<Stock> _addedStocks = [];
  final List<Stock> _selectedStocks = [];


  bool _validateStocks() {
    for (var stock in _addedStocks) {
      if (stock.quantity == null || stock.location == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('재고의 수량과 위치를 입력해 주세요.')),
        );
        return false;
      }
    }

    return true;
  }

  Future<List<Stock>?> _registerAllStocks() async {
    List<Stock> stockList = _addedStocks;

    List<Stock> registeredStocks = await StockRepository()
        .addStocks(stockList);

    return registeredStocks;
  }

  Future<void> _createStockHistories(List<Stock> registeredStocks) async {
    final currentUser = Provider.of<PersonProvider>(context, listen: false).currentUser;
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final category = categoryProvider.getCategory(StockHistoryCategoryType.register);
    final memo = _memoFieldController.text.trim();
    
    final stockHistories = registeredStocks.map((stock) {
      final stockLocation = '${stock.location?.section.section ?? ""}-${stock.location?.number ?? ""}';

      return StockHistory(
        category: category,
        memo: memo,
        type: stock.part?.type.type ?? "",
        specification: stock.part?.specification ?? "",
        maker: stock.part?.maker.maker ?? "",
        unit: stock.part?.unit.unit ?? "",
        beforeQuantity: 0,
        afterQuantity: stock.quantity ?? 0,
        beforeLocation: "",
        afterLocation: stockLocation,
        person: currentUser?.name ?? "",
      );
    }).toList();

    final stockHistoryRepo = StockHistoryRepository();
    stockHistoryRepo.addHistories(stockHistories);
  }

  void _showPartDialog(PartType? selectedType, PartMaker? selectedMaker, String? specFilter) async {
    final newPart = await showDialog<Part>(
      context: context,
      builder: (context) => PartSelectWithConditionDialog(
        selectedType: selectedType,
        selectedMaker: selectedMaker,
        specFilter: specFilter,
      ),
    );

    if (newPart != null) {
      _newStock = Stock(
        part: newPart,
      );

      _addedStocks.add(_newStock!);
      _dataSource.updateData(_addedStocks);
    }

    setState(() {
      _typeFieldController.text = "";
      _makerFieldController.text = "";
      _specFieldController.text = "";
    });
  }


  @override
  void initState() {
    super.initState();
    final typeProvider = Provider.of<TypeProvider>(context, listen: false);
    typeProvider.reloadTypes();

    final makerProvider = Provider.of<MakerProvider>(context, listen: false);
    makerProvider.reloadMakers();

    final personProvider = Provider.of<PersonProvider>(context, listen: false);
    personProvider.reloadPersons();

    _dataSource = StockDataSource(
      stocks: _addedStocks,
      selectedStocks: _selectedStocks,
      onSelectChanged: (stock, selected) {
        if (selected) {
          _selectedStocks.add(stock);
        } else {
          _selectedStocks.remove(stock);
        }
      },
      onQuantityTapped: () async {
        int? quantity = await showDialog<int>(
          context: context,
          builder: (context) => NumberInputDialog(
            title: "수량 변경",
            labelText: "수량",
          ),
        );

        return quantity;
      },
      onLocationTapped: () async {
        final selectedLocation = await showDialog<Location>(
          context: context,
          builder: (context) => LocationSelectDialog(),
        );

        return selectedLocation;
      }
    );
  }


  @override
  Widget build(BuildContext context) {
    final typeProvider = Provider.of<TypeProvider>(context);
    final makerProvider = Provider.of<MakerProvider>(context);
    final personProvider = Provider.of<PersonProvider>(context, listen: false);
    final tableOptionsProvider = context.watch<DataTableOptionsProvider>();


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScreenTitle(menu: InventoryMenu.stockRegister),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 5,
                  children: [
                    DropdownMenu<PartType>(
                      controller: _typeFieldController,
                      label: IconLabel(labelType: LabelType.type),
                      enableFilter: true,
                      menuHeight: 400,
                      width: 200,
                      onSelected: (type) {
                        if (type != null) {
                          _showPartDialog(type, null, null);
                        }
                      },
                      dropdownMenuEntries:
                          typeProvider.typesDropdownWithAll,
                    ),
                    DropdownMenu<PartMaker>(
                      controller: _makerFieldController,
                      label: IconLabel(labelType: LabelType.maker),
                      enableFilter: true,
                      menuHeight: 400,
                      width: 200,
                      onSelected: (maker) {
                        if (maker != null) {
                          _showPartDialog(null, maker, null);
                        }
                      },
                      dropdownMenuEntries:
                          makerProvider.makersDropdownWithAll,
                    ),
                    SizedBox(
                      width: 200,
                      child: TextField(
                        controller: _specFieldController,
                        decoration: InputDecoration(
                          label: IconLabel(labelType: LabelType.specification),
                          hintText: "입력 후 엔터",
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (spec) {
                          _showPartDialog(null, null, spec.trim());
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 20.0,
                  ),
                  child: SizedBox(
                    width: 1500,
                    child: Row(
                      spacing: 20,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: PaginatedDataTable(
                              key: _dataTableKey,
                              columns: _columns,
                              source: _dataSource,
                              rowsPerPage: tableOptionsProvider.rowsPerPage,
                              availableRowsPerPage: tableOptionsProvider.availableRowsPerPage,
                              onRowsPerPageChanged: (value) {
                                if (value != null) {
                                  tableOptionsProvider.updateRowsPerPage(value);
                                }
                              },
                              showCheckboxColumn: true,
                              showFirstLastButtons: true,
                            ),
                          ),
                        ),
                        Column(
                          spacing: 20,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              spacing: 5, 
                              children: [
                                DropdownMenu<Person>(
                                  label: Text("System User"),
                                  enableFilter: true,
                                  menuHeight: 400,
                                  width: 150,
                                  initialSelection: personProvider.currentUser,
                                  onSelected: (person) {
                                    if (person != null) {
                                      personProvider.currentUser = person;
                                    }
                                  },
                                  dropdownMenuEntries:
                                      personProvider.personsDropdown,
                                ),
                                EditButton(
                                  onPressed: () async {
                                    final refresh = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => UserManagementDialog(),
                                    );
                    
                                    if (refresh == true) {
                                      setState(() {});
                                    }
                                  },
                                ),
                              ],
                            ),
                            SizedBox(
                              width: 300,
                              child: TextField(
                                controller: _memoFieldController,
                                maxLines: 3,
                                maxLength: 150,
                                decoration: InputDecoration(
                                  labelText: '재고 등록 메모 (선택)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            SaveAllButton(
                              onPressed: () async {
                                if (_addedStocks.isEmpty) return;

                                if (!_validateStocks()) return;
                    
                                if (personProvider.currentUser == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('시스템 사용자를 선택해주세요.')),
                                  );
                                  return;
                                }
                    
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) =>
                                      ConfirmDialog(message: "전체등록 하시겠습니까?"),
                                );
                                if (!context.mounted) return;
                    
                                if (confirmed == true) {
                                  final registeredStocks = await _registerAllStocks();
                                  if (!context.mounted) return;
                    
                                  if (registeredStocks != null && registeredStocks.isNotEmpty) {
                    
                                    _createStockHistories(registeredStocks);
                    
                                    setState(() {
                                      _addedStocks.clear();
                                      _dataTableKey = UniqueKey();
                                      refresh = true;
                                    });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${registeredStocks.length}개의 재고가 등록되었습니다.')),
                                    );
                                  } 
                                  else {
                                    showDialog(
                                      context: context,
                                      builder: (context) =>
                                          ErrorDialog(message: '이미 등록된 재고입니다.'),
                                    );
                                  }
                                }
                              },
                            ),
                            DeleteButton(onPressed: () {
                              if (_selectedStocks.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('삭제할 재고를 선택해주세요.')),
                                );
                                return;
                              }
                                
                              _addedStocks.removeWhere((stock) => _selectedStocks.contains(stock));
                              _selectedStocks.clear();
                              _dataSource.updateSelected();
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
