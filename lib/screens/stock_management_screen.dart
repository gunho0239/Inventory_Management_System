import 'package:flutter/material.dart';
import 'package:inventory_management/datatable_source/stock_data.dart';
import 'package:inventory_management/enums/inventory_menu.dart';
import 'package:inventory_management/enums/label_type.dart';
import 'package:inventory_management/constants/columns.dart';
import 'package:inventory_management/models/location_section.dart';
import 'package:inventory_management/models/part_maker.dart';
import 'package:inventory_management/models/part_type.dart';
import 'package:inventory_management/models/person.dart';
import 'package:inventory_management/models/stock.dart';
import 'package:inventory_management/providers/data_table_options_provider.dart';
import 'package:inventory_management/providers/maker_provider.dart';
import 'package:inventory_management/providers/person_provider.dart';
import 'package:inventory_management/providers/section_provider.dart';
import 'package:inventory_management/providers/type_provider.dart';
import 'package:inventory_management/repository/stock_repository.dart';
import 'package:inventory_management/screens/stock_location_change_dialog.dart';
import 'package:inventory_management/screens/stock_quantity_change_dialog.dart';
import 'package:inventory_management/screens/stock_release_dialog.dart';
import 'package:inventory_management/screens/stock_release_print_dialog.dart';
import 'package:inventory_management/screens/user_management_dialog.dart';
import 'package:inventory_management/style/style.dart';
import 'package:inventory_management/widgets/buttons.dart';
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
    DataColumn(label: Text(type)),
    DataColumn(label: Text(specification)),
    DataColumn(label: Text(maker)),
    DataColumn(label: Text(quantity)),
    DataColumn(label: Text(location)),
  ];
  late StockDataSource _dataSource;
  Key dataTableKey = UniqueKey();
  List<Stock> _inquiredStocks = [];
  List<Stock> selectedStocks = [];
  bool _isLoading = false;

  final StockRepository _stockRepo = StockRepository();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    specFieldController.dispose();
    numberFieldController.dispose();
    _specFieldFocusNode.dispose();
    _numberFieldFocusNode.dispose();
    super.dispose();
  }

  void _initializeData() {
    final typeProvider = Provider.of<TypeProvider>(context, listen: false);
    final makerProvider = Provider.of<MakerProvider>(context, listen: false);
    final sectionProvider = Provider.of<SectionProvider>(context, listen: false);

    selectedType = typeProvider.allType;
    selectedMaker = makerProvider.allMaker;
    selectedSection = sectionProvider.allSection;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      typeProvider.reloadTypes();
      makerProvider.reloadMakers();
      sectionProvider.reloadSections();
      Provider.of<PersonProvider>(context, listen: false).reloadPersons();
      _getStocks();
    });

    _dataSource = StockDataSource(
      stocks: _inquiredStocks,
      selectedStocks: selectedStocks,
      onSelectChanged: (stock, selected) {
        if (selected) {
          selectedStocks.add(stock);
        } else {
          selectedStocks.remove(stock);
        }
      },
    );
  }

  void _getStocks() async {
    setState(() => _isLoading = true);
    
    final typeProvider = Provider.of<TypeProvider>(context, listen: false);
    final makerProvider = Provider.of<MakerProvider>(context, listen: false);
    final sectionProvider = Provider.of<SectionProvider>(context, listen: false);

    final isAllType = selectedType == typeProvider.allType;
    final isAllMaker = selectedMaker == makerProvider.allMaker;
    final isAllSection = selectedSection == sectionProvider.allSection;
    final specText = specFieldController.text.trim();
    final numberText = numberFieldController.text.trim();
    
    final result = await switch ((isAllType, isAllMaker, specText.isEmpty, isAllSection, numberText.isEmpty)) {
      (true, true, true, true, true) => _stockRepo.getAllStocks(),
      (false, true, true, true, true) => _stockRepo.getStocksByType(selectedType.id!),
      (true, false, true, true, true) => _stockRepo.getStocksByMaker(selectedMaker.id!),
      (true, true, true, false, true) => _stockRepo.getStocksBySection(selectedSection.id!),
      _ => _stockRepo.getStocksByFilter(
              isAllType ? null : selectedType.id!,
              isAllMaker ? null : selectedMaker.id!,
              specText.isEmpty ? null : specText,
              isAllSection ? null : selectedSection.id!,
              numberText.isEmpty ? null : numberText,
            ),
    };

    if (!mounted) return;

    setState(() {
      _inquiredStocks = result;
      selectedStocks.clear();
      _dataSource.updateData(_inquiredStocks);
      dataTableKey = UniqueKey(); // 페이지네이션 초기화
      _isLoading = false;
    });
  }

  Future<void> _showEachDialog(DialogType dialogType) async {
    final personProvider = Provider.of<PersonProvider>(context, listen: false);

    if (selectedStocks.isEmpty) {
      _showSnackBar('재고를 선택해주세요.');
      return;
    }
    
    if (personProvider.currentUser == null) {
      _showSnackBar('시스템 사용자를 선택해주세요.');
      return;
    }
    
    Widget dialog = switch (dialogType) {
      DialogType.release => ReleaseDialog(selectedStocks: selectedStocks.toList()),
      DialogType.quantityChange => QuantityChangeDialog(selectedStocks: selectedStocks.toList()),
      DialogType.locationChange => LocationChangeDialog(selectedStocks: selectedStocks.toList()),
    };

    final refresh = await showDialog<bool>(
      context: context,
      builder: (context) {
        return dialog;
      },
    );

    if (!mounted) return;
    
    if (refresh == true) {
      _getStocks();
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _clearFilters() {
    final typeProvider = Provider.of<TypeProvider>(context, listen: false);
    final makerProvider = Provider.of<MakerProvider>(context, listen: false);
    final sectionProvider = Provider.of<SectionProvider>(context, listen: false);

    if (selectedType == typeProvider.allType &&
        selectedMaker == makerProvider.allMaker &&
        selectedSection == sectionProvider.allSection &&
        specFieldController.text.isEmpty &&
        numberFieldController.text.isEmpty) {
      return;
    }

    setState(() {
      selectedType = typeProvider.allType;
      selectedMaker = makerProvider.allMaker;
      selectedSection = sectionProvider.allSection;
      specFieldController.clear();
      numberFieldController.clear();
    });

    _getStocks();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ScreenTitle(menu: InventoryMenu.stockManagement),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                _buildFilterBar(),
                Expanded(
                  child: SizedBox(
                    width: 1500,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(child: _buildDataTable()),
                        _buildActionPanel(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    final typeProvider = Provider.of<TypeProvider>(context);
    final makerProvider = Provider.of<MakerProvider>(context);
    final sectionProvider = Provider.of<SectionProvider>(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.only(top: 5.0),
        child: Row(
          spacing: 10,
          children: [
            DropdownMenu<PartType>(
              label: const IconLabel(labelType: LabelType.type),
              enableFilter: true,
              menuHeight: 400,
              width: 150,
              initialSelection: selectedType,
              onSelected: (type) {
                if (type != null) {
                  selectedType = type;
                  _getStocks();
                }
              },
              dropdownMenuEntries: typeProvider.typesDropdownWithAll,
            ),
            DropdownMenu<PartMaker>(
              label: const IconLabel(labelType: LabelType.maker),
              enableFilter: true,
              menuHeight: 400,
              width: 160,
              initialSelection: selectedMaker,
              onSelected: (maker) {
                if (maker != null) {
                  selectedMaker = maker;
                  _getStocks();
                }
              },
              dropdownMenuEntries: makerProvider.makersDropdownWithAll,
            ),
            SizedBox(
              width: 180,
              child: TextField(
                controller: specFieldController,
                focusNode: _specFieldFocusNode,
                decoration: InputDecoration(
                  label: const IconLabel(labelType: LabelType.specification),
                  hintText: "입력 후 엔터",
                ),
                onSubmitted: (_) {
                  _getStocks();
                  FocusScope.of(context).requestFocus(_specFieldFocusNode);
                },
              ),
            ),
            DropdownMenu<LocationSection>(
              label: const IconLabel(labelType: LabelType.section),
              enableFilter: true,
              menuHeight: 400,
              width: 150,
              initialSelection: selectedSection,
              onSelected: (section) {
                if (section != null) {
                  selectedSection = section;
                  _getStocks();
                }
              },
              dropdownMenuEntries: sectionProvider.sectionsDropdownWithAll,
            ),
            SizedBox(
              width: 130,
              child: TextField(
                controller: numberFieldController,
                focusNode: _numberFieldFocusNode,
                decoration: const InputDecoration(
                  label: IconLabel(labelType: LabelType.number),
                  hintText: "입력 후 엔터",
                ),
                onSubmitted: (_) {
                  _getStocks();
                  FocusScope.of(context).requestFocus(_numberFieldFocusNode);
                },
              ),
            ),
            ElevatedButton(
              style: AppButtonStyle.newPage,
              onPressed: _clearFilters,
              child: const Text('필터초기화', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    final tableOptionsProvider = context.watch<DataTableOptionsProvider>();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: PaginatedDataTable(
        key: dataTableKey,
        columns: columns,
        source: _dataSource,
        rowsPerPage: tableOptionsProvider.rowsPerPage,
        availableRowsPerPage: tableOptionsProvider.availableRowsPerPage,
        showCheckboxColumn: true,
        showFirstLastButtons: true,
        showEmptyRows: false,
        onRowsPerPageChanged: (value) {
          if (value != null) {
            tableOptionsProvider.updateRowsPerPage(value);
          }
        },
      ),
    );
  }

  Widget _buildActionPanel() {
    final personProvider = Provider.of<PersonProvider>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20),
      child: Column(
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
          ReleaseButton(onPressed: () => _showEachDialog(DialogType.release)),
          QuantityChangeButton(onPressed: () => _showEachDialog(DialogType.quantityChange)),
          LocationChangeButton(onPressed: () => _showEachDialog(DialogType.locationChange)),
          const SizedBox(height: 20),
          PrintReleasedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const StockReleasePrintDialog(),
              );
            },
          ),
        ],
      ),
    );
  }
}
