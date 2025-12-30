import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_management/constants/columns.dart';
import 'package:inventory_management/datatable_source/location_data.dart';
import 'package:inventory_management/enums/label_type.dart';
import 'package:inventory_management/models/location.dart';
import 'package:inventory_management/models/location_section.dart';
import 'package:inventory_management/providers/section_provider.dart';
import 'package:inventory_management/repository/location_repository.dart';
import 'package:inventory_management/widgets/dialogs.dart';
import 'package:inventory_management/widgets/icon_label.dart';
import 'package:provider/provider.dart';

class LocationSelectWithConditionDialog extends StatefulWidget {
  final LocationSection? selectedSection;

  const LocationSelectWithConditionDialog({super.key, this.selectedSection});

  @override
  State<LocationSelectWithConditionDialog> createState() => _LocationSelectWithConditionDialogState();
}

class _LocationSelectWithConditionDialogState extends State<LocationSelectWithConditionDialog> {
  final TextEditingController _numberFieldController = TextEditingController();
  final FocusNode _numberFieldFocusNode = FocusNode();
  late LocationSection _selectedSection;

  final List<DataColumn> _columns = [
    DataColumn(label: Text(section)),
    DataColumn(label: Text(number)),
  ];
  late LocationDataSource _dataSource;
  Key _dataTableKey = UniqueKey();
  List<Location> _inquiredLocations = [];
  Location? _selectedLocation;

  @override
  void initState() {
    super.initState();
    final sectionProvider = Provider.of<SectionProvider>(context, listen: false);
    
    if (widget.selectedSection != null) {
      _selectedSection = widget.selectedSection!;
    } else {
      _selectedSection = sectionProvider.allSection;
    }
    sectionProvider.reloadSections();
    getLocations();
  }

  void getLocations() async {
    LocationRepository locationRepo = LocationRepository();
    final sectionProvider = Provider.of<SectionProvider>(context, listen: false);

    final bool isAllSection = _selectedSection == sectionProvider.allSection;
    final String numberText = _numberFieldController.text.trim();

    _inquiredLocations = await switch ((isAllSection, numberText.isEmpty)) {
      (true, true) => locationRepo.getAllLocations(),
      (false, true) => locationRepo.getLocationsBySection(_selectedSection.id!),
      _ => locationRepo.getLocationsByFilter(
              isAllSection ? null : _selectedSection.id!,
              numberText.isEmpty ? null : int.parse(numberText),
            ),
    };

    _selectedLocation = null;
    _dataTableKey = UniqueKey();
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    final sectionProvider = Provider.of<SectionProvider>(context);

    _dataSource = LocationDataSource(
      locations: _inquiredLocations,
      selectedLocations: (_selectedLocation == null) ? {} : {_selectedLocation!},
      onSelectChanged: (location, selected) {
        setState(() {
          if (selected) {
            _selectedLocation = location;
          } else {
            _selectedLocation = null;
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                DropdownMenu<LocationSection>(
                  label: IconLabel(labelType: LabelType.section),
                  enableFilter: true,
                  menuHeight: 400,
                  width: 150,
                  onSelected: (section) {
                    if (section != null) {
                      _selectedSection = section;
                      getLocations();
                    }
                  },
                  dropdownMenuEntries: sectionProvider.sectionsDropdownWithAll,
                ),
                SizedBox(
                  width: 150,
                  child: TextField(
                    controller: _numberFieldController,
                    focusNode: _numberFieldFocusNode,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      label: IconLabel(labelType: LabelType.number),
                      hintText: "입력 후 엔터",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (locationNumber) {
                      getLocations();
                      FocusScope.of(context).requestFocus(_numberFieldFocusNode);
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: PaginatedDataTable(
                  key: _dataTableKey,
                  columns: _columns,
                  source: _dataSource,
                  rowsPerPage: 6,
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
            if (_selectedLocation != null) {
              Navigator.of(context).pop(_selectedLocation);
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