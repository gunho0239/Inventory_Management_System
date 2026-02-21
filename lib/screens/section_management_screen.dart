import 'package:flutter/material.dart';
import 'package:inventory_management/dto/bulk_request_result.dart';
import 'package:inventory_management/datatable_source/location_section_data.dart';
import 'package:inventory_management/enums/inventory_menu.dart';
import 'package:inventory_management/models/location_section.dart';
import 'package:inventory_management/providers/data_table_options_provider.dart';
import 'package:inventory_management/providers/section_provider.dart';
import 'package:inventory_management/repository/location_section_repository.dart';
import 'package:inventory_management/widgets/buttons.dart';
import 'package:inventory_management/widgets/dialogs.dart';
import 'package:inventory_management/widgets/title.dart';
import 'package:provider/provider.dart';

class SectionManagementScreen extends StatefulWidget {
  const SectionManagementScreen({super.key});

  @override
  State<SectionManagementScreen> createState() =>
      _SectionManagementScreenState();
}

class _SectionManagementScreenState extends State<SectionManagementScreen> {
  late LocationSection selectedSection;

  final List<DataColumn> columns = [DataColumn(label: Text('구역'))];

  Set<LocationSection> selectedSections = {};
  late LocationSectionDataSource _dataSource;
  Key dataTableKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    final sectionProvider = Provider.of<SectionProvider>(context, listen: false);
    selectedSection = sectionProvider.allSection;
    sectionProvider.reloadSections();
  }

  @override
  Widget build(BuildContext context) {
    final sectionProvider = Provider.of<SectionProvider>(context);
    final tableOptionsProvider = context.watch<DataTableOptionsProvider>();

    _dataSource = LocationSectionDataSource(
      sections: (selectedSection == sectionProvider.allSection)
          ? sectionProvider.sections
          : [selectedSection],
      selectedSections: selectedSections,
      onSelectChanged: (section, selected) {
        setState(() {
          if (selected) {
            selectedSections.add(section);
          } else {
            selectedSections.remove(section);
          }
        });
      },
    );

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenTitle(menu: InventoryMenu.sectionManagement),
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
                            sectionProvider.reloadSections();
                          });
                        },
                      ),
                      RegisterPageButton(InventoryMenu.sectionRegister,),
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
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                          child: DropdownMenu<LocationSection>(
                            label: Text("구역"),
                            enableFilter: true,
                            menuHeight: 400,
                            initialSelection: selectedSection,
                            onSelected: (section) {
                              if (section != null) {
                                selectedSection = section;
                                setState(() {});
                              }
                            },
                            dropdownMenuEntries: sectionProvider.sectionsDropdownWithAll,
                          ),
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
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: DeleteButton(
                            onPressed: () async {
                              if (selectedSections.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('삭제할 구역을 선택해주세요.')),
                                );
                                return;
                              }
                              final confirmed = await showDialog(
                                context: context,
                                builder: (context) =>
                                    ConfirmDialog(message: "선택한 구역을 삭제하시겠습니까?"),
                              );

                              if (confirmed == null || confirmed == false) return;

                              List<int> sectionIds = selectedSections
                                  .map((sec) => sec.id!)
                                  .toList();
                              BulkRequestResult result =
                                  await LocationSectionRepository()
                                      .removeLocationSections(sectionIds);

                              String message = "";
                              if (result.successCount > 0) {
                                dataTableKey = UniqueKey();
                                selectedSection = sectionProvider.allSection;
                                message =
                                    "${result.successCount}개의 구역을 삭제하였습니다.\n";
                              }
                              if (result.failedCount > 0) {
                                message =
                                    "${result.successCount}개 삭제 완료\n${result.failedCount}개 삭제 실패!\n해당 구역의 위치를 먼저 삭제해주세요.";
                              }

                              if (!context.mounted) return;
                              showDialog(
                                context: context,
                                builder: (context) =>
                                    ResultDialog(message: message),
                              );

                              selectedSections.clear();
                              Provider.of<SectionProvider>(
                                context,
                                listen: false,
                              ).reloadSections();
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
