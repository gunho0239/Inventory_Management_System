import 'package:flutter/material.dart';
import 'package:inventory_management/datatable_source/part_maker_data.dart';
import 'package:inventory_management/dto/bulk_request_result.dart';
import 'package:inventory_management/enums/inventory_menu.dart';
import 'package:inventory_management/models/part_maker.dart';
import 'package:inventory_management/providers/data_table_options_provider.dart';
import 'package:inventory_management/providers/maker_provider.dart';
import 'package:inventory_management/repository/part_maker_repository.dart';
import 'package:inventory_management/widgets/buttons.dart';
import 'package:inventory_management/widgets/dialogs.dart';
import 'package:inventory_management/widgets/title.dart';
import 'package:provider/provider.dart';

class MakerManagementScreen extends StatefulWidget {
  const MakerManagementScreen({super.key});

  @override
  State<MakerManagementScreen> createState() => _MakerManagementScreenState();
}

class _MakerManagementScreenState extends State<MakerManagementScreen> {
  PartMaker? _selectedMaker;
  final Set<PartMaker> _selectedMakers = {};
  
  late PartMakerDataSource _dataSource;
  Key _dataTableKey = UniqueKey();

  final List<DataColumn> _columns = const [
    DataColumn(label: Text('제조사')),
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // 1. [개선] DataSource를 단 1번만 초기화합니다.
    _dataSource = PartMakerDataSource(
      makers: [], // 초기엔 빈 배열, build 시점에 업데이트
      selectedMakers: _selectedMakers,
      onSelectChanged: (maker, selected) {
        setState(() {
          if (selected) {
            _selectedMakers.add(maker);
          } else {
            _selectedMakers.remove(maker);
          }
        });
      },
    );

    // 프레임 렌더링 직후 Provider 데이터를 불러옵니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final makerProvider = Provider.of<MakerProvider>(context, listen: false);
      _selectedMaker = makerProvider.allMaker;
      makerProvider.reloadMakers();
    });
  }

  // 스낵바 공통 함수
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // 2. [개선] 삭제 비즈니스 로직을 별도 메서드로 추출 및 안전성(mounted) 강화
  Future<void> _handleDeleteSelected() async {
    if (_selectedMakers.isEmpty) {
      _showSnackBar('삭제할 제조사를 선택해주세요.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmDialog(message: "선택한 제조사를 삭제하시겠습니까?"),
    );

    if (!mounted || confirmed != true) return;

    List<int> makerIds = _selectedMakers.map((maker) => maker.id!).toList();
    BulkRequestResult result = await PartMakerRepository().removePartMakers(makerIds);

    if (!mounted) return;

    String message = "";
    if (result.successCount > 0) {
      _dataTableKey = UniqueKey();
      
      // 필터를 '전체보기'로 초기화
      final makerProvider = Provider.of<MakerProvider>(context, listen: false);
      _selectedMaker = makerProvider.allMaker; 
      
      message = "${result.successCount}개의 제조사를 삭제하였습니다.\n";
    }
    
    if (result.failedCount > 0) {
      message += "${result.successCount}개 삭제 완료\n${result.failedCount}개 삭제 실패!\n해당 제조사의 부품을 먼저 삭제해주세요.";
    }

    _showSnackBar(message);

    if (result.successCount > 0) {
      _selectedMakers.clear();
      Provider.of<MakerProvider>(context, listen: false).reloadMakers();
    }
  }

  // 3. [개선] UI 렌더링을 기능별 위젯 메서드로 분리
  @override
  Widget build(BuildContext context) {
    final makerProvider = Provider.of<MakerProvider>(context);

    // Provider의 데이터를 바탕으로 현재 표에 보여줄 리스트를 결정합니다.
    final displayMakers = (_selectedMaker == makerProvider.allMaker || _selectedMaker == null)
        ? makerProvider.makers
        : [_selectedMaker!];

    // [중요] 새로 생성하는 대신, 데이터만 업데이트합니다.
    _dataSource.updateData(displayMakers); 

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScreenTitle(menu: InventoryMenu.makerManagement),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopButtonsRow(makerProvider),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilterDropdown(makerProvider),
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

  Widget _buildTopButtonsRow(MakerProvider makerProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      child: Row(
        spacing: 20,
        children: [
          const GoFirstButton(),
          const GoBackButton(),
          RefreshButton(
            onPressed: () {
              makerProvider.reloadMakers(); // setState 불필요 (Provider가 화면을 갱신함)
            },
          ),
          const RegisterPageButton(InventoryMenu.makerRegister),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(MakerProvider makerProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
      child: DropdownMenu<PartMaker>(
        label: const Text("제조사"),
        menuHeight: 400,
        initialSelection: _selectedMaker,
        onSelected: (maker) {
          if (maker != null) {
            setState(() => _selectedMaker = maker);
          }
        },
        dropdownMenuEntries: makerProvider.makersDropdownWithAll,
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