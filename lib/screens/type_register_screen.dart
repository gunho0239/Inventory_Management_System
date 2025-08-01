import 'package:flutter/material.dart';
import 'package:inventory_management/datatable_source/part_type_data.dart';
import 'package:inventory_management/main.dart';
import 'package:inventory_management/models/part_type.dart';
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
    _dataSource = PartTypeDataSource(
      types: types.toList(),
      selectedTypes: selectedTypes,
      onSelectChanged: (section, selected) {
        setState(() {
          if (selected) {
            selectedTypes.add(section);
          } else {
            selectedTypes.remove(section);
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
                        SizedBox(width: 10),
                        Row(
                          children: [
                            Text("품명 :"),
                            SizedBox(
                              width: 180,
                              child: TextField(
                                controller: typeFieldController,
                                focusNode: _typeFieldFocusNode,
                                textAlign: TextAlign.center,
                                onSubmitted: (typeName) {
                                  addType(context, typeName.trim());
                                },
                              ),
                            ),
                            ElevatedButton(
                              child: Icon(Icons.add, size: 30),
                              onPressed: () {
                                String typeName = typeFieldController.text
                                    .trim();
                                addType(context, typeName);
                              },
                            ),
                          ],
                        ),
                        SizedBox(width: 50),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: SingleChildScrollView(
                            child: SizedBox(
                              width: 500,
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
                                if (types.isEmpty) {
                                  showDialog(
                                    context: context,
                                    builder: (context) =>
                                        ErrorDialog(message: '등록할 품명이 없습니다.'),
                                  );
                                  return;
                                }

                                int count = await registerAllTypes();

                                if (!mounted) return;

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
