import 'package:flutter/material.dart';
import 'package:inventory_management/api/api_client.dart';
import 'package:inventory_management/datatable_source/part_data.dart';
import 'package:inventory_management/main.dart';
import 'package:inventory_management/models/part.dart';
import 'package:inventory_management/models/part_type.dart';
import 'package:inventory_management/providers/type_provider.dart';
import 'package:inventory_management/repository/part_repository.dart';
import 'package:inventory_management/screens/part_register_screen.dart';
import 'package:inventory_management/widgets/buttons.dart';
import 'package:inventory_management/widgets/dialogs.dart';
import 'package:inventory_management/widgets/title.dart';
import 'package:provider/provider.dart';

class PartManagementScreen extends StatefulWidget {
  const PartManagementScreen({super.key});

  @override
  State<PartManagementScreen> createState() => _PartManagementScreenState();
}

class _PartManagementScreenState extends State<PartManagementScreen> {
  late PartType selectedType;

  late Part selectedPart;
  final TextEditingController specFieldController = TextEditingController();

  final List<DataColumn> columns = [
    DataColumn(label: Text('품명')),
    DataColumn(label: Text('규격')),
    DataColumn(label: Text('제조사')),
    DataColumn(label: Text('단위')),
  ];
  late PartDataSource _dataSource;
  Key dataTableKey = UniqueKey();
  List<Part> inquiredParts = [];
  Set<Part> selectedParts = {};

  @override
  void initState() {
    super.initState();
    final typeProvider = Provider.of<TypeProvider>(context, listen: false);
    selectedType = typeProvider.allType;
    typeProvider.reloadTypes();
  }

  void getParts() async {
    final typeProvider = Provider.of<TypeProvider>(context, listen: false);
    PartRepository partRepo = PartRepository();
    final specText = specFieldController.text.trim();

    if (selectedType == typeProvider.allType && specText == '') {
      inquiredParts = await partRepo.getAllParts();
    } 
    else if (specText == '') {
      inquiredParts = await partRepo.getPartsByType(selectedType.id!);
    }
    else if (selectedType == typeProvider.allType) {
      inquiredParts = await partRepo.getPartsBySpecification(specText);
    }
    else {
      inquiredParts = await partRepo.getPartsByTypeAndSpecification(selectedType.id!, specText);
    }

    selectedParts.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final typeProvider = Provider.of<TypeProvider>(context);

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
                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                        child: DropdownMenu<PartType>(
                          width: 150,
                          initialSelection: selectedType,
                          onSelected: (type) {
                            selectedType = type!;
                          },
                          dropdownMenuEntries:
                              typeProvider.typesDropdownWithAll,
                        ),
                      ),
                      SizedBox(width: 20),
                      Text("규격 :"),
                      SizedBox(
                        width: 180,
                        child: TextField(
                          controller: specFieldController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (sectionName) {
                            getParts();
                            dataTableKey = UniqueKey();
                          },
                        ),
                      ),
                      SizedBox(width: 20),
                      ElevatedButton(
                        child: Icon(Icons.search, size: 30),
                        onPressed: () {
                          getParts();
                          dataTableKey = UniqueKey();
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
                                key: dataTableKey,
                                columns: columns,
                                source: _dataSource,
                                rowsPerPage: 10,
                                showCheckboxColumn: true,
                              ),
                            ),
                          ),
                        ),
                        DeleteButton(
                          onPressed: () async {
                            if (selectedParts.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('삭제할 부품을 선택해주세요.')),
                              );
                              return;
                            }
                            final confirmed = await showDialog(
                              context: context,
                              builder: (context) => ConfirmDialog(
                                message: "선택한 부품을 삭제하시겠습니까?",
                              ),
                            );

                            if (!confirmed) return;
                            List<int> partIds = selectedParts
                                .map((part) => part.id!)
                                .toList();
                            DeleteResult result = await PartRepository()
                                .removeParts(partIds);

                            String message = "";
                            if (result.successCount > 0) {
                              dataTableKey = UniqueKey();
                              message =
                                  "${result.successCount}개의 부품을 삭제하였습니다.\n";
                            }
                            if (result.failedCount > 0) {
                              message =
                                  "${result.successCount}개 삭제 완료\n${result.failedCount}개 삭제 실패!";
                            }

                            if (!mounted) return;
                            showDialog(
                              context: context,
                              builder: (context) => ResultDialog(
                                message: message,
                              ),
                            );

                            selectedParts.clear();
                            getParts();
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
