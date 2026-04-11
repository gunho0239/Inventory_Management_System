import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_management/datatable_source/location_data.dart';
import 'package:inventory_management/enums/label_type.dart';
import 'package:inventory_management/models/location.dart';
import 'package:inventory_management/models/location_section.dart';
import 'package:inventory_management/providers/data_table_options_provider.dart';
import 'package:inventory_management/providers/section_provider.dart';
import 'package:inventory_management/repository/location_repository.dart';
import 'package:inventory_management/widgets/dialogs.dart';
import 'package:inventory_management/widgets/icon_label.dart';
import 'package:provider/provider.dart';

class LocationSelectDialog extends StatefulWidget {
  const LocationSelectDialog({super.key});

  @override
  State<LocationSelectDialog> createState() => _LocationSelectDialogState();
}

class _LocationSelectDialogState extends State<LocationSelectDialog> {
  final TextEditingController _numberFieldController = TextEditingController();
  final FocusNode _numberFieldFocusNode = FocusNode();
  final LocationRepository _locationRepo = LocationRepository();

  late LocationSection _selectedSection;
  final List<DataColumn> _columns = const [
    DataColumn(label: Text('구역')),
    DataColumn(label: Text('번호')),
  ];
  
  late LocationDataSource _dataSource;
  Key _dataTableKey = UniqueKey();
  
  List<Location> _inquiredLocations = [];
  Location? _selectedLocation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // 1. [개선] 메모리 누수 방지
  @override
  void dispose() {
    _numberFieldController.dispose();
    _numberFieldFocusNode.dispose();
    super.dispose();
  }

  // 2. [개선] DataSource 1회 초기화
  void _initializeData() {
    final sectionProvider = Provider.of<SectionProvider>(context, listen: false);
    _selectedSection = sectionProvider.allSection;

    _dataSource = LocationDataSource(
      locations: _inquiredLocations,
      selectedLocations: {},
      onSelectChanged: (location, selected) {
        setState(() {
          if (selected) {
            _selectedLocation = location;
            // DataSource 내부에 Set으로 관리되므로 업데이트
            _dataSource.selectedLocations = {location};
          } else {
            _selectedLocation = null;
            _dataSource.selectedLocations = {};
          }
        });
        _dataSource.updateSelected();
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      sectionProvider.reloadSections();
      _getLocations();
    });
  }

  // 3. [개선] 비동기 데이터 호출 및 mounted 체크
  Future<void> _getLocations() async {
    setState(() => _isLoading = true);

    final sectionProvider = Provider.of<SectionProvider>(context, listen: false);
    final bool isAllSection = _selectedSection == sectionProvider.allSection;
    final String numberText = _numberFieldController.text.trim();

    final result = await switch ((isAllSection, numberText.isEmpty)) {
      (true, true) => _locationRepo.getAllLocations(),
      (false, true) => _locationRepo.getLocationsBySection(_selectedSection.id!),
      _ => _locationRepo.getLocationsByFilter(
            isAllSection ? null : _selectedSection.id!,
            numberText.isEmpty ? null : int.parse(numberText),
          ),
    };

    if (!mounted) return;

    setState(() {
      _inquiredLocations = result;
      _selectedLocation = null;
      _isLoading = false;
      _dataTableKey = UniqueKey(); // 페이지네이션 1페이지로 리셋
      
      _dataSource.selectedLocations = {};
      _dataSource.updateData(_inquiredLocations);
    });
  }

  void _handleConfirm() {
    if (_selectedLocation != null) {
      Navigator.of(context).pop(_selectedLocation);
    } else {
      showDialog(
        context: context,
        builder: (context) => const ErrorDialog(message: '위치를 선택해주세요.'),
      );
    }
  }

  // 4. [개선] UI 코드 구조화
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('위치 선택', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 800, // 다이얼로그 크기 제한
        height: 600,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterPanel(),
            const SizedBox(width: 20),
            _buildDataTable(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _handleConfirm,
          child: const Text('확인'),
        ),
      ],
    );
  }

  Widget _buildFilterPanel() {
    final sectionProvider = Provider.of<SectionProvider>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 20,
        children: [
          DropdownMenu<LocationSection>(
            label: const IconLabel(labelType: LabelType.section),
            enableFilter: true,
            menuHeight: 400,
            width: 150,
            initialSelection: _selectedSection,
            onSelected: (section) {
              if (section != null) {
                _selectedSection = section;
                _getLocations();
              }
            },
            dropdownMenuEntries: sectionProvider.sectionsDropdownWithAll,
          ),
          SizedBox(
            width: 150,
            child: TextField(
              controller: _numberFieldController,
              focusNode: _numberFieldFocusNode,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                label: IconLabel(labelType: LabelType.number),
                hintText: "입력 후 엔터",
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) {
                _getLocations();
                FocusScope.of(context).requestFocus(_numberFieldFocusNode);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    final tableOptionsProvider = context.watch<DataTableOptionsProvider>();

    if (_isLoading) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }

    return Expanded(
      child: SingleChildScrollView(
        child: PaginatedDataTable(
          key: _dataTableKey,
          columns: _columns,
          source: _dataSource,
          rowsPerPage: tableOptionsProvider.rowsPerPage,
          availableRowsPerPage: tableOptionsProvider.availableRowsPerPage,
          showCheckboxColumn: true,
          onRowsPerPageChanged: (value) {
            if (value != null) {
              tableOptionsProvider.updateRowsPerPage(value);
            }
          },
        ),
      ),
    );
  }
}