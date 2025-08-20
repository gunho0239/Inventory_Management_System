import 'package:flutter/material.dart';
import 'package:inventory_management/api/api_response_entity.dart';
import 'package:inventory_management/datatable_source/part_data.dart';
import 'package:inventory_management/main.dart';
import 'package:inventory_management/models/part.dart';
import 'package:inventory_management/models/part_maker.dart';
import 'package:inventory_management/models/part_type.dart';
import 'package:inventory_management/providers/maker_provider.dart';
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
  late PartMaker selectedMaker;

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

    final makerProvider = Provider.of<MakerProvider>(context, listen: false);
    selectedMaker = makerProvider.allMaker;
    makerProvider.reloadMakers();
  }

  void getParts() async {
    final typeProvider = Provider.of<TypeProvider>(context, listen: false);
    final makerProvider = Provider.of<MakerProvider>(context, listen: false);
    PartRepository partRepo = PartRepository();
    
    final isAllType = selectedType == typeProvider.allType;
    final isAllMaker = selectedMaker == makerProvider.allMaker;
    final specText = specFieldController.text.trim();
    
    inquiredParts = await switch ((isAllType, isAllMaker, specText.isEmpty)) {
      (true, true, true) => partRepo.getAllParts(),
      (false, true, true) => partRepo.getPartsByType(selectedType.id!),
      (true, false, true) => partRepo.getPartsByMaker(selectedMaker.id!),
      _ => partRepo.getPartsByFilter(
              isAllType ? null : selectedType.id!,
              isAllMaker ? null : selectedMaker.id!,
              specText.isEmpty ? null : specText,
            ),
    };

    selectedParts.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final typeProvider = Provider.of<TypeProvider>(context);
    final makerProvider = Provider.of<MakerProvider>(context);

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

    return Column(
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
                  spacing: 20,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                      child: DropdownMenu<PartType>(
                        label: Text("품명"),
                        enableFilter: true,
                        menuHeight: 400,
                        width: 150,
                        onSelected: (type) {
                          selectedType = type!;
                          getParts();
                          dataTableKey = UniqueKey();
                        },
                        dropdownMenuEntries:
                            typeProvider.typesDropdownWithAll,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                      child: DropdownMenu<PartMaker>(
                        label: Text("제조사"),
                        enableFilter: true,
                        menuHeight: 400,
                        width: 150,
                        onSelected: (maker) {
                          selectedMaker = maker!;
                          getParts();
                          dataTableKey = UniqueKey();
                        },
                        dropdownMenuEntries:
                            makerProvider.makersDropdownWithAll,
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: TextField(
                        controller: specFieldController,
                        decoration: InputDecoration(
                          labelText: "규격",
                          hintText: "입력 후 엔터",
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (sectionName) {
                          dataTableKey = UniqueKey();
                          getParts();
                        },
                      ),
                    ),
                    RegisterPageButton(InventoryMenu.partRegister,
                      onPressed: () async {
                        final refresh = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PartRegisterScreen(),
                          ),
                        );
    
                        if (refresh == true) {
                          getParts();
                          dataTableKey = UniqueKey();
                        }
                      },
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
    
                          if (confirmed == null || confirmed == false) return;
                          
                          List<int> partIds = selectedParts
                              .map((part) => part.id!)
                              .toList();
                          BulkRequestResult result = await PartRepository()
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
    );
  }
}
