import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_management/constants/columns.dart';
import 'package:inventory_management/datatable_source/location_data.dart';
import 'package:inventory_management/enums/label_type.dart';
import 'package:inventory_management/models/location.dart';
import 'package:inventory_management/models/location_section.dart';
import 'package:inventory_management/providers/data_table_options_provider.dart';
import 'package:inventory_management/repository/location_repository.dart';
import 'package:inventory_management/widgets/dialogs.dart';
import 'package:inventory_management/widgets/icon_label.dart';
import 'package:provider/provider.dart';

class LocationSelectWithSectionDialog extends StatefulWidget {
  final LocationSection section;

  const LocationSelectWithSectionDialog({super.key, required this.section});

  @override
  State<LocationSelectWithSectionDialog> createState() => _LocationSelectWithSectionDialogState();
}

class _LocationSelectWithSectionDialogState extends State<LocationSelectWithSectionDialog> {
  final TextEditingController _numberFieldController = TextEditingController();
  final FocusNode _numberFieldFocusNode = FocusNode();
  final LocationRepository _locationRepo = LocationRepository();

  late LocationSection _selectedSection;

  final List<DataColumn> _columns = const [
    DataColumn(label: Text(section)),
    DataColumn(label: Text(number)),
  ];

  late LocationDataSource _dataSource;
  Key _dataTableKey = UniqueKey();
  
  List<Location> _inquiredLocations = [];
  Location? _selectedLocation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedSection = widget.section;
    _initializeData();
  }

  // 1. [개선] 메모리 누수 방지
  @override
  void dispose() {
    _numberFieldController.dispose();
    _numberFieldFocusNode.dispose();
    super.dispose();
  }

  // 2. [개선] DataSource 1회 초기화 (렌더링 최적화)
  void _initializeData() {
    _dataSource = LocationDataSource(
      locations: _inquiredLocations,
      selectedLocations: {},
      onSelectChanged: (location, selected) {
        setState(() {
          if (selected) {
            _selectedLocation = location;
            _dataSource.selectedLocations = {location};
          } else {
            _selectedLocation = null;
            _dataSource.selectedLocations = {};
          }
          _dataSource.updateSelected(); // UI의 체크박스 상태만 업데이트
        });
      },
    );

    // 프레임이 그려진 직후 데이터를 호출합니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getLocations();
    });
  }

  // 3. [개선] 비동기 데이터 로딩 및 mounted 안전성 확보
  Future<void> _getLocations() async {
    setState(() => _isLoading = true);

    final String numberText = _numberFieldController.text.trim();

    final result = await switch (numberText.isEmpty) {
      true => _locationRepo.getLocationsBySection(_selectedSection.id!),
      false => _locationRepo.getLocationsByFilter(
          _selectedSection.id!,
          int.parse(numberText),
        ),
    };

    if (!mounted) return;

    setState(() {
      _inquiredLocations = result;
      _selectedLocation = null;
      _isLoading = false;
      _dataTableKey = UniqueKey(); // 페이지네이션 초기화

      _dataSource.selectedLocations = {};
      _dataSource.updateData(_inquiredLocations); // 표 데이터 갱신
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

  // 4. [개선] UI 코드 구조화 및 안정성 확보 (SizedBox 고정)
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${_selectedSection.section} 구역 위치 선택', style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 800, // 다이얼로그 오버플로우 방지
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: SizedBox(
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