import 'package:flutter/material.dart';
import 'package:inventory_management/api/api_response_entity.dart';
import 'package:inventory_management/datatable_source/location_data.dart';
import 'package:inventory_management/enums/inventory_menu.dart';
import 'package:inventory_management/enums/label_type.dart';
import 'package:inventory_management/models/location.dart';
import 'package:inventory_management/models/location_section.dart';
import 'package:inventory_management/providers/section_provider.dart';
import 'package:inventory_management/repository/location_repository.dart';
import 'package:inventory_management/screens/location_register_screen.dart';
import 'package:inventory_management/widgets/buttons.dart';
import 'package:inventory_management/widgets/dialogs.dart';
import 'package:inventory_management/widgets/icon_label.dart';
import 'package:inventory_management/widgets/title.dart';
import 'package:provider/provider.dart';

class LocationManagementScreen extends StatefulWidget {
  const LocationManagementScreen({super.key});

  @override
  State<LocationManagementScreen> createState() =>
      _LocationManagementScreenState();
}

class _LocationManagementScreenState extends State<LocationManagementScreen> {
  late LocationSection selectedSection;

  final List<DataColumn> columns = [
    DataColumn(label: Text('구역')),
    DataColumn(label: Text('번호')),
  ];
  late LocationDataSource _dataSource;
  Key dataTableKey = UniqueKey();
  List<Location> inquiredLocations = [];
  Set<Location> selectedLocations = {};

  @override
  void initState() {
    super.initState();
    final sectionProvider = Provider.of<SectionProvider>(context, listen: false);
    selectedSection = sectionProvider.allSection;
    sectionProvider.reloadSections();

    _dataSource = LocationDataSource(
      locations: inquiredLocations,
      selectedLocations: selectedLocations,
      onSelectChanged: (location, selected) {
        setState(() {
          if (selected) {
            selectedLocations.add(location);
          } else {
            selectedLocations.remove(location);
          }
        });
      },
    );

    getLocations();
  }

  void getLocations() async {
    LocationRepository locationRepo = LocationRepository();

    if (selectedSection == Provider.of<SectionProvider>(context, listen: false).allSection) {
      inquiredLocations = await locationRepo.getAllLocations();
    } else {
      inquiredLocations = await locationRepo.getLocationsBySection(
        selectedSection.id!,
      );
    }

    selectedLocations.clear();
    _dataSource.updateData(inquiredLocations);
  }

  @override
  Widget build(BuildContext context) {
    final sectionProvider = Provider.of<SectionProvider>(context);


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScreenTitle(menu: InventoryMenu.locationManagement),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 5.0,
                          horizontal: 10.0,
                        ),
                        child: DropdownMenu<LocationSection>(
                          label: IconLabel(labelType: LabelType.section),
                          enableFilter: true,
                          menuHeight: 400,
                          onSelected: (section) {
                            if (section != null) {
                              selectedSection = section;
                              getLocations();
                              dataTableKey = UniqueKey();
                            }
                          },
                          dropdownMenuEntries: sectionProvider.sectionsDropdownWithAll,
                        ),
                      ),
                      SizedBox(width: 20),
                      RegisterPageButton(InventoryMenu.locationRegister,
                        onPressed: () async {
                          final refresh = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LocationRegisterScreen(),
                            ),
                          );
                      
                          if (refresh == true) {
                            dataTableKey = UniqueKey();
                            getLocations();
                          }
                        }
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                                rowsPerPage: 6,
                                showCheckboxColumn: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                      DeleteButton(
                        onPressed: () async {
                          if (selectedLocations.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('삭제할 위치를 선택해주세요.')),
                            );
                            return;
                          }
                          final confirmed = await showDialog(
                            context: context,
                            builder: (context) => ConfirmDialog(
                              message: "선택한 위치를 삭제하시겠습니까?",
                            ),
                          );
    
                          if (confirmed == null || confirmed == false) return;
                          
                          List<int> locationIds = selectedLocations
                              .map((loc) => loc.id!)
                              .toList();
                          BulkRequestResult result = await LocationRepository()
                              .removeLocations(locationIds);
    
                          String message = "";
                          if (result.successCount > 0) {
                            dataTableKey = UniqueKey();
                            message =
                                "${result.successCount}개의 위치를 삭제하였습니다.\n";
                          }
                          if (result.failedCount > 0) {
                            message =
                                "${result.successCount}개 삭제 완료\n${result.failedCount}개 삭제 실패!\n해당 위치의 재고를 먼저 이동시켜주세요.";
                          }
    
                          if (!context.mounted) return;
                          showDialog(
                            context: context,
                            builder: (context) => ResultDialog(
                              message: message,
                            ),
                          );
    
                          selectedLocations.clear();
                          getLocations();
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
