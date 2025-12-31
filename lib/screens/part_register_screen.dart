import 'package:flutter/material.dart';
import 'package:inventory_management/datatable_source/part_data.dart';
import 'package:inventory_management/enums/inventory_menu.dart';
import 'package:inventory_management/enums/label_type.dart';
import 'package:inventory_management/models/part.dart';
import 'package:inventory_management/models/part_maker.dart';
import 'package:inventory_management/models/part_type.dart';
import 'package:inventory_management/models/part_unit.dart';
import 'package:inventory_management/providers/data_table_options_provider.dart';
import 'package:inventory_management/providers/maker_provider.dart';
import 'package:inventory_management/providers/type_provider.dart';
import 'package:inventory_management/providers/unit_provider.dart';
import 'package:inventory_management/repository/part_repository.dart';
import 'package:inventory_management/screens/maker_management_screen.dart';
import 'package:inventory_management/screens/type_management_screen.dart';
import 'package:inventory_management/screens/unit_management_screen.dart';
import 'package:inventory_management/style/style.dart';
import 'package:inventory_management/widgets/buttons.dart';
import 'package:inventory_management/widgets/dialogs.dart';
import 'package:inventory_management/widgets/icon_label.dart';
import 'package:inventory_management/widgets/title.dart';
import 'package:provider/provider.dart';

class PartRegisterScreen extends StatefulWidget {
  const PartRegisterScreen({super.key});

  @override
  State<PartRegisterScreen> createState() => _PartRegisterScreenState();
}

class _PartRegisterScreenState extends State<PartRegisterScreen> {
  bool refresh = false;

  final TextEditingController specFieldController = TextEditingController();
  final FocusNode _specFieldFocusNode = FocusNode();
  PartType? selectedType;
  PartMaker? selectedMaker;
  PartUnit? selectedUnit;

  final List<DataColumn> columns = [
    DataColumn(label: Text('품명')),
    DataColumn(label: Text('규격')),
    DataColumn(label: Text('제조사')),
    DataColumn(label: Text('단위')),
  ];
  late PartDataSource _dataSource;
  Key dataTableKey = UniqueKey();
  Set<Part> parts = {};
  Set<Part> selectedParts = {};

