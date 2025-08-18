import 'package:flutter/material.dart';
import 'package:inventory_management/api/api_client.dart';
import 'package:inventory_management/datatable_source/part_unit_data.dart';
import 'package:inventory_management/main.dart';
import 'package:inventory_management/models/part_unit.dart';
import 'package:inventory_management/providers/unit_provider.dart';
import 'package:inventory_management/repository/part_unit_repository.dart';
import 'package:inventory_management/screens/unit_register_screen.dart';
import 'package:inventory_management/widgets/buttons.dart';
import 'package:inventory_management/widgets/dialogs.dart';
import 'package:inventory_management/widgets/title.dart';
import 'package:provider/provider.dart';

class UnitManagementScreen extends StatefulWidget {
  const UnitManagementScreen({super.key});

  @override
  State<UnitManagementScreen> createState() => _UnitManagementScreenState();
}

class _UnitManagementScreenState extends State<UnitManagementScreen> {
  late PartUnit selectedUnit;

  final List<DataColumn> columns = [DataColumn(label: Text('단위'))];

  Set<PartUnit> selectedUnits = {};
  late PartUnitDataSource _dataSource;
  Key dataTableKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    final unitProvider = Provider.of<UnitProvider>(context, listen: false);
    selectedUnit = unitProvider.allUnit;
    unitProvider.reloadUnits();
  }

  @override
  Widget build(BuildContext context) {
    final unitProvider = Provider.of<UnitProvider>(context);

    _dataSource = PartUnitDataSource(
      units: (selectedUnit == unitProvider.allUnit) ? unitProvider.units : [selectedUnit],
      selectedUnits: selectedUnits,
      onSelectChanged: (unit, selected) {
        setState(() {
          if (selected) {
            selectedUnits.add(unit);
          } else {
            selectedUnits.remove(unit);
          }
        });
      },
    );

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenTitle(menu: InventoryMenu.unitManagement),
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
                            unitProvider.reloadUnits();
                          });
                        },
                      ),
                      RegisterPageButton(InventoryMenu.unitRegister,),
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
                          child: DropdownMenu<PartUnit>(
                            label: Text("단위"),
                            menuHeight: 400,
                            initialSelection: selectedUnit,
                            onSelected: (unit) {
                              selectedUnit = unit!;
                              setState(() {});
                            },
                            dropdownMenuEntries: unitProvider.unitsDropdownWithAll,
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
                              if (selectedUnits.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('삭제할 단위를 선택해주세요.')),
                                );
                                return;
                              }
                              final confirmed = await showDialog(
                                context: context,
                                builder: (context) =>
                                    ConfirmDialog(message: "선택한 단위를 삭제하시겠습니까?"),
                              );

                              if (!confirmed) return;

                              List<int> unitIds = selectedUnits
                                  .map((unit) => unit.id!)
                                  .toList();
                              DeleteResult result = await PartUnitRepository()
                                  .removePartUnits(unitIds);

                              String message = "";
                              if (result.successCount > 0) {
                                dataTableKey = UniqueKey();
                                selectedUnit = unitProvider.allUnit;
                                message =
                                    "${result.successCount}개의 단위를 삭제하였습니다.\n";
                              }
                              if (result.failedCount > 0) {
                                message =
                                    "${result.successCount}개 삭제 완료\n${result.failedCount}개 삭제 실패!\n해당 단위의 부품을 먼저 삭제해주세요.";
                              }

                              if (!mounted) return;
                              showDialog(
                                context: context,
                                builder: (context) =>
                                    ResultDialog(message: message),
                              );

                              selectedUnits.clear();
                              Provider.of<UnitProvider>(
                                context,
                                listen: false,
                              ).reloadUnits();
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
