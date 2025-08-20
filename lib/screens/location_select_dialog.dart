import 'package:flutter/material.dart';
import 'package:inventory_management/datatable_source/location_data.dart';
import 'package:inventory_management/models/location.dart';
import 'package:inventory_management/models/location_section.dart';
import 'package:inventory_management/models/stock.dart';
import 'package:inventory_management/providers/section_provider.dart';
import 'package:inventory_management/repository/location_repository.dart';
import 'package:inventory_management/widgets/dialogs.dart';
import 'package:provider/provider.dart';

class LocationSelectDialog extends StatefulWidget {
  final Stock? stock;

  const LocationSelectDialog({super.key, required this.stock});

  @override
  State<LocationSelectDialog> createState() => _LocationSelectDialogState();
}

class _LocationSelectDialogState extends State<LocationSelectDialog> {
  late LocationSection selectedSection;

  final List<DataColumn> columns = [
    DataColumn(label: Text('구역')),
    DataColumn(label: Text('번호')),
  ];
  late LocationDataSource _dataSource;
  Key dataTableKey = UniqueKey();
  List<Location> inquiredLocations = [];
  Location? selectedLocation;

  @override
  void initState() {
    super.initState();
    final sectionProvider = Provider.of<SectionProvider>(context, listen: false);
    selectedSection = sectionProvider.allSection;
    sectionProvider.reloadSections();
    // getLocations();
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

    selectedLocation = null;
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    final sectionProvider = Provider.of<SectionProvider>(context);

    _dataSource = LocationDataSource(
      locations: inquiredLocations,
      selectedLocations: (selectedLocation == null) ? {} : {selectedLocation!},
      onSelectChanged: (location, selected) {
        setState(() {
          if (selected) {
            selectedLocation = location;
          } else {
            selectedLocation = null;
          }
        });
      },
    );

    return AlertDialog(
      title: Text('위치 선택'),
      content: Row(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: DropdownMenu<LocationSection>(
              label: Text("구역"),
              enableFilter: true,
              menuHeight: 400,
              onSelected: (section) {
                selectedSection = section!;
                getLocations();
                dataTableKey = UniqueKey();
              },
              dropdownMenuEntries: sectionProvider.sectionsDropdownWithAll,
            ),
          ),
          Expanded(
            child: SizedBox(
              width: 500,
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
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            if (selectedLocation != null) {
              Stock newStock = Stock(
                part: widget.stock?.part,
                quantity: widget.stock?.quantity,
                location: selectedLocation!,
              );

              Navigator.of(context).pop(newStock);
            }
            else {
              showDialog(
                context: context,
                builder: (context) => ErrorDialog(
                  message: '위치를 선택해주세요.',
                ),
              );
            }
          },
          child: Text('확인'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('취소'),
        ),
      ],
    );
  }
}