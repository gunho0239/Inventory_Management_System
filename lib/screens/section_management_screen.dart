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
  State<SectionManagementScreen> createState() => _SectionManagementScreenState();
}

class _SectionManagementScreenState extends State<SectionManagementScreen> {
  LocationSection? _selectedSection;
  final Set<LocationSection> _selectedSections = {};
  
  late LocationSectionDataSource _dataSource;
  Key _dataTableKey = UniqueKey();

  final List<DataColumn> _columns = const [
    DataColumn(label: Text('구역')),
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // 1. [개선] 매 빌드마다 생성되던 DataSource를 1회만 초기화하여 성능 극대화
    _dataSource = LocationSectionDataSource(
      sections: [], // 초기엔 빈 배열, build 시점에 업데이트
      selectedSections: _selectedSections,
      onSelectChanged: (section, selected) {
        setState(() {
          if (selected) {
            _selectedSections.add(section);
          } else {
            _selectedSections.remove(section);
          }
        });
      },
    );

    // 프레임 렌더링 직후 Provider 데이터를 불러옵니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sectionProvider = Provider.of<SectionProvider>(context, listen: false);
      _selectedSection = sectionProvider.allSection;
      sectionProvider.reloadSections();
    });
  }

  // 스낵바 공통 함수
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // 2. [개선] 거대한 삭제 비즈니스 로직을 별도 메서드로 추출
  Future<void> _handleDeleteSelected() async {
    if (_selectedSections.isEmpty) {
      _showSnackBar('삭제할 구역을 선택해주세요.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmDialog(message: "선택한 구역을 삭제하시겠습니까?"),
    );

    if (!mounted || confirmed != true) return;

    List<int> sectionIds = _selectedSections.map((sec) => sec.id!).toList();
    BulkRequestResult result = await LocationSectionRepository().removeLocationSections(sectionIds);

    if (!mounted) return;

    String message = "";
    if (result.successCount > 0) {
      _dataTableKey = UniqueKey();
      
      // 필터를 '전체보기'로 초기화
      final sectionProvider = Provider.of<SectionProvider>(context, listen: false);
      _selectedSection = sectionProvider.allSection; 
      
      message = "${result.successCount}개의 구역을 삭제하였습니다.\n";
    }
    
    if (result.failedCount > 0) {
      message += "${result.successCount}개 삭제 완료\n${result.failedCount}개 삭제 실패!\n해당 구역의 위치를 먼저 삭제해주세요.";
    }

    _showSnackBar(message);

    if (result.successCount > 0) {
      _selectedSections.clear();
      Provider.of<SectionProvider>(context, listen: false).reloadSections();
    }
  }

  // 3. [개선] UI 렌더링을 역할별 위젯 메서드로 분할
  @override
  Widget build(BuildContext context) {
    final sectionProvider = Provider.of<SectionProvider>(context);

    // Provider의 데이터를 바탕으로 현재 표에 보여줄 리스트를 결정
    final displaySections = (_selectedSection == sectionProvider.allSection || _selectedSection == null)
        ? sectionProvider.sections
        : [_selectedSection!];

    // [중요] DataSource 객체를 새로 만들지 않고 데이터만 덮어씌움
    _dataSource.updateData(displaySections); 

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScreenTitle(menu: InventoryMenu.sectionManagement),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopButtonsRow(sectionProvider),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilterDropdown(sectionProvider),
                        _buildDataTable(),
                        _buildActionPanel(),
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

  Widget _buildTopButtonsRow(SectionProvider sectionProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      child: Row(
        spacing: 20,
        children: [
          const GoFirstButton(),
          const GoBackButton(),
          RefreshButton(
            onPressed: () {
              sectionProvider.reloadSections(); // Provider 상태만 갱신 (setState 불필요)
            },
          ),
          const RegisterPageButton(InventoryMenu.sectionRegister),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(SectionProvider sectionProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
      child: DropdownMenu<LocationSection>(
        label: const Text("구역"),
        enableFilter: true,
        menuHeight: 400,
        initialSelection: _selectedSection,
        onSelected: (section) {
          if (section != null) {
            setState(() => _selectedSection = section);
          }
        },
        dropdownMenuEntries: sectionProvider.sectionsDropdownWithAll,
      ),
    );
  }

  Widget _buildDataTable() {
    final tableOptionsProvider = context.watch<DataTableOptionsProvider>();

    return Flexible(
      child: SizedBox(
        width: 500,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: SingleChildScrollView(
            child: PaginatedDataTable(
              key: _dataTableKey,
              columns: _columns,
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
    );
  }

  Widget _buildActionPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DeleteButton(
        onPressed: _handleDeleteSelected,
      ),
    );
  }
}