import 'package:flutter/material.dart';
import 'package:inventory_management/datatable_source/stock_data.dart';
import 'package:inventory_management/main.dart';
import 'package:inventory_management/models/location_section.dart';
import 'package:inventory_management/models/part_maker.dart';
import 'package:inventory_management/models/part_type.dart';
import 'package:inventory_management/models/stock.dart';
import 'package:inventory_management/providers/maker_provider.dart';
import 'package:inventory_management/providers/section_provider.dart';
import 'package:inventory_management/providers/type_provider.dart';
import 'package:inventory_management/repository/stock_repository.dart';
import 'package:inventory_management/widgets/buttons.dart';
import 'package:inventory_management/widgets/title.dart';
import 'package:provider/provider.dart';

class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({super.key});

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  late PartType selectedType;
  late PartMaker selectedMaker;
  late LocationSection selectedSection;

  final TextEditingController specFieldController = TextEditingController();
  final TextEditingController numberFieldController = TextEditingController();
  final FocusNode _specFieldFocusNode = FocusNode();
  final FocusNode _numberFieldFocusNode = FocusNode();

  final List<DataColumn> columns = [
    DataColumn(label: Text('품명')),
    DataColumn(label: Text('규격')),
    DataColumn(label: Text('제조사')),
    DataColumn(label: Text('단위')),
    DataColumn(label: Text('수량')),
    DataColumn(label: Text('구역')),
    DataColumn(label: Text('번호')),
  ];
  late StockDataSource _dataSource;
  Key dataTableKey = UniqueKey();
  List<Stock> inquiredStocks = [];
  Stock? selectedStock;

  @override
  void initState() {
    super.initState();
    final typeProvider = Provider.of<TypeProvider>(context, listen: false);
    selectedType = typeProvider.allType;
    typeProvider.reloadTypes();

    final makerProvider = Provider.of<MakerProvider>(context, listen: false);
    selectedMaker = makerProvider.allMaker;
    makerProvider.reloadMakers();

    final sectionProvider = Provider.of<SectionProvider>(context, listen: false);
    selectedSection = sectionProvider.allSection;
    sectionProvider.reloadSections();
  }

  void getStocks() async {
    final typeProvider = Provider.of<TypeProvider>(context, listen: false);
    final makerProvider = Provider.of<MakerProvider>(context, listen: false);
    final sectionProvider = Provider.of<SectionProvider>(context, listen: false);
    StockRepository stockRepo = StockRepository();

    final isAllType = selectedType == typeProvider.allType;
    final isAllMaker = selectedMaker == makerProvider.allMaker;
    final isAllSection = selectedSection == sectionProvider.allSection;
    final specText = specFieldController.text.trim();
    final numberText = numberFieldController.text.trim();
    
    inquiredStocks = await switch ((isAllType, isAllMaker, specText.isEmpty, isAllSection, numberText.isEmpty)) {
      (true, true, true, true, true) => stockRepo.getAllStocks(),
      (false, true, true, true, true) => stockRepo.getStocksByType(selectedType.id!),
      (true, false, true, true, true) => stockRepo.getStocksByMaker(selectedMaker.id!),
      (true, true, true, false, true) => stockRepo.getStocksBySection(selectedSection.id!),
      _ => stockRepo.getStocksByFilter(
              isAllType ? null : selectedType.id!,
              isAllMaker ? null : selectedMaker.id!,
              specText.isEmpty ? null : specText,
              isAllSection ? null : selectedSection.id!,
              numberText.isEmpty ? null : numberText,
            ),
    };

    selectedStock = null;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final typeProvider = Provider.of<TypeProvider>(context);
    final makerProvider = Provider.of<MakerProvider>(context);
    final sectionProvider = Provider.of<SectionProvider>(context);

    _dataSource = StockDataSource(
      stocks: inquiredStocks,
      selectedStocks: (selectedStock == null) ? {} : {selectedStock!},
      onSelectChanged: (stock, selected) {
        setState(() {
          if (selected) {
            selectedStock = stock;
          } else {
            selectedStock = null;
          }
        });
      },
    );

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenTitle(menu: InventoryMenu.stockManagement),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 20.0,
              ),
              child: Column(
                spacing: 10,
                children: [
                  Row(
                    spacing: 20,
                    children: [
                      DropdownMenu<PartType>(
                        label: Text("품명"),
                        enableFilter: true,
                        menuHeight: 400,
                        width: 150,
                        onSelected: (type) {
                          selectedType = type ?? typeProvider.allType;
                          getStocks();
                          dataTableKey = UniqueKey();
                        },
                        dropdownMenuEntries:
                            typeProvider.typesDropdownWithAll,
                      ),
                      DropdownMenu<PartMaker>(
                        label: Text("제조사"),
                        enableFilter: true,
                        menuHeight: 400,
                        width: 150,
                        onSelected: (maker) {
                          selectedMaker = maker ?? makerProvider.allMaker;
                          getStocks();
                          dataTableKey = UniqueKey();
                        },
                        dropdownMenuEntries:
                            makerProvider.makersDropdownWithAll,
                      ),
                      SizedBox(
                        width: 180,
                        child: TextField(
                          controller: specFieldController,
                          focusNode: _specFieldFocusNode,
                          decoration: InputDecoration(
                            labelText: "규격",
                            hintText: "입력 후 엔터",
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (sectionName) {
                            dataTableKey = UniqueKey();
                            getStocks();
                            FocusScope.of(context).requestFocus(_specFieldFocusNode);
                          },
                        ),
                      ),
                       DropdownMenu<LocationSection>(
                        label: Text("구역"),
                        enableFilter: true,
                        menuHeight: 400,
                        width: 150,
                        onSelected: (section) {
                          selectedSection = section ?? sectionProvider.allSection;
                          dataTableKey = UniqueKey();
                          getStocks();
                        },
                        dropdownMenuEntries:
                            sectionProvider.sectionsDropdownWithAll,
                      ),
                      SizedBox(
                        width: 130,
                        child: TextField(
                          controller: numberFieldController,
                          focusNode: _numberFieldFocusNode,
                          decoration: InputDecoration(
                            labelText: "번호",
                            hintText: "입력 후 엔터",
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (sectionName) {
                            dataTableKey = UniqueKey();
                            getStocks();
                            FocusScope.of(context).requestFocus(_numberFieldFocusNode);
                          },
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Row(
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
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20,),
                          child: Column(
                            spacing: 20,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ReleaseButton(
                                onPressed: () async {
                                },
                              ),
                              QuantityChangeButton(onPressed: () {
                          
                              }),
                              LocationChangeButton(onPressed: () {}),
                            ],
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
      ),
    );
  }
}
