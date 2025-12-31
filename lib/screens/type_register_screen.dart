import 'package:flutter/material.dart';
import 'package:inventory_management/datatable_source/part_type_data.dart';
import 'package:inventory_management/enums/inventory_menu.dart';
import 'package:inventory_management/models/part_type.dart';
import 'package:inventory_management/providers/data_table_options_provider.dart';
import 'package:inventory_management/providers/type_provider.dart';
import 'package:inventory_management/repository/part_type_repository.dart';
import 'package:inventory_management/widgets/buttons.dart';
import 'package:inventory_management/widgets/dialogs.dart';
import 'package:inventory_management/widgets/title.dart';
import 'package:provider/provider.dart';

class TypeRegisterScreen extends StatefulWidget {
  const TypeRegisterScreen({super.key});

  @override
  State<TypeRegisterScreen> createState() => _TypeRegisterScreenState();
}

class _TypeRegisterScreenState extends State<TypeRegisterScreen> {
  final TextEditingController typeFieldController = TextEditingController();
  final FocusNode _typeFieldFocusNode = FocusNode();

  final List<DataColumn> columns = [DataColumn(label: Text('품명'))];
  late PartTypeDataSource _dataSource;
  Key dataTableKey = UniqueKey();

  Set<PartType> types = {};
  Set<PartType> selectedTypes = {};

  void addType(BuildContext context, String typeName) {
    if (typeName.isNotEmpty) {
      PartType newType = PartType(type: typeName);
      types.add(newType);
      typeFieldController.clear();
      setState(() {});
      FocusScope.of(context).requestFocus(_typeFieldFocusNode);
    } 
    else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('품명 이름을 입력해주세요.')));
    }
  }

  Future<int> registerAllTypes() async {
    if (types.isEmpty) return 0;

    List<PartType> typeList = types.toList();
    typeList.sort((a, b) => a.type!.compareTo(b.type!));

    List<PartType> registeredTypes = await PartTypeRepository()
        .addPartTypes(typeList);

    return registeredTypes.length;
  }

  @override
  Widget build(BuildContext context) {
    final tableOptionsProvider = context.watch<DataTableOptionsProvider>();
    
    _dataSource = PartTypeDataSource(
      types: types.toList(),
      selectedTypes: selectedTypes,
      onSelectChanged: (type, selected) {
        setState(() {
          if (selected) {
            selectedTypes.add(type);
          } else {
            selectedTypes.remove(type);
          }
        });
      },
    );

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenTitle(menu: InventoryMenu.typeRegister),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 5.0,
                  ),
                  child: GoBackButton(),
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
                        Padding(
                          padding: const EdgeInsets.only(left: 10, top: 10),
                          child: SizedBox(
                            width: 180,
                            child: TextField(
                              controller: typeFieldController,
                              focusNode: _typeFieldFocusNode,
                              decoration: InputDecoration(
                                labelText: "품명 입력",
                                hintText: "입력 후 엔터",
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: (typeName) {
                                addType(context, typeName.trim());
                              },
                            ),
                          ),
                        ),
                        Spacer(flex: 1,),
                        Flexible(
                          flex: 30,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: SingleChildScrollView(
                              child: SizedBox(
                                width: 500,
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
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SaveAllButton(
                              onPressed: () async {
                                if (types.isEmpty) {
                                  showDialog(
                                    context: context,
                                    builder: (context) =>
                                        ErrorDialog(message: '등록할 품명이 없습니다.'),
                                  );
                                  return;
                                }

                                final confirmed = await showDialog(
                                  context: context,
                                  builder: (context) =>
                                      ConfirmDialog(message: "전체등록 하시겠습니까?"),
                                );

                                if (confirmed == null || confirmed == false) return;

                                int count = await registerAllTypes();

                                if (!context.mounted) return;

                                if (count > 0) {
                                  types.clear();
                                  dataTableKey = UniqueKey();
                                  Provider.of<TypeProvider>(
                                    context,
                                    listen: false,
                                  ).reloadTypes();
                                  setState(() {});
                                  showDialog(
                                    context: context,
                                    builder: (context) => ResultDialog(
                                      message: '$count개의 품명이 등록되었습니다.',
                                    ),
                                  );
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (context) =>
                                        ErrorDialog(message: '이미 등록된 품명입니다.'),
                                  );
                                  return;
                                }
                              },
                            ),
                            SizedBox(height: 20),
                            DeleteButton(
                              onPressed: () {
                                if (selectedTypes.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('삭제할 품명을 선택해주세요.')),
                                  );
                                  return;
                                }
                                setState(() {
                                  types.removeAll(selectedTypes);
                                  selectedTypes.clear();
                                });
                              },
                            ),
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
