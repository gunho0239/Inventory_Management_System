import 'package:flutter/material.dart';
import 'package:inventory_management/datatable_source/part_data.dart';
import 'package:inventory_management/main.dart';
import 'package:inventory_management/models/part.dart';
import 'package:inventory_management/models/part_maker.dart';
import 'package:inventory_management/models/part_type.dart';
import 'package:inventory_management/models/part_unit.dart';
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
import 'package:inventory_management/widgets/title.dart';
import 'package:provider/provider.dart';

class PartRegisterScreen extends StatefulWidget {
  const PartRegisterScreen({super.key});

  @override
  State<PartRegisterScreen> createState() => _PartRegisterScreenState();
}

class _PartRegisterScreenState extends State<PartRegisterScreen> {
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

    selectedType = typeProvider.allType;
    selectedMaker = makerProvider.allMaker;
    selectedUnit = unitProvider.allUnit;

    typeProvider.reloadTypes();
    makerProvider.reloadMakers();
    unitProvider.reloadUnits();
  }


  @override
  Widget build(BuildContext context) {
    final typeProvider = Provider.of<TypeProvider>(context);
    final makerProvider = Provider.of<MakerProvider>(context);
    final unitProvider = Provider.of<UnitProvider>(context);

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
                      GoBackButton(),
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 10),
                        Column(
                          spacing: 10,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SizedBox(width: 60, child: Text("규격 :")),
                                SizedBox(
                                  width: 180,
                                  child: TextField(
                                    controller: specFieldController,
                                    focusNode: _specFieldFocusNode,
                                    textAlign: TextAlign.start,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                    ),
                                    onSubmitted: (sectionName) {
                                      // addSection(context, sectionName.trim());
                                    },
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                SizedBox(width: 60, child: Text("품명 :")),
                                DropdownMenu<PartType>(
                                  menuHeight: 400,
                                  width: 180,
                                  initialSelection: selectedType,
                                  onSelected: (type) {
                                    selectedType = type!;
                                  },
                                  dropdownMenuEntries: typeProvider.typesDropdown,
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                SizedBox(width: 60, child: Text("제조사 :")),
                                DropdownMenu<PartMaker>(
                                  menuHeight: 400,
                                  width: 180,
                                  initialSelection: selectedMaker,
                                  onSelected: (maker) {
                                    selectedMaker = maker!;
                                  },
                                  dropdownMenuEntries: makerProvider.makersDropdown,
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                SizedBox(width: 60, child: Text("단위 :")),
                                DropdownMenu<PartUnit>(
                                  menuHeight: 400,
                                  width: 180,
                                  initialSelection: selectedUnit,
                                  onSelected: (unit) {
                                    selectedUnit = unit!;
                                  },
                                  dropdownMenuEntries: unitProvider.unitsDropdown,
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(100, 20, 0, 0),
                              child: ElevatedButton(
                                child: Icon(Icons.add, size: 30),
                                onPressed: () {
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
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('모든 항목을 입력해주세요.'),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 50),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: SingleChildScrollView(
                            child: SizedBox(
                              width: 700,
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

                                int count = await registerAllParts();

                                if (!mounted) return;

                                if (count > 0) {
                                  parts.clear();
                                  dataTableKey = UniqueKey();
                                  // Provider.of<PartProvider>(
                                  //   context,
                                  //   listen: false,
                                  // ).reloadParts();
                                  setState(() {});
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
