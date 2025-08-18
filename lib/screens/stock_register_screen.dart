import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_management/datatable_source/stock_data.dart';
import 'package:inventory_management/main.dart';
import 'package:inventory_management/models/part_maker.dart';
import 'package:inventory_management/models/part_type.dart';
import 'package:inventory_management/models/part_unit.dart';
import 'package:inventory_management/models/stock.dart';
import 'package:inventory_management/providers/maker_provider.dart';
import 'package:inventory_management/providers/type_provider.dart';
import 'package:inventory_management/providers/unit_provider.dart';
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
    DataColumn(label: Text('품명')),
    DataColumn(label: Text('규격')),
    DataColumn(label: Text('제조사')),
    DataColumn(label: Text('단위')),
    DataColumn(label: Text('수량')),
    DataColumn(label: Text('구역')),
    DataColumn(label: Text('번호')),
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
      // stock = null;
      // inputStockRow.clear();
    } 
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('부품, 수량, 위치를 선택해주세요.'),
        ),
      );
    }
  }

  Future<int> registerAllStocks() async {
    if (stocks.isEmpty) return 0;

    List<Stock> stockList = stocks.toList();

    List<Stock> registeredStocks = await StockRepository()
        .addStocks(stockList);

    return registeredStocks.length;
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

    selectedType = typeProvider.allType;
    selectedMaker = makerProvider.allMaker;
    selectedUnit = unitProvider.allUnit;

    typeProvider.reloadTypes();
    makerProvider.reloadMakers();
    unitProvider.reloadUnits();
  }


  @override
  Widget build(BuildContext context) {

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

    return Scaffold(
      body: Column(
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

                                int count = await registerAllStocks();

                                if (!mounted) return;

                                if (count > 0) {
                                  setState(() {
                                    stocks.clear();
                                    dataTableKey = UniqueKey();
                                    refresh = true;
                                  });
                                  showDialog(
                                    context: context,
                                    builder: (context) => ResultDialog(
                                      message: '$count개의 재고가 등록되었습니다.',
                                    ),
                                  );
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (context) =>
                                        ErrorDialog(message: '이미 등록된 재고입니다.'),
                                  );
                                  return;
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
      ),
    );
  }
}
