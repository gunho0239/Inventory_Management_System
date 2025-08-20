import 'package:flutter/material.dart';
import 'package:inventory_management/datatable_source/location_data.dart';
import 'package:inventory_management/main.dart';
import 'package:inventory_management/models/location.dart';
import 'package:inventory_management/models/location_section.dart';
import 'package:inventory_management/providers/section_provider.dart';
import 'package:inventory_management/repository/location_repository.dart';
import 'package:inventory_management/screens/section_management_screen.dart';
import 'package:inventory_management/style/style.dart';
import 'package:inventory_management/widgets/buttons.dart';
import 'package:inventory_management/widgets/dialogs.dart';
import 'package:inventory_management/widgets/title.dart';
import 'package:provider/provider.dart';

class LocationRegisterScreen extends StatefulWidget {
  const LocationRegisterScreen({super.key});

  @override
  State<LocationRegisterScreen> createState() => _LocationRegisterScreenState();
}

class _LocationRegisterScreenState extends State<LocationRegisterScreen> {
  bool refresh = false;
  LocationSection? selectedSection;
  TextEditingController startNumberController = TextEditingController();
  TextEditingController endNumberController = TextEditingController();

  final List<DataColumn> columns = [
    DataColumn(label: Text('구역')),
    DataColumn(label: Text('번호')),
  ];
  late LocationDataSource _dataSource;
  Set<Location> locations = {};
  Set<Location> selectedLocations = {};

  void addLocation(
    LocationSection section,
    String startNumber,
    String endNumber,
  ) {
    int start = int.tryParse(startNumber) ?? 0;
    int end = int.tryParse(endNumber) ?? 0;

    for (int number = start; number <= end; number++) {
      locations.add(
        Location(
          section: LocationSection(id: section.id, section: section.section),
          number: number,
        ),
      );
    }
  }

  List<DropdownMenuItem<LocationSection>> sectionDropdownItems(
    List<LocationSection> sections,
  ) {
    return sections
        .map(
          (section) => DropdownMenuItem<LocationSection>(
            value: section,
            child: Text(section.section!),
          ),
        )
        .toList();
  }

  Future<int> registerAllLocations() async {
    if (locations.isEmpty) return 0;

    List<Location> allLocations = locations.toList();
    allLocations.sort((a, b) {
      if (a.section.id != b.section.id) {
        return a.section.id!.compareTo(b.section.id!);
      }
      return a.number.compareTo(b.number);
    });
    List<Location> registeredLocations = await LocationRepository()
        .addLocations(allLocations);

    return registeredLocations.length;
  }

  @override
  Widget build(BuildContext context) {
    final sectionProvider = Provider.of<SectionProvider>(context);

    _dataSource = LocationDataSource(
      locations: locations.toList(),
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

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenTitle(menu: InventoryMenu.locationRegister),
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
                      GoBackButton(refresh: refresh),
                      ElevatedButton(
                        style: AppButtonStyle.newPage,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SectionManagementScreen(),
                            ),
                          );
                        },
                        child: Text('구역관리', style: TextStyle(fontSize: 18)),
                      ),
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
                        SizedBox(width: 10),
                        Column(
                          spacing: 20,
                          // crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownMenu<LocationSection>(
                              label: Text("구역"),
                              menuHeight: 400,
                              initialSelection: selectedSection,
                              onSelected: (section) {
                                setState(() {
                                  selectedSection = section;
                                });
                              },
                              dropdownMenuEntries: sectionProvider
                                  .sections
                                  .map(
                                    (section) =>
                                        DropdownMenuEntry<
                                          LocationSection
                                        >(
                                          value: section,
                                          label: section.section!,
                                        ),
                                  )
                                  .toList(),
                            ),
                            SizedBox(
                              width: 130,
                              child: TextField(
                                controller: startNumberController,
                                decoration: InputDecoration(
                                  labelText: "시작 번호",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 130,
                              child: TextField(
                                controller: endNumberController,
                                decoration: InputDecoration(
                                  labelText: "종료 번호",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (selectedSection == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('구역을 선택해주세요.')),
                                  );
                                  return;
                                }
                                if (startNumberController.text.isEmpty ||
                                    endNumberController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('번호를 입력해주세요.')),
                                  );
                                  return;
                                }
                                if (int.tryParse(startNumberController.text) ==
                                        null ||
                                    int.tryParse(endNumberController.text) ==
                                        null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('숫자를 입력해주세요.')),
                                  );
                                  return;
                                }
                                if (int.parse(startNumberController.text) < 0 ||
                                    int.parse(endNumberController.text) < 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('번호는 0 이상의 숫자를 입력해주세요.'),
                                    ),
                                  );
                                  return;
                                }
                                addLocation(
                                  selectedSection!,
                                  startNumberController.text,
                                  endNumberController.text,
                                );
                                startNumberController.clear();
                                endNumberController.clear();
                                setState(() {});
                              },
                              child: Icon(Icons.add, size: 30),
                            ),
                          ],
                        ),
                        SizedBox(width: 50),
                        SizedBox(
                          width: 500,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                            ),
                            child: SingleChildScrollView(
                              child: PaginatedDataTable(
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
                                if (locations.isEmpty) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('알림'),
                                      content: Text('등록할 위치가 없습니다.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: Text('확인'),
                                        ),
                                      ],
                                    ),
                                  );
                                  return;
                                }

                                final confirmed = await showDialog(
                                  context: context,
                                  builder: (context) =>
                                      ConfirmDialog(message: "전체등록 하시겠습니까?"),
                                );

                                if (confirmed == null || confirmed == false) return;

                                int count = await registerAllLocations();

                                if (!mounted) return;

                                if (count > 0) {
                                  refresh = true;
                                  locations.clear();
                                  selectedLocations.clear();
                                  startNumberController.clear();
                                  endNumberController.clear();
                                  selectedSection = null;
                                  setState(() {});
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('알림'),
                                      content: Text('$count개의 위치가 등록되었습니다.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: Text('확인'),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('오류'),
                                      content: Text('이미 등록된 위치입니다.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: Text('확인'),
                                        ),
                                      ],
                                    ),
                                  );
                                  return;
                                }
                              },
                            ),
                            SizedBox(height: 10),
                            DeleteButton(
                              onPressed: () {
                                if (selectedLocations.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('삭제할 위치를 선택해주세요.')),
                                  );
                                  return;
                                }
                                setState(() {
                                  locations.removeAll(selectedLocations);
                                  selectedLocations.clear();
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
