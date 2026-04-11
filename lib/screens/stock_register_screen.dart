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
  
  late StockDataSource _dataSource;
  Key _dataTableKey = UniqueKey();
  final List<Stock> _addedStocks = [];
  final List<Stock> _selectedStocks = [];

  final StockRepository _stockRepo = StockRepository();
  final StockHistoryRepository _stockHistoryRepo = StockHistoryRepository();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _typeFieldController.dispose();
    _makerFieldController.dispose();
    _specFieldController.dispose();
    _memoFieldController.dispose();
    super.dispose();
  }

  void _initializeData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TypeProvider>(context, listen: false).reloadTypes();
      Provider.of<MakerProvider>(context, listen: false).reloadMakers();
      Provider.of<PersonProvider>(context, listen: false).reloadPersons();
    });

    _dataSource = StockDataSource(
      stocks: _addedStocks,
      selectedStocks: _selectedStocks,
      onSelectChanged: (stock, selected) {
        setState(() {
          if (selected) {
            _selectedStocks.add(stock);
          } else {
            _selectedStocks.remove(stock);
          }
        });
      },
      onQuantityTapped: () async {
        return await showDialog<int>(
          context: context,
          builder: (context) => NumberInputDialog(
            title: "수량 변경",
            labelText: "수량",
          ),
        );
      },
      onLocationTapped: () async {
        return await showDialog<Location>(
          context: context,
          builder: (context) => const LocationSelectDialog(),
        );
      }
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _validateStocks() {
    for (var stock in _addedStocks) {
      if (stock.quantity == null || stock.location == null) {
        _showSnackBar('재고의 수량과 위치를 모두 입력해 주세요.');
        return false;
      }
    }
    return true;
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

    if (!mounted) return;

    if (newPart != null) {
      setState(() {
        _addedStocks.add(Stock(part: newPart));
        _dataSource.updateData(_addedStocks);
        
        // 입력창 초기화
        _typeFieldController.clear();
        _makerFieldController.clear();
        _specFieldController.clear();
      });
    }
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

    _stockHistoryRepo.addHistories(stockHistories);
  }

  Future<void> _handleSaveAll() async {
    if (_addedStocks.isEmpty) return;
    if (!_validateStocks()) return;

    final personProvider = Provider.of<PersonProvider>(context, listen: false);
    if (personProvider.currentUser == null) {
      _showSnackBar('시스템 사용자를 선택해주세요.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmDialog(message: "전체등록 하시겠습니까?"),
    );

    if (!mounted || confirmed != true) return;

    final registeredStocks = await _stockRepo.addStocks(_addedStocks);
    
    if (!mounted) return;

    if (registeredStocks.isNotEmpty) {
      await _createStockHistories(registeredStocks); // 히스토리 등록 대기
      
      if (!mounted) return;

      setState(() {
        _addedStocks.clear();
        _dataTableKey = UniqueKey();
        _memoFieldController.clear(); // 완료 후 메모 초기화
        refresh = true;
      });

      _showSnackBar('${registeredStocks.length}개의 재고가 등록되었습니다.');
    } else {
      showDialog(
        context: context,
        builder: (context) => const ErrorDialog(message: '이미 등록된 재고입니다.'),
      );
    }
  }

  void _handleDeleteSelected() {
    if (_selectedStocks.isEmpty) {
      _showSnackBar('삭제할 재고를 선택해주세요.');
      return;
    }
    setState(() {
      _addedStocks.removeWhere((stock) => _selectedStocks.contains(stock));
      _selectedStocks.clear();
      _dataSource.updateSelected();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ScreenTitle(menu: InventoryMenu.stockRegister),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputRow(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SizedBox(
                    width: 1500,
                    child: Row(
                      spacing: 20,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(child: _buildDataTable()),
                        _buildActionPanel(),
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

  Widget _buildInputRow() {
    final typeProvider = Provider.of<TypeProvider>(context);
    final makerProvider = Provider.of<MakerProvider>(context);

    return Padding(
      padding: const EdgeInsets.only(top: 5.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 5,
        children: [
          DropdownMenu<PartType>(
            controller: _typeFieldController,
            label: const IconLabel(labelType: LabelType.type),
            enableFilter: true,
            menuHeight: 400,
            width: 200,
            onSelected: (type) {
              if (type != null) _showPartDialog(type, null, null);
            },
            dropdownMenuEntries: typeProvider.typesDropdownWithAll,
          ),
          DropdownMenu<PartMaker>(
            controller: _makerFieldController,
            label: const IconLabel(labelType: LabelType.maker),
            enableFilter: true,
            menuHeight: 400,
            width: 200,
            onSelected: (maker) {
              if (maker != null) _showPartDialog(null, maker, null);
            },
            dropdownMenuEntries: makerProvider.makersDropdownWithAll,
          ),
          SizedBox(
            width: 200,
            child: TextField(
              controller: _specFieldController,
              decoration: const InputDecoration(
                label: IconLabel(labelType: LabelType.specification),
                hintText: "입력 후 엔터",
                border: OutlineInputBorder(),
              ),
              onSubmitted: (spec) => _showPartDialog(null, null, spec.trim()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    final tableOptionsProvider = context.watch<DataTableOptionsProvider>();

    return SingleChildScrollView(
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
    );
  }

  Widget _buildActionPanel() {
    final personProvider = Provider.of<PersonProvider>(context);

    return Column(
      spacing: 20,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          spacing: 5,
          children: [
            DropdownMenu<Person>(
              label: const Text("System User"),
              enableFilter: true,
              menuHeight: 400,
              width: 150,
              initialSelection: personProvider.currentUser,
              onSelected: (person) {
                if (person != null) {
                  personProvider.currentUser = person;
                }
              },
              dropdownMenuEntries: personProvider.personsDropdown,
            ),
            EditButton(
              onPressed: () async {
                final refresh = await showDialog<bool>(
                  context: context,
                  builder: (context) => const UserManagementDialog(),
                );
                if (!mounted) return;
                if (refresh == true) setState(() {});
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
            decoration: const InputDecoration(
              labelText: '재고 등록 메모 (선택)',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        SaveAllButton(onPressed: _handleSaveAll),
        DeleteButton(onPressed: _handleDeleteSelected),
      ],
    );
  }
}
