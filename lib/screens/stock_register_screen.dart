import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_management/constants/columns.dart';
import 'package:inventory_management/datatable_source/stock_data.dart';
import 'package:inventory_management/main.dart';
import 'package:inventory_management/models/part_maker.dart';
import 'package:inventory_management/models/part_type.dart';
import 'package:inventory_management/models/part_unit.dart';
import 'package:inventory_management/models/person.dart';
import 'package:inventory_management/models/stock.dart';
import 'package:inventory_management/models/stock_history.dart';
import 'package:inventory_management/models/stock_history_category.dart';
import 'package:inventory_management/providers/category_provider.dart';
import 'package:inventory_management/providers/maker_provider.dart';
import 'package:inventory_management/providers/person_provider.dart';
import 'package:inventory_management/providers/type_provider.dart';
import 'package:inventory_management/providers/unit_provider.dart';
import 'package:inventory_management/repository/stock_history_repository.dart';
import 'package:inventory_management/repository/stock_repository.dart';
import 'package:inventory_management/screens/location_select_dialog.dart';
import 'package:inventory_management/screens/part_select_dialog.dart';
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

  final TextEditingController quantityController = TextEditingController();
  PartType? selectedType;
  PartMaker? selectedMaker;
  PartUnit? selectedUnit;

  final List<DataColumn> columns = [
    DataColumn(label: Text(type)),
    DataColumn(label: Text(specification)),
    DataColumn(label: Text(maker)),
    DataColumn(label: Text(unit)),
    DataColumn(label: Text(quantity)),
    DataColumn(label: Text(location)),
    DataColumn(label: Text(number)),
  ];
  Stock? inputStock;
  List<DataRow> inputStockRow = [];
  late StockDataSource _dataSource;
  Key dataTableKey = UniqueKey();
  Set<Stock> stocks = {};
  Set<Stock> selectedStocks = {};

  void addStock() {
    if (inputStock != null && inputStock?.part != null && inputStock?.quantity != null && inputStock?.location != null) {
      stocks.add(inputStock!);
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
    if (stocks.isEmpty) return null;

    List<Stock> stockList = stocks.toList();

    List<Stock> registeredStocks = await StockRepository()
        .addStocks(stockList);

    return registeredStocks;
  }

  Future<void> createStockHistories(List<Stock> registeredStocks) async {
    final stockHistoryRepo = StockHistoryRepository();

    final currentUser = Provider.of<PersonProvider>(context, listen: false).currentUser;
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final category = categoryProvider.getCategory(StockHistoryCategoryType.register);
    
    final stockHistories = registeredStocks.map((stock) {
      final stockLocation = '${stock.location?.section.section ?? ""} ${stock.location?.number ?? ""}';

      return StockHistory(
        category: category,
        note: "",
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
    inputStockRow = [
      DataRow(cells: [
        DataCell(Text(inputStock?.part?.type.type ?? "")),
        DataCell(Text(inputStock?.part?.specification ?? "")),
        DataCell(Text(inputStock?.part?.maker.maker ?? "")),
        DataCell(Text(inputStock?.part?.unit.unit ?? "")),
        DataCell(Text(inputStock?.quantity?.toString() ?? "")),
        DataCell(Text(inputStock?.location?.section.section ?? "")),
        DataCell(Text(inputStock?.location?.number.toString() ?? "")),
      ])
    ];
  }

  @override
  void initState() {
    super.initState();

    final typeProvider = Provider.of<TypeProvider>(context, listen: false);
    final makerProvider = Provider.of<MakerProvider>(context, listen: false);
    final unitProvider = Provider.of<UnitProvider>(context, listen: false);
    final personProvider = Provider.of<PersonProvider>(context, listen: false);

    selectedType = typeProvider.allType;
    selectedMaker = makerProvider.allMaker;
    selectedUnit = unitProvider.allUnit;

    typeProvider.reloadTypes();
    makerProvider.reloadMakers();
    unitProvider.reloadUnits();
    personProvider.reloadPersons();
  }


  @override
  Widget build(BuildContext context) {
    final personProvider = Provider.of<PersonProvider>(context, listen: false);

    _dataSource = StockDataSource(
      stocks: stocks.toList(),
      selectedStocks: selectedStocks,
      onSelectChanged: (stock, selected) {
        setState(() {
          if (selected) {
            selectedStocks.add(stock);
          } else {
            selectedStocks.remove(stock);
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
                        final currentStock = await showDialog<Stock>(
                          context: context,
                          builder: (context) => PartSelectDialog(stock: inputStock),
                        );

                        if (currentStock != null) {
                          inputStock = currentStock;
                          updateStockRows();
                          setState(() {});
                        }
                        
                      },
                      child: Text('부품선택', style: TextStyle(fontSize: 18)),
                    ),
                    SizedBox(
                      width: 150,
                      child: TextField(
                        controller: quantityController,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: '수량',
                          hintText: '입력 후 엔터',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (number) {
                          inputStock = Stock(
                            part: inputStock?.part,
                            quantity: int.parse(number),
                            location: inputStock?.location,
                          );
                          updateStockRows();
                          quantityController.clear();
                          setState(() {});
                        },
                      )
                    ),
                    ElevatedButton(
                      style: AppButtonStyle.newPage,
                      onPressed: () async {
                        final currentStock = await showDialog<Stock>(
                          context: context,
                          builder: (context) => LocationSelectDialog(stock: inputStock),
                        );

                        if (currentStock != null) {
                          inputStock = currentStock;
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
                        columns: columns,
                        rows: inputStockRow,
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
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: SizedBox(
                              width: 800,
                              child: PaginatedDataTable(
                                key: dataTableKey,
                                columns: columns,
                                source: _dataSource,
                                rowsPerPage: 10,
                                showCheckboxColumn: true,
                              ),
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
                                    personProvider.currentUser = person;
                                  },
                                  dropdownMenuEntries:
                                      personProvider.personsDropdown,
                                ),
                                EditButton(
                                  onPressed: () async {
                                  },
                                ),
                              ],
                            ),
                          SaveAllButton(
                            onPressed: () async {
                              if (stocks.isEmpty) {
                                showDialog(
                                  context: context,
                                  builder: (context) =>
                                      ErrorDialog(message: '등록할 재고가 없습니다.'),
                                );
                                return;
                              }

                              if (personProvider.currentUser == null) {
                                showDialog(
                                  context: context,
                                  builder: (context) =>
                                      ErrorDialog(message: '시스템 사용자를 선택해주세요.'),
                                );
                                return;
                              }

                              final confirmed = await showDialog(
                                context: context,
                                builder: (context) =>
                                    ConfirmDialog(message: "전체등록 하시겠습니까?"),
                              );

                              if (confirmed) {
                                final registeredStocks = await registerAllStocks();

                                if (!context.mounted) return;

                                if (registeredStocks != null && registeredStocks.isNotEmpty) {

                                  createStockHistories(registeredStocks);

                                  setState(() {
                                    stocks.clear();
                                    dataTableKey = UniqueKey();
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
                            if (selectedStocks.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('삭제할 재고를 선택해주세요.')),
                                );
                                return;
                              }
                              setState(() {
                                stocks.removeAll(selectedStocks);
                                selectedStocks.clear();
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
