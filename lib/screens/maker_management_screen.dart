import 'package:flutter/material.dart';
import 'package:inventory_management/api/api_response_entity.dart';
import 'package:inventory_management/datatable_source/part_maker_data.dart';
import 'package:inventory_management/enums/inventory_menu.dart';
import 'package:inventory_management/models/part_maker.dart';
import 'package:inventory_management/providers/maker_provider.dart';
import 'package:inventory_management/repository/part_maker_repository.dart';
import 'package:inventory_management/widgets/buttons.dart';
import 'package:inventory_management/widgets/dialogs.dart';
import 'package:inventory_management/widgets/title.dart';
import 'package:provider/provider.dart';

class MakerManagementScreen extends StatefulWidget {
  const MakerManagementScreen({super.key});

  @override
  State<MakerManagementScreen> createState() => _MakerManagementScreenState();
}

class _MakerManagementScreenState extends State<MakerManagementScreen> {
  late PartMaker selectedMaker;

  final List<DataColumn> columns = [DataColumn(label: Text('제조사'))];

  Set<PartMaker> selectedMakers = {};
  late PartMakerDataSource _dataSource;
  Key dataTableKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    final makerProvider = Provider.of<MakerProvider>(context, listen: false);
    selectedMaker = makerProvider.allMaker;;
    makerProvider.reloadMakers();
  }

  @override
  Widget build(BuildContext context) {
    final makerProvider = Provider.of<MakerProvider>(context);

    _dataSource = PartMakerDataSource(
      makers: (selectedMaker == makerProvider.allMaker) ? makerProvider.makers : [selectedMaker],
      selectedMakers: selectedMakers,
      onSelectChanged: (maker, selected) {
        setState(() {
          if (selected) {
            selectedMakers.add(maker);
          } else {
            selectedMakers.remove(maker);
          }
        });
      },
    );

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenTitle(menu: InventoryMenu.makerManagement),
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
                            makerProvider.reloadMakers();
                          });
                        },
                      ),
                      RegisterPageButton(InventoryMenu.makerRegister,),
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
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 5.0,
                                horizontal: 10.0,
                              ),
                              child: DropdownMenu<PartMaker>(
                                label: Text("제조사"),
                                menuHeight: 400,
                                initialSelection: selectedMaker,
                                onSelected: (maker) {
                                  selectedMaker = maker!;
                                  setState(() {});
                                },
                                dropdownMenuEntries: makerProvider.makersDropdownWithAll,
                              ),
                            ),
                          ],
                        ),
                        Flexible(
                          child: SizedBox(
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
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: DeleteButton(
                            onPressed: () async {
                              if (selectedMakers.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('삭제할 제조사를 선택해주세요.')),
                                );
                                return;
                              }
                              final confirmed = await showDialog(
                                context: context,
                                builder: (context) =>
                                    ConfirmDialog(message: "선택한 제조사를 삭제하시겠습니까?"),
                              );

                              if (confirmed == null || confirmed == false) return;

                              List<int> makerIds = selectedMakers
                                  .map((maker) => maker.id!)
                                  .toList();
                              BulkRequestResult result = await PartMakerRepository()
                                  .removePartMakers(makerIds);

                              String message = "";
                              if (result.successCount > 0) {
                                dataTableKey = UniqueKey();
                                selectedMaker = makerProvider.allMaker;
                                message =
                                    "${result.successCount}개의 제조사를 삭제하였습니다.\n";
                              }
                              if (result.failedCount > 0) {
                                message =
                                    "${result.successCount}개 삭제 완료\n${result.failedCount}개 삭제 실패!\n해당 제조사의 부품을 먼저 삭제해주세요.";
                              }

                              if (!context.mounted) return;
                              showDialog(
                                context: context,
                                builder: (context) =>
                                    ResultDialog(message: message),
                              );

                              selectedMakers.clear();
                              Provider.of<MakerProvider>(
                                context,
                                listen: false,
                              ).reloadMakers();
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
