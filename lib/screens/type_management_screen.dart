import 'package:flutter/material.dart';
import 'package:inventory_management/dto/bulk_request_result.dart';
import 'package:inventory_management/datatable_source/part_type_data.dart';
import 'package:inventory_management/enums/inventory_menu.dart';
import 'package:inventory_management/models/part_type.dart';
import 'package:inventory_management/providers/data_table_options_provider.dart';
import 'package:inventory_management/providers/type_provider.dart';
import 'package:inventory_management/repository/part_type_repository.dart';
import 'package:inventory_management/widgets/buttons.dart';
import 'package:inventory_management/widgets/dialogs.dart';
import 'package:inventory_management/widgets/title.dart';
import 'package:provider/provider.dart';

class TypeManagementScreen extends StatefulWidget {
  const TypeManagementScreen({super.key});

  @override
  State<TypeManagementScreen> createState() => _TypeManagementScreenState();
}

class _TypeManagementScreenState extends State<TypeManagementScreen> {
  PartType? _selectedType;
  final Set<PartType> _selectedTypes = {};
  
  late PartTypeDataSource _dataSource;
  Key _dataTableKey = UniqueKey();

  final List<DataColumn> _columns = const [
    DataColumn(label: Text('품명')),
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // 1. [개선] DataSource를 단 1번만 초기화합니다.
    _dataSource = PartTypeDataSource(
      types: [], // 초기엔 빈 배열, build 시점에 업데이트
      selectedTypes: _selectedTypes,
      onSelectChanged: (type, selected) {
        setState(() {
          if (selected) {
            _selectedTypes.add(type);
          } else {
            _selectedTypes.remove(type);
          }
        });
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final typeProvider = Provider.of<TypeProvider>(context, listen: false);
      _selectedType = typeProvider.allType;
      typeProvider.reloadTypes();
    });
  }

  // 스낵바 공통 함수
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // 2. [개선] 삭제 비즈니스 로직을 별도 메서드로 추출 및 안전성(mounted) 강화
  Future<void> _handleDeleteSelected() async {
    if (_selectedTypes.isEmpty) {
      _showSnackBar('삭제할 품명을 선택해주세요.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmDialog(message: "선택한 품명을 삭제하시겠습니까?"),
    );

    if (!mounted || confirmed != true) return;

    List<int> typeIds = _selectedTypes.map((type) => type.id!).toList();
    BulkRequestResult result = await PartTypeRepository().removePartTypes(typeIds);

    if (!mounted) return;

    String message = "";
    if (result.successCount > 0) {
      _dataTableKey = UniqueKey();
      
      // 필터를 '전체보기'로 초기화
      final typeProvider = Provider.of<TypeProvider>(context, listen: false);
      _selectedType = typeProvider.allType; 
      
      message = "${result.successCount}개의 품명을 삭제하였습니다.\n";
    }
    
    if (result.failedCount > 0) {
      message += "${result.successCount}개 삭제 완료\n${result.failedCount}개 삭제 실패!\n해당 품명의 부품을 먼저 삭제해주세요.";
    }

    _showSnackBar(message);

    if (result.successCount > 0) {
      _selectedTypes.clear();
      Provider.of<TypeProvider>(context, listen: false).reloadTypes();
    }
  }

  // 3. [개선] UI 렌더링을 기능별 위젯 메서드로 분리
  @override
  Widget build(BuildContext context) {
    final typeProvider = Provider.of<TypeProvider>(context);

    // Provider의 데이터를 바탕으로 현재 표에 보여줄 리스트를 결정합니다.
    final displayTypes = (_selectedType == typeProvider.allType || _selectedType == null)
        ? typeProvider.types
        : [_selectedType!];

    // [중요] 새로 생성하는 대신, 데이터만 업데이트합니다.
    _dataSource.updateData(displayTypes); 

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScreenTitle(menu: InventoryMenu.typeManagement),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopButtonsRow(typeProvider),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilterDropdown(typeProvider),
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

  Widget _buildTopButtonsRow(TypeProvider typeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      child: Row(
        spacing: 20,
        children: [
          const GoFirstButton(),
          const GoBackButton(),
          RefreshButton(
            onPressed: () {
              typeProvider.reloadTypes(); // setState 불필요 (Provider가 알아서 알림)
            },
          ),
          const RegisterPageButton(InventoryMenu.typeRegister),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(TypeProvider typeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
      child: DropdownMenu<PartType>(
        label: const Text("품명"),
        menuHeight: 400,
        initialSelection: _selectedType,
        onSelected: (type) {
          if (type != null) {
            setState(() => _selectedType = type);
          }
        },
        dropdownMenuEntries: typeProvider.typesDropdownWithAll,
      ),
    );
  }

  Widget _buildDataTable() {
    final tableOptionsProvider = context.watch<DataTableOptionsProvider>();

    return Flexible(
      child: SizedBox(
        width: 700,
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