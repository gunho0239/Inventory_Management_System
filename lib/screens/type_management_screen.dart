import 'package:flutter/material.dart';
import 'package:inventory_management/api/api_response_entity.dart';
import 'package:inventory_management/datatable_source/part_type_data.dart';
import 'package:inventory_management/main.dart';
import 'package:inventory_management/models/part_type.dart';
import 'package:inventory_management/providers/type_provider.dart';
import 'package:inventory_management/repository/part_type_repository.dart';
import 'package:inventory_management/widgets/buttons.dart';
import 'package:inventory_management/widgets/dialogs.dart';
import 'package:inventory_management/widgets/title.dart';
import 'package:provider/provider.dart';

class TypeManagementScreen extends StatefulWidget {
  const TypeManagementScreen({super.key});

  @override
  State<TypeManagementScreen> createState() => _TypeManagementScreenState();
}

class _TypeManagementScreenState extends State<TypeManagementScreen> {
  
  late PartType selectedType;

  final List<DataColumn> columns = [DataColumn(label: Text('품명'))];

  Set<PartType> selectedTypes = {};
  late PartTypeDataSource _dataSource;
  Key dataTableKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    final typeProvider = Provider.of<TypeProvider>(context, listen: false);
    selectedType = typeProvider.allType;
    typeProvider.reloadTypes();
  }

  @override
  Widget build(BuildContext context) {
    final typeProvider = Provider.of<TypeProvider>(context);

    _dataSource = PartTypeDataSource(
      types: (selectedType == typeProvider.allType) ? typeProvider.types : [selectedType],
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
          ScreenTitle(menu: InventoryMenu.typeManagement),
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
                      RefreshButton(
                        onPressed: () {
                          setState(() {
                            typeProvider.reloadTypes();
                          });
                        },
                      ),
                      RegisterPageButton(InventoryMenu.typeRegister,),
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
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 5.0,
                            horizontal: 10.0,
                          ),
                          child: DropdownMenu<PartType>(
                            label: Text("품명"),
                            menuHeight: 400,
                            initialSelection: selectedType,
                            onSelected: (type) {
                              selectedType = type!;
                              setState(() {});
                            },
                            dropdownMenuEntries: typeProvider.typesDropdownWithAll,
                          ),
                        ),
                        SizedBox(
                          width: 500,
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
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: DeleteButton(
                            onPressed: () async {
                              if (selectedTypes.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('삭제할 품명을 선택해주세요.')),
                                );
                                return;
                              }
                              final confirmed = await showDialog(
                                context: context,
                                builder: (context) =>
                                    ConfirmDialog(message: "선택한 품명을 삭제하시겠습니까?"),
                              );

                              if (confirmed == null || confirmed == false) return;

                              List<int> typeIds = selectedTypes
                                  .map((type) => type.id!)
                                  .toList();
                              BulkRequestResult result = await PartTypeRepository()
                                  .removePartTypes(typeIds);

                              String message = "";
                              if (result.successCount > 0) {
                                dataTableKey = UniqueKey();
                                selectedType = typeProvider.allType;
                                message =
                                    "${result.successCount}개의 품명을 삭제하였습니다.\n";
                              }
                              if (result.failedCount > 0) {
                                message =
                                    "${result.successCount}개 삭제 완료\n${result.failedCount}개 삭제 실패!\n해당 품명의 부품을 먼저 삭제해주세요.";
                              }

                              if (!context.mounted) return;
                              showDialog(
                                context: context,
                                builder: (context) =>
                                    ResultDialog(message: message),
                              );

                              selectedTypes.clear();
                              Provider.of<TypeProvider>(
                                context,
                                listen: false,
                              ).reloadTypes();
                              setState(() {});
                            },
                          ),
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
