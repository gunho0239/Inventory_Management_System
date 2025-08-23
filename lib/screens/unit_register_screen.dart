import 'package:flutter/material.dart';
import 'package:inventory_management/datatable_source/part_unit_data.dart';
import 'package:inventory_management/enums/inventory_menu.dart';
import 'package:inventory_management/models/part_unit.dart';
import 'package:inventory_management/providers/unit_provider.dart';
import 'package:inventory_management/repository/part_unit_repository.dart';
import 'package:inventory_management/widgets/buttons.dart';
import 'package:inventory_management/widgets/dialogs.dart';
import 'package:inventory_management/widgets/title.dart';
import 'package:provider/provider.dart';

class UnitRegisterScreen extends StatefulWidget {
  const UnitRegisterScreen({super.key});

  @override
  State<UnitRegisterScreen> createState() => _UnitRegisterScreenState();
}

class _UnitRegisterScreenState extends State<UnitRegisterScreen> {
  final TextEditingController unitFieldController = TextEditingController();
  final FocusNode _unitFieldFocusNode = FocusNode();

  final List<DataColumn> columns = [DataColumn(label: Text('단위'))];
  late PartUnitDataSource _dataSource;
  Key dataTableKey = UniqueKey();

  Set<PartUnit> units = {};
  Set<PartUnit> selectedUnits = {};

  void addUnit(BuildContext context, String unitName) {
    if (unitName.isNotEmpty) {
      PartUnit newUnit = PartUnit(unit: unitName);
      units.add(newUnit);
      unitFieldController.clear();
      setState(() {});
      FocusScope.of(context).requestFocus(_unitFieldFocusNode);
    } 
    else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('단위 이름을 입력해주세요.')));
    }
  }

  Future<int> registerAllUnits() async {
    if (units.isEmpty) return 0;

    List<PartUnit> unitList = units.toList();
    unitList.sort((a, b) => a.unit!.compareTo(b.unit!));

    List<PartUnit> registeredUnits = await PartUnitRepository()
        .addPartUnits(unitList);

    return registeredUnits.length;
  }

  @override
  Widget build(BuildContext context) {
    _dataSource = PartUnitDataSource(
      units: units.toList(),
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
          ScreenTitle(menu: InventoryMenu.unitRegister),
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
                          padding: const EdgeInsets.only(left: 10, top: 10,),
                          child: SizedBox(
                            width: 180,
                            child: TextField(
                              controller: unitFieldController,
                              focusNode: _unitFieldFocusNode,
                              decoration: InputDecoration(
                                labelText: "단위 입력",
                                hintText: "입력 후 엔터",
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: (unitName) {
                                addUnit(context, unitName.trim());
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
                                  rowsPerPage: 10,
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
                                if (units.isEmpty) {
                                  showDialog(
                                    context: context,
                                    builder: (context) =>
                                        ErrorDialog(message: '등록할 단위가 없습니다.'),
                                  );
                                  return;
                                }

                                final confirmed = await showDialog(
                                  context: context,
                                  builder: (context) =>
                                      ConfirmDialog(message: "전체등록 하시겠습니까?"),
                                );

                                if (confirmed == null || confirmed == false) return;

                                int count = await registerAllUnits();

                                if (!context.mounted) return;

                                if (count > 0) {
                                  units.clear();
                                  dataTableKey = UniqueKey();
                                  Provider.of<UnitProvider>(
                                    context,
                                    listen: false,
                                  ).reloadUnits();
                                  setState(() {});
                                  showDialog(
                                    context: context,
                                    builder: (context) => ResultDialog(
                                      message: '$count개의 단위가 등록되었습니다.',
                                    ),
                                  );
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (context) =>
                                        ErrorDialog(message: '이미 등록된 단위입니다.'),
                                  );
                                  return;
                                }
                              },
                            ),
                            SizedBox(height: 20),
                            DeleteButton(
                              onPressed: () {
                                if (selectedUnits.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('삭제할 단위를 선택해주세요.')),
                                  );
                                  return;
                                }
                                setState(() {
                                  units.removeAll(selectedUnits);
                                  selectedUnits.clear();
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