  void addPart() {
    String spec = specFieldController.text.trim();

    if (spec.isNotEmpty &&
        selectedType != null &&
        selectedMaker != null &&
        selectedUnit != null) 
    {
      Part newPart = Part(
        type: selectedType!,
        maker: selectedMaker!,
        unit: selectedUnit!,
        specification: spec,
      );
      setState(() {
        parts.add(newPart);
      });
      specFieldController.clear();
      FocusScope.of(context).requestFocus(_specFieldFocusNode);
    } 
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('모든 항목을 입력해주세요.'),
        ),
      );
    }
  }

  Future<int> registerAllParts() async {
    if (parts.isEmpty) return 0;

    List<Part> partList = parts.toList();

    List<Part> registeredParts = await PartRepository()
        .addParts(partList);

    return registeredParts.length;
  }


  @override
  void initState() {
    super.initState();

    final typeProvider = Provider.of<TypeProvider>(context, listen: false);
    final makerProvider = Provider.of<MakerProvider>(context, listen: false);
    final unitProvider = Provider.of<UnitProvider>(context, listen: false);

    typeProvider.reloadTypes();
    makerProvider.reloadMakers();
    unitProvider.reloadUnits();
  }


  @override
  Widget build(BuildContext context) {
    final typeProvider = Provider.of<TypeProvider>(context);
    final makerProvider = Provider.of<MakerProvider>(context);
    final unitProvider = Provider.of<UnitProvider>(context);
    final tableOptionsProvider = context.watch<DataTableOptionsProvider>();

    _dataSource = PartDataSource(
      parts: parts.toList(),
      selectedParts: selectedParts,
      onSelectChanged: (part, selected) {
        setState(() {
          if (selected) {
            selectedParts.add(part);
          } else {
            selectedParts.remove(part);
          }
        });
      },
    );

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenTitle(menu: InventoryMenu.partRegister),
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
                      GoBackButton(refresh: refresh),
                      ElevatedButton(
                        style: AppButtonStyle.newPage,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TypeManagementScreen(),
                            ),
                          );
                        },
                        child: Text('품명관리', style: TextStyle(fontSize: 18)),
                      ),
                      ElevatedButton(
                        style: AppButtonStyle.newPage,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MakerManagementScreen(),
                            ),
                          );
                        },
                        child: Text('제조사관리', style: TextStyle(fontSize: 18)),
                      ),
                      ElevatedButton(
                        style: AppButtonStyle.newPage,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UnitManagementScreen(),
                            ),
                          );
                        },
                        child: Text('단위관리', style: TextStyle(fontSize: 18)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30.0,
                      vertical: 20.0,
                    ),
                    child: SizedBox(
                      width: 1500,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 10, top: 10),
                            child: Column(
                              spacing: 20,
                              children: [
                                DropdownMenu<PartType>(
                                  label: IconLabel(labelType: LabelType.type),
                                  enableFilter: true,
                                  menuHeight: 400,
                                  width: 180,
                                  initialSelection: selectedType,
                                  onSelected: (type) {
                                    if (type != null) {
                                      selectedType = type;
                                    }
                                  },
                                  dropdownMenuEntries: typeProvider.typesDropdown,
                                ),
                                DropdownMenu<PartMaker>(
                                  label: IconLabel(labelType: LabelType.maker),
                                  enableFilter: true,
                                  menuHeight: 400,
                                  width: 180,
                                  initialSelection: selectedMaker,
                                  onSelected: (maker) {
                                    if (maker != null) {
                                      selectedMaker = maker;
                                    }
                                  },
                                  dropdownMenuEntries: makerProvider.makersDropdown,
                                ),
                                DropdownMenu<PartUnit>(
                                  label: IconLabel(labelType: LabelType.unit),
                                  enableFilter: true,
                                  menuHeight: 400,
                                  width: 180,
                                  initialSelection: selectedUnit,
                                  onSelected: (unit) {
                                    if (unit != null) {
                                      selectedUnit = unit;
                                    }
                                  },
                                  dropdownMenuEntries: unitProvider.unitsDropdown,
                                ),
                                SizedBox(
                                  width: 180,
                                  child: TextField(
                                    controller: specFieldController,
                                    focusNode: _specFieldFocusNode,
                                    textAlign: TextAlign.start,
                                    decoration: InputDecoration(
                                      label: IconLabel(labelType: LabelType.specification),
                                      hintText: "입력 후 엔터",
                                      border: OutlineInputBorder(),
                                    ),
                                    onSubmitted: (sectionName) {
                                      addPart();
                                    },
                                  ),
                                ),
                                ElevatedButton(
                                  child: Icon(Icons.add, size: 30),
                                  onPressed: () {
                                    addPart();
                                  },
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: SingleChildScrollView(
                                child: PaginatedDataTable(
                                  key: dataTableKey,
                                  columns: columns,
                                  source: _dataSource,
                                  rowsPerPage: tableOptionsProvider.rowsPerPage,
                                  availableRowsPerPage: tableOptionsProvider.availableRowsPerPage,
                                  onRowsPerPageChanged: (value) {
                                    if (value != null) {
                                      tableOptionsProvider.updateRowsPerPage(value);
                                    }
                                  },
                                  showCheckboxColumn: true,
                                ),
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SaveAllButton(
                                onPressed: () async {
                                  if (parts.isEmpty) {
                                    showDialog(
                                      context: context,
                                      builder: (context) =>
                                          ErrorDialog(message: '등록할 부품이 없습니다.'),
                                    );
                                    return;
                                  }
                      
                                  final confirmed = await showDialog(
                                    context: context,
                                    builder: (context) =>
                                        ConfirmDialog(message: "전체등록 하시겠습니까?"),
                                  );
                      
                                  if (confirmed == null || confirmed == false) return;
                      
                                  int count = await registerAllParts();
                      
                                  if (!context.mounted) return;
                      
                                  if (count > 0) {
                                    setState(() {
                                      parts.clear();
                                      dataTableKey = UniqueKey();
                                      refresh = true;
                                    });
                                    showDialog(
                                      context: context,
                                      builder: (context) => ResultDialog(
                                        message: '$count개의 부품이 등록되었습니다.',
                                      ),
                                    );
                                  } else {
                                    showDialog(
                                      context: context,
                                      builder: (context) =>
                                          ErrorDialog(message: '이미 등록된 부품입니다.'),
                                    );
                                    return;
                                  }
                                },
                              ),
                              SizedBox(height: 20),
                              DeleteButton(onPressed: () {
                                if (selectedParts.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('삭제할 부품을 선택해주세요.')),
                                    );
                                    return;
                                  }
                                  setState(() {
                                    parts.removeAll(selectedParts);
                                    selectedParts.clear();
                                  });
                              }),
                            ],
                          ),
                        ],
                      ),
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
