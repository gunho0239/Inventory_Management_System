import 'package:flutter/material.dart';
import 'package:inventory_management/datatable_source/part_data.dart';
import 'package:inventory_management/main.dart';
import 'package:inventory_management/models/part.dart';
import 'package:inventory_management/models/part_maker.dart';
import 'package:inventory_management/models/part_type.dart';
import 'package:inventory_management/models/part_unit.dart';
import 'package:inventory_management/screens/type_management_screen.dart';
import 'package:inventory_management/style/style.dart';
import 'package:inventory_management/widgets/buttons.dart';
import 'package:inventory_management/widgets/title.dart';

class PartRegisterScreen extends StatefulWidget {
  const PartRegisterScreen({super.key});

  @override
  State<PartRegisterScreen> createState() => _PartRegisterScreenState();
}

class _PartRegisterScreenState extends State<PartRegisterScreen> {
  final TextEditingController specFieldController = TextEditingController();
  PartType? selectedType;
  PartMaker? selectedMaker;
  PartUnit? selectedUnit;

  final List<DataColumn> columns = [
    DataColumn(label: Text('품명')),
    DataColumn(label: Text('규격')),
    DataColumn(label: Text('제조사')),
    DataColumn(label: Text('단위')),
  ];
  final List<DataRow> rows = [];
  late PartDataSource _dataSource;
  Set<Part> parts = {};
  Set<Part> selectedParts = {};

  @override
  Widget build(BuildContext context) {
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
                        onPressed: () {},
                        child: Text('제조사관리', style: TextStyle(fontSize: 18)),
                      ),
                      ElevatedButton(
                        style: AppButtonStyle.newPage,
                        onPressed: () {},
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
                                    // focusNode: _sectionFieldFocusNode,
                                    textAlign: TextAlign.center,
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
                                  width: 180,
                                  initialSelection: selectedType,
                                  onSelected: (type) {
                                    selectedType = type!;
                                  },
                                  dropdownMenuEntries: [],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                SizedBox(width: 60, child: Text("제조사 :")),
                                DropdownMenu<PartMaker>(
                                  width: 180,
                                  initialSelection: selectedMaker,
                                  onSelected: (maker) {
                                    selectedMaker = maker!;
                                  },
                                  dropdownMenuEntries: [],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                SizedBox(width: 60, child: Text("단위 :")),
                                DropdownMenu<PartUnit>(
                                  width: 180,
                                  initialSelection: selectedUnit,
                                  onSelected: (unit) {
                                    selectedUnit = unit!;
                                  },
                                  dropdownMenuEntries: [],
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(100, 20, 0, 0),
                              child: ElevatedButton(
                                child: Icon(Icons.add, size: 30),
                                onPressed: () {},
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
                                // key: dataTableKey,
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
                            SaveAllButton(onPressed: () {}),
                            SizedBox(height: 20),
                            DeleteButton(onPressed: () {}),
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
