import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_management/constants/columns.dart';
import 'package:inventory_management/datatable_source/stock_data.dart';
import 'package:inventory_management/enums/inventory_menu.dart';
import 'package:inventory_management/models/location.dart';
import 'package:inventory_management/models/location_section.dart';
import 'package:inventory_management/models/part.dart';
import 'package:inventory_management/models/part_maker.dart';
import 'package:inventory_management/models/part_type.dart';
import 'package:inventory_management/models/person.dart';
import 'package:inventory_management/models/stock.dart';
import 'package:inventory_management/models/stock_history.dart';
import 'package:inventory_management/models/stock_history_category.dart';
import 'package:inventory_management/providers/category_provider.dart';
import 'package:inventory_management/providers/maker_provider.dart';
import 'package:inventory_management/providers/person_provider.dart';
import 'package:inventory_management/providers/section_provider.dart';
import 'package:inventory_management/providers/type_provider.dart';
import 'package:inventory_management/repository/stock_history_repository.dart';
import 'package:inventory_management/repository/stock_repository.dart';
import 'package:inventory_management/screens/location_select_dialog.dart';
import 'package:inventory_management/screens/location_select_with_condition_dialog.dart';
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
  final TextEditingController _unitFieldController = TextEditingController();
  final TextEditingController _quantityFieldController = TextEditingController();
  final TextEditingController _sectionFieldController = TextEditingController();
  final TextEditingController _numberFieldController = TextEditingController();
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

  void addStock() {
    if (_newStock != null && _newStock?.part != null && _newStock?.location != null && _quantityFieldController.text.isNotEmpty) {
      _newStock = _newStock!.copyWith(
        quantity: int.tryParse(_quantityFieldController.text),
      );
      _addedStocks.add(_newStock!);
      _dataSource.updateData(_addedStocks);
    } 
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('부품, 수량, 위치를 선택해주세요.'),
        ),
      );
    }
  }

  Future<List<Stock>?> registerAllStocks() async {
    if (_addedStocks.isEmpty) return null;

    List<Stock> stockList = _addedStocks;

    List<Stock> registeredStocks = await StockRepository()
        .addStocks(stockList);

    return registeredStocks;
  }

  Future<void> createStockHistories(List<Stock> registeredStocks) async {
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

  void showPartDialog(PartType? selectedType, PartMaker? selectedMaker, String? specFilter) async {
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
        quantity: _newStock?.quantity,
        location: _newStock?.location,
        version: _newStock?.version,
      );

      setState(() {
        _typeFieldController.text = newPart.type.type ?? "";
        _makerFieldController.text = newPart.maker.maker ?? "";
        _specFieldController.text = newPart.specification;
        _unitFieldController.text = newPart.unit.unit ?? "";
      });
    }
  }

  void showLocationDialog(LocationSection? selectedSection) async {
    final newLocation = await showDialog<Location>(
      context: context,
      builder: (context) => LocationSelectWithConditionDialog(selectedSection: selectedSection),
    );

    if (newLocation != null) {
      _newStock = Stock(
        part: _newStock?.part,
        quantity: _newStock?.quantity,
        location: newLocation,
        version: _newStock?.version,
      );

      setState(() {
        _sectionFieldController.text = newLocation.section.section ?? "";
        _numberFieldController.text = newLocation.number.toString();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final typeProvider = Provider.of<TypeProvider>(context, listen: false);
    typeProvider.reloadTypes();

    final makerProvider = Provider.of<MakerProvider>(context, listen: false);
    makerProvider.reloadMakers();

    final sectionProvider = Provider.of<SectionProvider>(context, listen: false);
    sectionProvider.reloadSections();

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
    final sectionProvider = Provider.of<SectionProvider>(context);
    final personProvider = Provider.of<PersonProvider>(context, listen: false);

    _typeFieldController.text = _newStock?.part?.type.type ?? "";
    _makerFieldController.text = _newStock?.part?.maker.maker ?? "";
    _specFieldController.text = _newStock?.part?.specification ?? "";
    _unitFieldController.text = _newStock?.part?.unit.unit ?? "";
    _sectionFieldController.text = _newStock?.location?.section.section ?? "";
    _numberFieldController.text = _newStock?.location?.number.toString() ?? "";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScreenTitle(menu: InventoryMenu.stockRegister),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 5.0),
                        child: Row(
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
                                  showPartDialog(type, null, null);
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
                                  showPartDialog(null, maker, null);
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
                                  showPartDialog(null, null, spec.trim());
                                },
                              ),
                            ),
                            SizedBox(
                              width: 130,
                              child: TextField(
                                controller: _quantityFieldController,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  label: IconLabel(labelType: LabelType.quantity),
                                  border: OutlineInputBorder(),
                                  suffixText: _newStock?.part?.unit.unit ?? "",
                                ),
                              ),
                            ),
                            DropdownMenu<LocationSection>(
                              controller: _sectionFieldController,
                              label: IconLabel(labelType: LabelType.section),
                              enableFilter: true,
                              menuHeight: 400,
                              width: 150,
                              onSelected: (section) {
                                if (section != null) {
                                  showLocationDialog(section);
                                }
                              },
                              dropdownMenuEntries:
                                  sectionProvider.sectionsDropdownWithAll,
                            ),
                            SizedBox(
                              width: 100,
                              child: TextField(
                                controller: _numberFieldController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  label: IconLabel(labelType: LabelType.number),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: ElevatedButton(
                      child: Icon(Icons.add, size: 30),
                      onPressed: () {
                        addStock();
                      },
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 20.0,
                  ),
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
                            rowsPerPage: 6,
                            showCheckboxColumn: true,
                            showEmptyRows: false,
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
                            width: 200,
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

                              if (personProvider.currentUser == null) {
                                showDialog(
                                  context: context,
                                  builder: (context) =>
                                      ErrorDialog(message: '시스템 사용자를 선택해주세요.'),
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
                                final registeredStocks = await registerAllStocks();
                                if (!context.mounted) return;

                                if (registeredStocks != null && registeredStocks.isNotEmpty) {

                                  createStockHistories(registeredStocks);

                                  setState(() {
                                    _addedStocks.clear();
                                    _dataTableKey = UniqueKey();
                                    refresh = true;
                                  });

                                  showDialog(
                                    context: context,
                                    builder: (context) => ResultDialog(
                                      message: '${registeredStocks.length}개의 재고가 등록되었습니다.',
                                    ),
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
            ],
          ),
        ),
      ],
    );
  }
}
