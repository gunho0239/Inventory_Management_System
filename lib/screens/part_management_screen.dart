import 'package:flutter/material.dart';
import 'package:inventory_management/constants/default_dropdownmenuitem.dart';
import 'package:inventory_management/datatable_source/part_data.dart';
import 'package:inventory_management/main.dart';
import 'package:inventory_management/models/part.dart';
import 'package:inventory_management/models/part_type.dart';
import 'package:inventory_management/screens/part_register_screen.dart';
import 'package:inventory_management/widgets/buttons.dart';
import 'package:inventory_management/widgets/title.dart';

class PartManagementScreen extends StatefulWidget {
  const PartManagementScreen({super.key});

  @override
  State<PartManagementScreen> createState() => _PartManagementScreenState();
}

class _PartManagementScreenState extends State<PartManagementScreen> {
  late PartType selectedType;
  PartType allType = PartType(id: defaultId, type: defaultLabel);
  final TextEditingController specFieldController = TextEditingController();

  final List<DataColumn> columns = [
    DataColumn(label: Text('품명')),
    DataColumn(label: Text('규격')),
    DataColumn(label: Text('제조사')),
    DataColumn(label: Text('단위')),
  ];
  final List<DataRow> rows = [];
  late PartDataSource _dataSource;
  List<Part> inquiredParts = [];
  Set<Part> selectedParts = {};

  @override
  void initState() {
    super.initState();
    selectedType = allType;
  }

  @override
  Widget build(BuildContext context) {
    _dataSource = PartDataSource(
      parts: inquiredParts,
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

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenTitle(menu: InventoryMenu.partManagement),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 20.0,
              ),
              child: Column(
                children: [
                  Row(
                    spacing: 5,
                    children: [
                      Text("품명 :"),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 5.0,
                        ),
                        child: DropdownMenu<PartType>(
                          initialSelection: selectedType,
                          onSelected: (type) {
                            selectedType = type!;
                          },
                          dropdownMenuEntries: [
                            DropdownMenuEntry<PartType>(
                              value: allType,
                              label: allType.type!,
                            ),
                            // ...sectionProvider.sections.map(
                            //   (section) => DropdownMenuEntry<LocationSection>(
                            //     value: section,
                            //     label: section.section!,
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                      SizedBox(width: 20),
                      Text("규격 :"),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 5.0,
                        ),
                        child: DropdownMenu<PartType>(
                          controller: specFieldController,
                          initialSelection: selectedType,
                          onSelected: (type) {
                            selectedType = type!;
                          },
                          dropdownMenuEntries: [
                            DropdownMenuEntry<PartType>(
                              value: allType,
                              label: allType.type!,
                            ),
                            // ...sectionProvider.sections.map(
                            //   (section) => DropdownMenuEntry<LocationSection>(
                            //     value: section,
                            //     label: section.section!,
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        child: Icon(Icons.search, size: 30),
                        onPressed: () {
                          // getLocation();
                          // dataTableKey = UniqueKey();
                        },
                      ),
                      SizedBox(width: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PartRegisterScreen(),
                            ),
                          );
                        },
                        child: Row(
                          spacing: 5,
                          children: [
                            Icon(Icons.add, size: 30),
                            Text('새로운 부품', style: TextStyle(fontSize: 18)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 700,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10.0,
                            ),
                            child: SingleChildScrollView(
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
                        DeleteButton(
                          onPressed: () {
                          },
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
