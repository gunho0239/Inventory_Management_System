import 'package:flutter/material.dart' hide Title;
import 'package:inventory_management/api/api_client.dart';
import 'package:inventory_management/constants/default_dropdownmenuitem.dart';
import 'package:inventory_management/datatable_source/location_data.dart';
import 'package:inventory_management/main.dart';
import 'package:inventory_management/models/location.dart';
import 'package:inventory_management/models/location_section.dart';
import 'package:inventory_management/providers/section_provider.dart';
import 'package:inventory_management/repository/location_repository.dart';
import 'package:inventory_management/screens/location_register_screen.dart';
import 'package:inventory_management/widgets/buttons.dart';
import 'package:inventory_management/widgets/dialogs.dart';
import 'package:inventory_management/widgets/title.dart';
import 'package:provider/provider.dart';

class LocationManagementScreen extends StatefulWidget {
  const LocationManagementScreen({super.key});

  @override
  State<LocationManagementScreen> createState() =>
      _LocationManagementScreenState();
}

class _LocationManagementScreenState extends State<LocationManagementScreen> {
  LocationSection allSection = LocationSection(id: defaultId, section: defaultLabel);
  late LocationSection selectedSection;
  List<LocationSection>? sections;
  List<DropdownMenuItem<LocationSection>> sectionsDropdown = [];

  final List<DataColumn> columns = [
    DataColumn(label: Text('구역')),
    DataColumn(label: Text('번호')),
  ];

  List<Location> inquiredLocations = [];
  Set<Location> selectedLocations = {};
  late LocationDataSource _dataSource;
  Key dataTableKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    selectedSection = allSection;
    Provider.of<SectionProvider>(context, listen: false).reloadSections();
  }

  void getLocation() async {
    LocationRepository locationRepo = LocationRepository();

    if (selectedSection == allSection) {
      inquiredLocations = await locationRepo.getAllLocations();
    } else {
      inquiredLocations = await locationRepo.getLocationsBySection(
        selectedSection.id!,
      );
    }

    selectedLocations.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final sectionProvider = Provider.of<SectionProvider>(context);

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

    return Expanded(
      child: Column(
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
                children: [
                  Row(
                    children: [
                      Text("구역 :"),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 5.0,
                          horizontal: 10.0,
                        ),
                        child: DropdownMenu<LocationSection>(
                          menuHeight: 400,
                          initialSelection: selectedSection,
                          onSelected: (section) {
                            selectedSection = section!;
                          },
                          dropdownMenuEntries: [
                            DropdownMenuEntry<LocationSection>(
                              value: allSection,
                              label: allSection.section!,
                            ),
                            ...sectionProvider.sections.map(
                              (section) => DropdownMenuEntry<LocationSection>(
                                value: section,
                                label: section.section!,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          getLocation();
                          dataTableKey = UniqueKey(); 
                        },
                        child: Icon(Icons.search, size: 30),
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
                              builder: (context) => LocationRegisterScreen(),
                            ),
                          );
                        },
                        child: Row(
                          spacing: 5,
                          children: [
                            Icon(Icons.add, size: 30),
                            Text('새로운 위치', style: TextStyle(fontSize: 18)),
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

                            if (!confirmed) return;
                            List<int> locationIds = selectedLocations
                                .map((loc) => loc.id!)
                                .toList();
                            DeleteResult result = await LocationRepository()
                                .removeLocations(locationIds);

                            String message = "";
                            if (result.successCount > 0) {
                              message =
                                  "${result.successCount}개의 위치를 삭제하였습니다.\n";
                            }
                            if (result.failedCount > 0) {
                              message =
                                  "${result.successCount}개 삭제 완료\n${result.failedCount}개 삭제 실패!\n해당 위치의 재고를 먼저 이동시켜주세요.";
                            }

                            if (!mounted) return;
                            showDialog(
                              context: context,
                              builder: (context) => ResultDialog(
                                message: message,
                              ),
                            );

                            selectedLocations.clear();
                            getLocation();
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
