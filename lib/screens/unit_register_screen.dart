import 'package:flutter/material.dart';
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

class UnitRegisterScreen extends StatefulWidget {
  const UnitRegisterScreen({super.key});

  @override
  State<UnitRegisterScreen> createState() => _UnitRegisterScreenState();
}

class _UnitRegisterScreenState extends State<UnitRegisterScreen> {
  final TextEditingController _unitFieldController = TextEditingController();
  final FocusNode _unitFieldFocusNode = FocusNode();

  final List<DataColumn> _columns = const [DataColumn(label: Text('단위'))];
  late PartUnitDataSource _dataSource;
  Key _dataTableKey = UniqueKey();

  final Set<PartUnit> _units = {};
  final Set<PartUnit> _selectedUnits = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // 1. [개선] 메모리 누수 방지
  @override
  void dispose() {
    _unitFieldController.dispose();
    _unitFieldFocusNode.dispose();
    super.dispose();
  }

  // 2. [개선] DataSource 초기화 및 뼈대 구축
  void _initializeData() {
    _dataSource = PartUnitDataSource(
      units: _units.toList(),
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
  }

  // 공통 스낵바
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // 3. [개선] 단위 추가 로직 분리
  void _handleAddUnit(String unitName) {
    if (unitName.isNotEmpty) {
      PartUnit newUnit = PartUnit(unit: unitName);
      setState(() {
        _units.add(newUnit);
        _dataSource.updateData(_units.toList()); // DataSource 데이터 갱신
      });
      _unitFieldController.clear();
      FocusScope.of(context).requestFocus(_unitFieldFocusNode);
    } else {
      _showSnackBar('단위 이름을 입력해주세요.');
    }
  }

  Future<int> _registerAllUnits() async {
    if (_units.isEmpty) return 0;

    List<PartUnit> unitList = _units.toList();
    unitList.sort((a, b) => a.unit!.compareTo(b.unit!));

    List<PartUnit> registeredUnits = await PartUnitRepository().addPartUnits(unitList);
    return registeredUnits.length;
  }

  // 4. [개선] 저장 비즈니스 로직 추출 및 안전한 화면 갱신
  Future<void> _handleSaveAll() async {
    if (_units.isEmpty) {
      _showSnackBar('등록할 단위가 없습니다.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmDialog(message: "전체등록 하시겠습니까?"),
    );

    if (!mounted || confirmed != true) return;

    int count = await _registerAllUnits();

    if (!mounted) return;

    if (count > 0) {
      setState(() {
        _units.clear();
        _selectedUnits.clear();
        _dataSource.updateData([]); // 테이블 비우기
        _dataTableKey = UniqueKey();
      });

      // Provider를 통한 전역 상태 새로고침
      Provider.of<UnitProvider>(context, listen: false).reloadUnits();
      
      _showSnackBar('$count개의 단위가 등록되었습니다.');
    } else {
      showDialog(
        context: context,
        builder: (context) => const ErrorDialog(message: '이미 등록된 단위입니다.'),
      );
    }
  }

  void _handleDeleteSelected() {
    if (_selectedUnits.isEmpty) {
      _showSnackBar('삭제할 단위를 선택해주세요.');
      return;
    }
    setState(() {
      _units.removeAll(_selectedUnits);
      _selectedUnits.clear();
      _dataSource.updateData(_units.toList()); // 테이블 갱신
    });
  }

  // 5. [개선] 거대한 build 메서드를 가독성 좋게 분리
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScreenTitle(menu: InventoryMenu.unitRegister),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopNavigationRow(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputSection(),
                        const Spacer(flex: 1),
                        _buildTableSection(),
                        _buildActionSection(),
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

  Widget _buildTopNavigationRow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      child: Row(
        spacing: 20,
        children: [
          GoFirstButton(),
          GoBackButton(),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 10),
      child: SizedBox(
        width: 180,
        child: TextField(
          controller: _unitFieldController,
          focusNode: _unitFieldFocusNode,
          decoration: const InputDecoration(
            labelText: "단위 입력",
            hintText: "입력 후 엔터",
            border: OutlineInputBorder(),
          ),
          onSubmitted: (unitName) => _handleAddUnit(unitName.trim()),
        ),
      ),
    );
  }

  Widget _buildTableSection() {
    final tableOptionsProvider = context.watch<DataTableOptionsProvider>();

    return Flexible(
      flex: 30,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: SingleChildScrollView(
          child: SizedBox(
            width: 500,
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

  Widget _buildActionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 20,
      children: [
        SaveAllButton(onPressed: _handleSaveAll),
        DeleteButton(onPressed: _handleDeleteSelected),
      ],
    );
  }
}