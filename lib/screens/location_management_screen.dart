import 'package:flutter/material.dart';
import 'package:inventory_management/datatable_source/location_data.dart';
import 'package:inventory_management/dto/bulk_request_result.dart';
import 'package:inventory_management/enums/inventory_menu.dart';
import 'package:inventory_management/enums/label_type.dart';
import 'package:inventory_management/models/location.dart';
import 'package:inventory_management/models/location_section.dart';
import 'package:inventory_management/providers/data_table_options_provider.dart';
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
  State<LocationManagementScreen> createState() => _LocationManagementScreenState();
}

class _LocationManagementScreenState extends State<LocationManagementScreen> {
  late LocationSection _selectedSection;
  final LocationRepository _locationRepo = LocationRepository();
  
  late LocationDataSource _dataSource;
  Key _dataTableKey = UniqueKey();
  
  List<Location> _inquiredLocations = [];
  final Set<Location> _selectedLocations = {};
  bool _isLoading = false;

  final List<DataColumn> _columns = const [
    DataColumn(label: Text('구역')),
    DataColumn(label: Text('번호')),
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final sectionProvider = Provider.of<SectionProvider>(context, listen: false);
    _selectedSection = sectionProvider.allSection;

    // 1. [개선] DataSource를 1회만 초기화
    _dataSource = LocationDataSource(
      locations: _inquiredLocations,
      selectedLocations: _selectedLocations,
      onSelectChanged: (location, selected) {
        setState(() {
          if (selected) {
            _selectedLocations.add(location);
          } else {
            _selectedLocations.remove(location);
          }
        });
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      sectionProvider.reloadSections();
      _getLocations();
    });
  }

  // 2. [개선] 로딩 상태 추가 및 비동기 로직 정돈
  Future<void> _getLocations() async {
    setState(() => _isLoading = true);
    
    final sectionProvider = Provider.of<SectionProvider>(context, listen: false);
    
    List<Location> result;
    if (_selectedSection == sectionProvider.allSection) {
      result = await _locationRepo.getAllLocations();
    } else {
      result = await _locationRepo.getLocationsBySection(_selectedSection.id!);
    }

    if (!mounted) return;

    setState(() {
      _inquiredLocations = result;
      _selectedLocations.clear();
      _isLoading = false;
    });
    
    _dataSource.updateData(_inquiredLocations);
  }

  // 스낵바 공통 함수
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // 3. [개선] 비즈니스 로직(삭제, 이동) 분리
  Future<void> _handleDelete() async {
    if (_selectedLocations.isEmpty) {
      _showSnackBar('삭제할 위치를 선택해주세요.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmDialog(message: "선택한 위치를 삭제하시겠습니까?"),
    );

    if (!mounted || confirmed != true) return;

    List<int> locationIds = _selectedLocations.map((loc) => loc.id!).toList();
    BulkRequestResult result = await _locationRepo.removeLocations(locationIds);

    if (!mounted) return;

    String message = "";
    if (result.successCount > 0) {
      _dataTableKey = UniqueKey();
      message = "${result.successCount}개의 위치를 삭제하였습니다.\n";
    }
    if (result.failedCount > 0) {
      message += "${result.successCount}개 삭제 완료\n${result.failedCount}개 삭제 실패!\n해당 위치의 재고를 먼저 이동시켜주세요.";
    }

    _showSnackBar(message);
    _getLocations();
  }

  Future<void> _handleRegister() async {
    final refresh = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LocationRegisterScreen()),
    );

    if (!mounted) return;

    if (refresh == true) {
      _dataTableKey = UniqueKey();
      _getLocations();
    }
  }

  // 4. [개선] UI 코드 구조화
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ScreenTitle(menu: InventoryMenu.locationManagement),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilterBar(),
                const SizedBox(height: 10),
                Expanded(
                  child: SizedBox(
                    width: 800,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(child: _buildDataTable()),
                        _buildActionPanel(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    final sectionProvider = Provider.of<SectionProvider>(context);
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
            child: DropdownMenu<LocationSection>(
              label: const IconLabel(labelType: LabelType.section),
              enableFilter: true,
              menuHeight: 400,
              initialSelection: _selectedSection,
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 0.8),
                ),
              ),
              onSelected: (section) {
                if (section != null) {
                  setState(() => _selectedSection = section);
                  _getLocations();
                  _dataTableKey = UniqueKey();
                }
              },
              dropdownMenuEntries: sectionProvider.sectionsDropdownWithAll,
            ),
          ),
          const SizedBox(width: 20),
          RegisterPageButton(
            InventoryMenu.locationRegister,
            onPressed: _handleRegister,
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    final tableOptionsProvider = context.watch<DataTableOptionsProvider>();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: SingleChildScrollView(
        child: PaginatedDataTable(
          key: _dataTableKey,
          columns: _columns,
          source: _dataSource,
          rowsPerPage: tableOptionsProvider.rowsPerPage,
          availableRowsPerPage: tableOptionsProvider.availableRowsPerPage,
          showCheckboxColumn: true,
          showFirstLastButtons: true,
          onRowsPerPageChanged: (value) {
            if (value != null) {
              tableOptionsProvider.updateRowsPerPage(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildActionPanel() {
    return DeleteButton(onPressed: _handleDelete);
  }
}