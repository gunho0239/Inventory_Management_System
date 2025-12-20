import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_management/constants/columns.dart';
import 'package:inventory_management/datatable_source/stock_data.dart';
import 'package:inventory_management/enums/inventory_menu.dart';
import 'package:inventory_management/models/location.dart';
import 'package:inventory_management/models/part.dart';
import 'package:inventory_management/models/person.dart';
import 'package:inventory_management/models/stock.dart';
import 'package:inventory_management/models/stock_history.dart';
import 'package:inventory_management/models/stock_history_category.dart';
import 'package:inventory_management/providers/category_provider.dart';
import 'package:inventory_management/providers/person_provider.dart';
import 'package:inventory_management/repository/stock_history_repository.dart';
import 'package:inventory_management/repository/stock_repository.dart';
import 'package:inventory_management/screens/location_select_dialog.dart';
import 'package:inventory_management/screens/part_select_dialog.dart';
import 'package:inventory_management/screens/user_management_dialog.dart';
import 'package:inventory_management/style/style.dart';
import 'package:inventory_management/widgets/buttons.dart';
import 'package:inventory_management/widgets/title.dart';
import 'package:inventory_management/widgets/dialogs.dart';
import 'package:provider/provider.dart';

class StockRegisterScreen extends StatefulWidget {
  const StockRegisterScreen({super.key});

  @override
  State<StockRegisterScreen> createState() => _StockRegisterScreenState();
}

class _StockRegisterScreenState extends State<StockRegisterScreen> {
  bool refresh = false;

  final TextEditingController _memoFieldController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  final List<DataColumn> _columns = [
    DataColumn(label: Text(type)),
    DataColumn(label: Text(specification)),
    DataColumn(label: Text(maker)),
    DataColumn(label: Text(unit)),
    DataColumn(label: Text(quantity)),
    DataColumn(label: Text(section)),
    DataColumn(label: Text(number)),
  ];
  Stock? _inputStock;
  List<DataRow> _inputStockRow = [];
  late StockDataSource _dataSource;
  Key _dataTableKey = UniqueKey();
  final Set<Stock> _stocks = {};
  final Set<Stock> _selectedStocks = {};

  void addStock() {
    if (_inputStock != null && _inputStock?.part != null && _inputStock?.quantity != null && _inputStock?.location != null) {
      _stocks.add(_inputStock!);
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
    if (_stocks.isEmpty) return null;

    List<Stock> stockList = _stocks.toList();

    List<Stock> registeredStocks = await StockRepository()
        .addStocks(stockList);

    return registeredStocks;
  }

  Future<void> createStockHistories(List<Stock> registeredStocks) async {
    final stockHistoryRepo = StockHistoryRepository();

    final currentUser = Provider.of<PersonProvider>(context, listen: false).currentUser;
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final category = categoryProvider.getCategory(StockHistoryCategoryType.register);
    final memo = _memoFieldController.text.trim();
    
    final stockHistories = registeredStocks.map((stock) {
      final stockLocation = '${stock.location?.section.section ?? ""} ${stock.location?.number ?? ""}';

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

    stockHistoryRepo.addHistories(stockHistories);
  }

  void updateStockRows() {
    _inputStockRow = [
      DataRow(cells: [
        DataCell(Text(_inputStock?.part?.type.type ?? "")),
        DataCell(Text(_inputStock?.part?.specification ?? "")),
        DataCell(Text(_inputStock?.part?.maker.maker ?? "")),
        DataCell(Text(_inputStock?.part?.unit.unit ?? "")),
        DataCell(Text(_inputStock?.quantity?.toString() ?? "")),
        DataCell(Text(_inputStock?.location?.section.section ?? "")),
        DataCell(Text(_inputStock?.location?.number.toString() ?? "")),
      ])
    ];
  }

  @override
  void initState() {
    super.initState();

    final personProvider = Provider.of<PersonProvider>(context, listen: false);
    personProvider.reloadPersons();
  }


  @override
  Widget build(BuildContext context) {
    final personProvider = Provider.of<PersonProvider>(context, listen: false);

    _dataSource = StockDataSource(
      stocks: _stocks.toList(),
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
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScreenTitle(menu: InventoryMenu.stockRegister),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 5.0,
                ),
                child: Row(
                  spacing: 20,
                  children: [
                    ElevatedButton(
                      style: AppButtonStyle.newPage,
                      onPressed: () async {
                        final newPart = await showDialog<Part>(
                          context: context,
                          builder: (context) => PartSelectDialog(),
                        );

                        if (newPart != null) {
                          _inputStock = Stock(
                            part: newPart,
                            quantity: _inputStock?.quantity,
                            location: _inputStock?.location,
                            version: _inputStock?.version,
                          );
                          updateStockRows();
                          setState(() {});
                        }
                      },
                      child: Text('부품선택', style: TextStyle(fontSize: 18)),
                    ),
                    SizedBox(
                      width: 150,
                      child: TextField(
                        controller: _quantityController,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: '수량',
                          hintText: '입력 후 엔터',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (number) {
                          _inputStock = Stock(
                            part: _inputStock?.part,
                            quantity: int.parse(number),
                            location: _inputStock?.location,
                            version: _inputStock?.version,
                          );
                          updateStockRows();
                          _quantityController.clear();
                          setState(() {});
                        },
                      )
                    ),
                    ElevatedButton(
                      style: AppButtonStyle.newPage,
                      onPressed: () async {
                        final newLocation = await showDialog<Location>(
                          context: context,
                          builder: (context) => LocationSelectDialog(),
                        );

                        if (newLocation != null) {
                          _inputStock = Stock(
                            part: _inputStock?.part,
                            quantity: _inputStock?.quantity,
                            location: newLocation,
                            version: _inputStock?.version,
                          );
                          updateStockRows();
                          setState(() {});
                        }
                        
                      },
                      child: Text('위치선택', style: TextStyle(fontSize: 18)),
                    ),
                  ],
                ),
              ),
              Row(
                spacing: 20,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: _columns,
                        rows: _inputStockRow,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    child: Icon(Icons.add, size: 30),
                    onPressed: () {
                      addStock();
                      setState(() {});
                    },
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
                          child: SizedBox(
                            width: 800,
                            child: PaginatedDataTable(
                              key: _dataTableKey,
                              columns: _columns,
                              source: _dataSource,
                              rowsPerPage: 10,
                              showCheckboxColumn: true,
                            ),
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
                              if (_stocks.isEmpty) return;

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
                                    _stocks.clear();
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
                              setState(() {
                                _stocks.removeAll(_selectedStocks);
                                _selectedStocks.clear();
                              });
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
