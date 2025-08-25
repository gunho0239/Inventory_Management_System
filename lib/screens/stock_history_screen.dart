import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/datatable_source/stock_history_data.dart';
import 'package:inventory_management/enums/inventory_menu.dart';
import 'package:inventory_management/enums/label_type.dart';
import 'package:inventory_management/models/stock_history.dart';
import 'package:inventory_management/models/stock_history_category.dart';
import 'package:inventory_management/providers/category_provider.dart';
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
  
  DateTime? _selectedStartDate;
  late DateTime? _selectedEndDate;
  late StockHistoryCategory selectedCategory;

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

  final List<DataColumn> _columns = [
    DataColumn(label: Text('일시')),
    DataColumn(label: Text('구분')),
    DataColumn(label: Text('메모')),
    DataColumn(label: Text('품명')),
    DataColumn(label: Text('규격')),
    DataColumn(label: Text('제조사')),
    DataColumn(label: Text('단위')),
    DataColumn(label: Text('수량')),
    DataColumn(label: Text('위치')),
    DataColumn(label: Text('시스템 사용자')),
  ];
  late StockHistoryDataSource _dataSource;
  Key _dataTableKey = UniqueKey();
  List<StockHistory> _inquiredStockHistories = [];

  @override
  void initState() {
    super.initState();

    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    selectedCategory = categoryProvider.allCategory;

    final now = DateTime.now();
    _selectedEndDate = now;
    _selectedStartDate = DateTime(now.year, now.month, now.day - 7);
    _endDateFieldController.text = _dateFormat.format(_selectedEndDate!);
    _startDateFieldController.text = _dateFormat.format(_selectedStartDate!);
    
    getHistories();
  }

  void getHistories() async {
    StockHistoryRepository historyRepo = StockHistoryRepository();
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);

    final bool hasStartDate = _selectedStartDate != null;
    final bool hasEndDate = _selectedEndDate != null;
    final bool isAllCategory = selectedCategory == categoryProvider.allCategory;
    final String typeText = _typeFieldController.text.trim();
    final String specText = _specFieldController.text.trim();
    final String makerText = _makerFieldController.text.trim();
    final String memoText = _memoFieldController.text.trim();

    _inquiredStockHistories = await switch ((!hasStartDate, !hasEndDate, isAllCategory, typeText.isEmpty, specText.isEmpty, makerText.isEmpty, memoText.isEmpty)) {
      (true, true, true, true, true, true, true) => historyRepo.getAllHistories(),
      (true, true,false, true, true, true, true) => historyRepo.getHistoriesByCategory(selectedCategory.id!),
      _ => historyRepo.getHistoriesByFilter(
              hasStartDate ? _selectedStartDate : null,
              hasEndDate ? _selectedEndDate : null,
              isAllCategory ? null : selectedCategory.id!,
              typeText.isEmpty ? null : typeText,
              specText.isEmpty ? null : specText,
              makerText.isEmpty ? null : makerText,
              memoText.isEmpty ? null : memoText,
            ),
    };

    _dataTableKey = UniqueKey();

    setState(() {});
  }

  Future<DateTime?> _selectDate(DateTime? selectedDate, TextEditingController dateFieldController) async {
    selectedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      currentDate: _selectedStartDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      dateFieldController.text = _dateFormat.format(selectedDate);
    }

    return selectedDate;
  }

  bool _isStartDateAfterEndDate() {
    return _selectedStartDate != null &&
          _selectedEndDate != null && 
          _selectedStartDate!.isAfter(_selectedEndDate!);
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);

    _dataSource = StockHistoryDataSource(
      stockHistories: _inquiredStockHistories,
      onSelectChanged: (stockHistory, selected) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return HistoryDetailsDialog(selectedHistory: stockHistory);
          },
        );
        // setState(() {
        //   if (selected) {
        //     _selectedStockHistory = stockHistory;
        //   } else {
        //     _selectedStockHistory = null;
        //   }
        // });
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScreenTitle(menu: InventoryMenu.stockHistory),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: Row(
                      spacing: 10,
                      children: [
                        SizedBox(
                          width: 150,
                          child: TextField(
                            controller: _startDateFieldController,
                            decoration: InputDecoration(
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
                                getHistories();
                              }
                            },
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          child: TextField(
                            controller: _endDateFieldController,
                            decoration: InputDecoration(
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
                                getHistories();
                              }
                            },
                          ),
                        ),
                        DropdownMenu<StockHistoryCategory>(
                          label: Text("구분"),
                          enableFilter: true,
                          menuHeight: 400,
                          width: 150,
                          onSelected: (category) {
                            selectedCategory = category ?? categoryProvider.allCategory;
                            getHistories();
                          },
                          dropdownMenuEntries:
                              categoryProvider.categoriesDropdownWithAll,
                        ),
                        SizedBox(
                          width: 150,
                          child: TextField(
                            controller: _memoFieldController,
                            focusNode: _memoFieldFocusNode,
                            decoration: InputDecoration(
                              label: IconLabel(labelType: LabelType.memo),
                              hintText: "입력 후 엔터",
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (memo) {
                              getHistories();
                              FocusScope.of(context).requestFocus(_memoFieldFocusNode);
                            },
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          child: TextField(
                            controller: _typeFieldController,
                            focusNode: _typeFieldFocusNode,
                            decoration: InputDecoration(
                              label: IconLabel(labelType: LabelType.type),
                              hintText: "입력 후 엔터",
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (type) {
                              getHistories();
                              FocusScope.of(context).requestFocus(_typeFieldFocusNode);
                            },
                          ),
                        ),
                        SizedBox(
                          width: 180,
                          child: TextField(
                            controller: _specFieldController,
                            focusNode: _specFieldFocusNode,
                            decoration: InputDecoration(
                              label: IconLabel(labelType: LabelType.specification),
                              hintText: "입력 후 엔터",
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (spec) {
                              getHistories();
                              FocusScope.of(context).requestFocus(_specFieldFocusNode);
                            },
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          child: TextField(
                            controller: _makerFieldController,
                            focusNode: _makerFieldFocusNode,
                            decoration: InputDecoration(
                              label: IconLabel(labelType: LabelType.maker),
                              hintText: "입력 후 엔터",
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (maker) {
                              getHistories();
                              FocusScope.of(context).requestFocus(_makerFieldFocusNode);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: SingleChildScrollView(
                          child: SizedBox(
                            width: 1150,
                            child: PaginatedDataTable(
                              key: _dataTableKey,
                              columns: _columns,
                              source: _dataSource,
                              rowsPerPage: 10,
                              showCheckboxColumn: false,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
