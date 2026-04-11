import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/constants/columns.dart';
import 'package:inventory_management/datatable_source/stock_history_data.dart';
import 'package:inventory_management/enums/inventory_menu.dart';
import 'package:inventory_management/enums/label_type.dart';
import 'package:inventory_management/models/stock_history.dart';
import 'package:inventory_management/models/stock_history_category.dart';
import 'package:inventory_management/providers/category_provider.dart';
import 'package:inventory_management/providers/data_table_options_provider.dart';
import 'package:inventory_management/repository/stock_history_repository.dart';
import 'package:inventory_management/screens/stock_history_details_dialog.dart';
import 'package:inventory_management/widgets/icon_label.dart';
import 'package:inventory_management/widgets/title.dart';
import 'package:provider/provider.dart';

class StockHistoryScreen extends StatefulWidget {
  const StockHistoryScreen({super.key});

  @override
  State<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends State<StockHistoryScreen> {
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final StockHistoryRepository _historyRepo = StockHistoryRepository();

  DateTime? _selectedStartDate;
  late DateTime? _selectedEndDate;
  late StockHistoryCategory _selectedCategory;

  // 컨트롤러 및 포커스 노드
  final TextEditingController _startDateFieldController = TextEditingController();
  final TextEditingController _endDateFieldController = TextEditingController();
  final TextEditingController _typeFieldController = TextEditingController();
  final TextEditingController _specFieldController = TextEditingController();
  final TextEditingController _makerFieldController = TextEditingController();
  final TextEditingController _memoFieldController = TextEditingController();

  final FocusNode _typeFieldFocusNode = FocusNode();
  final FocusNode _specFieldFocusNode = FocusNode();
  final FocusNode _makerFieldFocusNode = FocusNode();
  final FocusNode _memoFieldFocusNode = FocusNode();

  final List<DataColumn> _columns = const [
    DataColumn(label: Text(date)),
    DataColumn(label: Text(category)),
    DataColumn(label: Text(memo)),
    DataColumn(label: Text(type)),
    DataColumn(label: Text(specification)),
    DataColumn(label: Text(maker)),
    DataColumn(label: Text(quantity)),
    DataColumn(label: Text(location)),
    DataColumn(label: Text(systemUser)),
  ];

  late StockHistoryDataSource _dataSource;
  Key _dataTableKey = UniqueKey();
  
  List<StockHistory> _inquiredStockHistories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // 1. [개선] 10개의 객체에 대한 완벽한 메모리 해제
  @override
  void dispose() {
    _startDateFieldController.dispose();
    _endDateFieldController.dispose();
    _typeFieldController.dispose();
    _specFieldController.dispose();
    _makerFieldController.dispose();
    _memoFieldController.dispose();
    
    _typeFieldFocusNode.dispose();
    _specFieldFocusNode.dispose();
    _makerFieldFocusNode.dispose();
    _memoFieldFocusNode.dispose();
    super.dispose();
  }

  // 2. [개선] 초기화 및 DataSource 1회 생성
  void _initializeData() {
    final now = DateTime.now();
    _selectedEndDate = now;
    _selectedStartDate = DateTime(now.year, now.month - 6, now.day);
    
    _endDateFieldController.text = _dateFormat.format(_selectedEndDate!);
    _startDateFieldController.text = _dateFormat.format(_selectedStartDate!);

    // DataSource 단 1번만 생성
    _dataSource = StockHistoryDataSource(
      stockHistories: _inquiredStockHistories,
      onSelectChanged: (stockHistory, selected) {
        showDialog(
          context: context,
          builder: (BuildContext context) => HistoryDetailsDialog(selectedHistory: stockHistory),
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      if (categoryProvider.categories.isEmpty) {
        await categoryProvider.reloadCategories();
      }
      if (mounted) {
        _selectedCategory = categoryProvider.allCategory;
        _getHistories();
      }
    });
  }

  // 3. [개선] 비동기 데이터 로딩 및 mounted 안전성 확보
  Future<void> _getHistories() async {
    setState(() => _isLoading = true);

    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);

    final bool hasStartDate = _selectedStartDate != null;
    final bool hasEndDate = _selectedEndDate != null;
    final bool isAllCategory = _selectedCategory == categoryProvider.allCategory;
    final String typeText = _typeFieldController.text.trim();
    final String specText = _specFieldController.text.trim();
    final String makerText = _makerFieldController.text.trim();
    final String memoText = _memoFieldController.text.trim();

    final result = await switch ((!hasStartDate, !hasEndDate, isAllCategory, typeText.isEmpty, specText.isEmpty, makerText.isEmpty, memoText.isEmpty)) {
      (true, true, true, true, true, true, true) => _historyRepo.getAllHistories(),
      (true, true, false, true, true, true, true) => _historyRepo.getHistoriesByCategory(_selectedCategory.id!),
      _ => _historyRepo.getHistoriesByFilter(
            hasStartDate ? _selectedStartDate : null,
            hasEndDate ? _selectedEndDate : null,
            isAllCategory ? null : _selectedCategory.id!,
            typeText.isEmpty ? null : typeText,
            specText.isEmpty ? null : specText,
            makerText.isEmpty ? null : makerText,
            memoText.isEmpty ? null : memoText,
          ),
    };

    if (!mounted) return;

    setState(() {
      _inquiredStockHistories = result;
      _isLoading = false;
      _dataTableKey = UniqueKey(); // 페이지네이션 초기화를 위해 Key 변경
      _dataSource.updateData(_inquiredStockHistories); // 표 데이터만 갱신
    });
  }

  Future<DateTime?> _selectDate(DateTime? selectedDate, TextEditingController dateFieldController) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      currentDate: _selectedStartDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && mounted) {
      dateFieldController.text = _dateFormat.format(pickedDate);
    }
    return pickedDate;
  }

  bool _isStartDateAfterEndDate() {
    return _selectedStartDate != null &&
          _selectedEndDate != null && 
          _selectedStartDate!.isAfter(_selectedEndDate!);
  }

  // 4. [개선] UI 렌더링 영역 분리 (가독성 향상)
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ScreenTitle(menu: InventoryMenu.stockHistory),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                _buildFilterBar(),
                _buildDataTable(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    final categoryProvider = Provider.of<CategoryProvider>(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.only(top: 5.0, bottom: 10.0),
        child: Row(
          spacing: 10,
          children: [
            SizedBox(
              width: 150,
              child: TextField(
                controller: _startDateFieldController,
                decoration: const InputDecoration(
                  labelText: "시작 날짜",
                  suffixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () async {
                  final DateTime? selectedDate = await _selectDate(_selectedStartDate, _startDateFieldController);
                  if (selectedDate != null) {
                    _selectedStartDate = selectedDate;
                    if (_isStartDateAfterEndDate()) {
                      _selectedEndDate = DateTime(_selectedStartDate!.year, _selectedStartDate!.month, _selectedStartDate!.day, 23, 59, 59);
                      _endDateFieldController.text = _dateFormat.format(_selectedEndDate!);
                    }
                    _getHistories();
                  }
                },
              ),
            ),
            SizedBox(
              width: 150,
              child: TextField(
                controller: _endDateFieldController,
                decoration: const InputDecoration(
                  labelText: "종료 날짜",
                  suffixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () async {
                  final DateTime? selectedDate = await _selectDate(_selectedEndDate, _endDateFieldController);
                  if (selectedDate != null) {
                    _selectedEndDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);
                    if (_isStartDateAfterEndDate()) {
                      _selectedStartDate = DateTime(_selectedEndDate!.year, _selectedEndDate!.month, _selectedEndDate!.day, 0, 0, 0);
                      _startDateFieldController.text = _dateFormat.format(_selectedStartDate!);
                    }
                    _getHistories();
                  }
                },
              ),
            ),
            DropdownMenu<StockHistoryCategory>(
              label: const Text("구분"),
              enableFilter: true,
              menuHeight: 400,
              width: 150,
              initialSelection: categoryProvider.allCategory, // 초기값 설정
              onSelected: (category) {
                if (category != null) {
                  _selectedCategory = category;
                  _getHistories();
                }
              },
              dropdownMenuEntries: categoryProvider.categoriesDropdownWithAll,
            ),
            SizedBox(
              width: 150,
              child: TextField(
                controller: _memoFieldController,
                focusNode: _memoFieldFocusNode,
                decoration: const InputDecoration(
                  label: IconLabel(labelType: LabelType.memo),
                  hintText: "입력 후 엔터",
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) {
                  _getHistories();
                  FocusScope.of(context).requestFocus(_memoFieldFocusNode);
                },
              ),
            ),
            SizedBox(
              width: 150,
              child: TextField(
                controller: _typeFieldController,
                focusNode: _typeFieldFocusNode,
                decoration: const InputDecoration(
                  label: IconLabel(labelType: LabelType.type),
                  hintText: "입력 후 엔터",
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) {
                  _getHistories();
                  FocusScope.of(context).requestFocus(_typeFieldFocusNode);
                },
              ),
            ),
            SizedBox(
              width: 180,
              child: TextField(
                controller: _specFieldController,
                focusNode: _specFieldFocusNode,
                decoration: const InputDecoration(
                  label: IconLabel(labelType: LabelType.specification),
                  hintText: "입력 후 엔터",
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) {
                  _getHistories();
                  FocusScope.of(context).requestFocus(_specFieldFocusNode);
                },
              ),
            ),
            SizedBox(
              width: 150,
              child: TextField(
                controller: _makerFieldController,
                focusNode: _makerFieldFocusNode,
                decoration: const InputDecoration(
                  label: IconLabel(labelType: LabelType.maker),
                  hintText: "입력 후 엔터",
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) {
                  _getHistories();
                  FocusScope.of(context).requestFocus(_makerFieldFocusNode);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    final tableOptionsProvider = context.watch<DataTableOptionsProvider>();

    if (_isLoading) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }

    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible( // 하드코딩된 width: 1600 제거 및 Flexible 적용
            child: SingleChildScrollView(
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
                showCheckboxColumn: false,
                showFirstLastButtons: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}