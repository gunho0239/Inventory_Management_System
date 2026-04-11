import 'package:flutter/material.dart';
import 'package:inventory_management/dto/bulk_request_result.dart';
import 'package:inventory_management/datatable_source/part_unit_data.dart';
import 'package:inventory_management/enums/inventory_menu.dart';
import 'package:inventory_management/models/part_unit.dart';
import 'package:inventory_management/providers/data_table_options_provider.dart';
import 'package:inventory_management/providers/unit_provider.dart';
import 'package:inventory_management/repository/part_unit_repository.dart';
import 'package:inventory_management/widgets/buttons.dart';
import 'package:inventory_management/widgets/dialogs.dart';
import 'package:inventory_management/widgets/title.dart';
import 'package:provider/provider.dart';

class UnitManagementScreen extends StatefulWidget {
  const UnitManagementScreen({super.key});

  @override
  State<UnitManagementScreen> createState() => _UnitManagementScreenState();
}

class _UnitManagementScreenState extends State<UnitManagementScreen> {
  PartUnit? _selectedUnit;
  final Set<PartUnit> _selectedUnits = {};
  
  late PartUnitDataSource _dataSource;
  Key _dataTableKey = UniqueKey();

  final List<DataColumn> _columns = const [
    DataColumn(label: Text('단위')),
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // 1. [개선] DataSource를 단 1번만 초기화합니다. (매 빌드마다 재생성 방지)
    _dataSource = PartUnitDataSource(
      units: [], // 초기엔 빈 배열, build 시점에 데이터 업데이트
      selectedUnits: _selectedUnits,
      onSelectChanged: (unit, selected) {
        setState(() {
          if (selected) {
            _selectedUnits.add(unit);
          } else {
            _selectedUnits.remove(unit);
          }
        });
      },
    );

    // 프레임 렌더링 직후 Provider 데이터를 불러옵니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final unitProvider = Provider.of<UnitProvider>(context, listen: false);
      _selectedUnit = unitProvider.allUnit;
      unitProvider.reloadUnits();
    });
  }

  // 스낵바 공통 함수
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // 2. [개선] 삭제 비즈니스 로직 별도 추출 및 안전성(mounted) 강화
  Future<void> _handleDeleteSelected() async {
    if (_selectedUnits.isEmpty) {
      _showSnackBar('삭제할 단위를 선택해주세요.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmDialog(message: "선택한 단위를 삭제하시겠습니까?"),
    );

    if (!mounted || confirmed != true) return;

    List<int> unitIds = _selectedUnits.map((unit) => unit.id!).toList();
    BulkRequestResult result = await PartUnitRepository().removePartUnits(unitIds);

    if (!mounted) return;

    String message = "";
    if (result.successCount > 0) {
      _dataTableKey = UniqueKey();
      
      // 필터를 '전체보기'로 초기화
      final unitProvider = Provider.of<UnitProvider>(context, listen: false);
      _selectedUnit = unitProvider.allUnit; 
      
      message = "${result.successCount}개의 단위를 삭제하였습니다.\n";
    }
    
    if (result.failedCount > 0) {
      message += "${result.successCount}개 삭제 완료\n${result.failedCount}개 삭제 실패!\n해당 단위의 부품을 먼저 삭제해주세요.";
    }

    _showSnackBar(message);

    if (result.successCount > 0) {
      _selectedUnits.clear();
      Provider.of<UnitProvider>(context, listen: false).reloadUnits();
    }
  }

  // 3. [개선] UI 렌더링을 역할별 위젯 메서드로 깔끔하게 분리
  @override
  Widget build(BuildContext context) {
    final unitProvider = Provider.of<UnitProvider>(context);

    // Provider의 데이터를 바탕으로 현재 표에 보여줄 리스트를 결정
    final displayUnits = (_selectedUnit == unitProvider.allUnit || _selectedUnit == null)
        ? unitProvider.units
        : [_selectedUnit!];

    // [중요] DataSource 객체를 재생성하지 않고 데이터만 덮어씌움
    _dataSource.updateData(displayUnits); 

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScreenTitle(menu: InventoryMenu.unitManagement),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopButtonsRow(unitProvider),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilterDropdown(unitProvider),
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

  Widget _buildTopButtonsRow(UnitProvider unitProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      child: Row(
        spacing: 20,
        children: [
          const GoFirstButton(),
          const GoBackButton(),
          RefreshButton(
            onPressed: () {
              unitProvider.reloadUnits(); // setState 없이 Provider 상태만 갱신
            },
          ),
          const RegisterPageButton(InventoryMenu.unitRegister),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(UnitProvider unitProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
      child: DropdownMenu<PartUnit>(
        label: const Text("단위"),
        menuHeight: 400,
        initialSelection: _selectedUnit,
        onSelected: (unit) {
          if (unit != null) {
            setState(() => _selectedUnit = unit);
          }
        },
        dropdownMenuEntries: unitProvider.unitsDropdownWithAll,
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