import 'package:flutter/material.dart';
import 'package:inventory_management/datatable_source/stock_data.dart';
import 'package:inventory_management/enums/inventory_menu.dart';
import 'package:inventory_management/enums/label_type.dart';
import 'package:inventory_management/models/location_section.dart';
import 'package:inventory_management/models/part_maker.dart';
import 'package:inventory_management/models/part_type.dart';
import 'package:inventory_management/models/person.dart';
import 'package:inventory_management/models/stock.dart';
import 'package:inventory_management/providers/maker_provider.dart';
import 'package:inventory_management/providers/person_provider.dart';
import 'package:inventory_management/providers/section_provider.dart';
import 'package:inventory_management/providers/type_provider.dart';
import 'package:inventory_management/repository/stock_repository.dart';
import 'package:inventory_management/screens/stock_location_change_dialog.dart';
import 'package:inventory_management/screens/stock_quantity_change_dialog.dart';
import 'package:inventory_management/screens/stock_release_dialog.dart';
import 'package:inventory_management/screens/user_management_dialog.dart';
import 'package:inventory_management/widgets/buttons.dart';
import 'package:inventory_management/widgets/dialogs.dart';
import 'package:inventory_management/widgets/icon_label.dart';
import 'package:inventory_management/widgets/title.dart';
import 'package:provider/provider.dart';

enum DialogType { release, quantityChange, locationChange }

class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({super.key});

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  late PartType selectedType;
  late PartMaker selectedMaker;
  late LocationSection selectedSection;
  late Person? selectedPerson;

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

    Provider.of<PersonProvider>(context, listen: false).reloadPersons();
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

  showEachDialog(BuildContext context, DialogType dialogType) async {
    final personProvider = Provider.of<PersonProvider>(context, listen: false);

    if (selectedStock == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('재고를 선택해주세요.')),
      );
    }
    else if (personProvider.currentUser == null) {
      showDialog(
        context: context,
        builder: (context) =>
            ErrorDialog(message: '시스템 사용자를 선택해주세요.'),
      );
    }
    else {
      Widget dialog = switch (dialogType) {
        DialogType.release => ReleaseDialog(selectedStock: selectedStock!),
        DialogType.quantityChange => QuantityChangeDialog(selectedStock: selectedStock!),
        DialogType.locationChange => LocationChangeDialog(selectedStock: selectedStock!),
      };

      final refresh = await showDialog<bool>(
        context: context,
        builder: (context) {
          return dialog;
        },
      );

      if (refresh == true) {
        dataTableKey = UniqueKey();
        getStocks();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeProvider = Provider.of<TypeProvider>(context);
    final makerProvider = Provider.of<MakerProvider>(context);
    final sectionProvider = Provider.of<SectionProvider>(context);
    final personProvider = Provider.of<PersonProvider>(context);

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

    return Column(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: Row(
                      spacing: 20,
                      children: [
                        DropdownMenu<PartType>(
                          label: IconLabel(labelType: LabelType.type),
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
                          label: IconLabel(labelType: LabelType.maker),
                          enableFilter: true,
                          menuHeight: 400,
                          width: 160,
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
                              label: IconLabel(labelType: LabelType.specification),
                              hintText: "입력 후 엔터",
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (spec) {
                              dataTableKey = UniqueKey();
                              getStocks();
                              FocusScope.of(context).requestFocus(_specFieldFocusNode);
                            },
                          ),
                        ),
                        DropdownMenu<LocationSection>(
                          label: IconLabel(labelType: LabelType.section),
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
                              label: IconLabel(labelType: LabelType.number),
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
                  ),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: SingleChildScrollView(
                          child: SizedBox(
                            width: 900,
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
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20,),
                        child: Column(
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
                                    showDialog(
                                      context: context,
                                      builder: (context) => UserManagementDialog(),
                                    );
                                  },
                                ),
                              ],
                            ),
                            ReleaseButton(
                              onPressed: () async {
                                showEachDialog(
                                  context, 
                                  DialogType.release,
                                );
                              },
                            ),
                            QuantityChangeButton(
                              onPressed: () {
                                showEachDialog(
                                  context, 
                                  DialogType.quantityChange,
                                );
                              },
                            ),
                            LocationChangeButton(
                              onPressed: () {
                                showEachDialog(
                                  context, 
                                  DialogType.locationChange,
                                );
                              },
                            ),
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
    );
  }
}
