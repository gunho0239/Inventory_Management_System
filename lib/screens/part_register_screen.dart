import 'package:flutter/material.dart';
import 'package:inventory_management/datatable_source/part_data.dart';
import 'package:inventory_management/enums/inventory_menu.dart';
import 'package:inventory_management/enums/label_type.dart';
import 'package:inventory_management/models/part.dart';
import 'package:inventory_management/models/part_maker.dart';
import 'package:inventory_management/models/part_type.dart';
import 'package:inventory_management/models/part_unit.dart';
import 'package:inventory_management/providers/data_table_options_provider.dart';
import 'package:inventory_management/providers/maker_provider.dart';
import 'package:inventory_management/providers/type_provider.dart';
import 'package:inventory_management/providers/unit_provider.dart';
import 'package:inventory_management/repository/part_repository.dart';
import 'package:inventory_management/screens/maker_management_screen.dart';
import 'package:inventory_management/screens/type_management_screen.dart';
import 'package:inventory_management/screens/unit_management_screen.dart';
import 'package:inventory_management/style/style.dart';
import 'package:inventory_management/widgets/buttons.dart';
import 'package:inventory_management/widgets/dialogs.dart';
import 'package:inventory_management/widgets/icon_label.dart';
import 'package:inventory_management/widgets/title.dart';
import 'package:provider/provider.dart';

class PartRegisterScreen extends StatefulWidget {
  const PartRegisterScreen({super.key});

  @override
  State<PartRegisterScreen> createState() => _PartRegisterScreenState();
}

class _PartRegisterScreenState extends State<PartRegisterScreen> {
  bool _refresh = false;

  final TextEditingController _specFieldController = TextEditingController();
  final FocusNode _specFieldFocusNode = FocusNode();
  
  PartType? _selectedType;
  PartMaker? _selectedMaker;
  PartUnit? _selectedUnit;

  final List<DataColumn> _columns = const [
    DataColumn(label: Text('품명')),
    DataColumn(label: Text('규격')),
    DataColumn(label: Text('제조사')),
    DataColumn(label: Text('단위')),
  ];
  
  late PartDataSource _dataSource;
  Key _dataTableKey = UniqueKey();
  
  final Set<Part> _parts = {};
  final Set<Part> _selectedParts = {};

  final PartRepository _partRepo = PartRepository();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // 1. [개선] 메모리 누수 방지
  @override
  void dispose() {
    _specFieldController.dispose();
    _specFieldFocusNode.dispose();
    super.dispose();
  }

  void _initializeData() {
    // DataSource를 단 한 번만 생성
    _dataSource = PartDataSource(
      parts: _parts.toList(),
      selectedParts: _selectedParts,
      onSelectChanged: (part, selected) {
        setState(() {
          if (selected) {
            _selectedParts.add(part);
          } else {
            _selectedParts.remove(part);
          }
        });
        _dataSource.updateSelected();
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TypeProvider>(context, listen: false).reloadTypes();
      Provider.of<MakerProvider>(context, listen: false).reloadMakers();
      Provider.of<UnitProvider>(context, listen: false).reloadUnits();
    });
  }

  // 스낵바 공통 함수
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // 2. [개선] 부품 추가 로직 (데이터 소스 업데이트 적용)
  void _handleAddPart() {
    String spec = _specFieldController.text.trim();

    if (spec.isEmpty || _selectedType == null || _selectedMaker == null || _selectedUnit == null) {
      _showSnackBar('모든 항목을 입력해주세요.');
      return;
    }

    Part newPart = Part(
      type: _selectedType!,
      maker: _selectedMaker!,
      unit: _selectedUnit!,
      specification: spec,
    );

    setState(() {
      _parts.add(newPart);
      _dataSource.updateData(_parts.toList()); // DataSource 재생성 대신 데이터만 업데이트
    });

    _specFieldController.clear();
    FocusScope.of(context).requestFocus(_specFieldFocusNode);
  }

  Future<int> _registerAllParts() async {
    if (_parts.isEmpty) return 0;
    List<Part> registeredParts = await _partRepo.addParts(_parts.toList());
    return registeredParts.length;
  }

  // 3. [개선] 저장 비즈니스 로직 분리 및 안전한 Context 제어
  Future<void> _handleSaveAll() async {
    if (_parts.isEmpty) {
      _showSnackBar('등록할 부품이 없습니다.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmDialog(message: "전체등록 하시겠습니까?"),
    );

    if (!mounted || confirmed != true) return;

    int count = await _registerAllParts();

    if (!mounted) return;

    if (count > 0) {
      setState(() {
        _parts.clear();
        _selectedParts.clear();
        _dataSource.updateData([]); // 테이블 초기화
        _dataTableKey = UniqueKey();
        _refresh = true;
      });
      _showSnackBar('$count개의 부품이 등록되었습니다.');
    } else {
      showDialog(
        context: context,
        builder: (context) => const ErrorDialog(message: '이미 등록된 부품이거나 오류가 발생했습니다.'),
      );
    }
  }

  void _handleDeleteSelected() {
    if (_selectedParts.isEmpty) {
      _showSnackBar('삭제할 부품을 선택해주세요.');
      return;
    }
    
    setState(() {
      _parts.removeAll(_selectedParts);
      _selectedParts.clear();
      _dataSource.updateData(_parts.toList()); // 갱신된 리스트 적용
    });
  }

  // 4. [개선] UI 렌더링 코드 분할
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScreenTitle(menu: InventoryMenu.partRegister),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopButtonsRow(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
                    child: SizedBox(
                      width: 1500,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputPanel(),
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: _buildDataTable(),
                            ),
                          ),
                          _buildActionPanel(),
                        ],
                      ),
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

  Widget _buildTopButtonsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      child: Row(
        spacing: 20,
        children: [
          GoFirstButton(refresh: _refresh),
          GoBackButton(refresh: _refresh),
          ElevatedButton(
            style: AppButtonStyle.newPage,
            onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (context) => const TypeManagementScreen())
            ),
            child: const Text('품명관리', style: TextStyle(fontSize: 18)),
          ),
          ElevatedButton(
            style: AppButtonStyle.newPage,
            onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (context) => const MakerManagementScreen())
            ),
            child: const Text('제조사관리', style: TextStyle(fontSize: 18)),
          ),
          ElevatedButton(
            style: AppButtonStyle.newPage,
            onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (context) => const UnitManagementScreen())
            ),
            child: const Text('단위관리', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputPanel() {
    final typeProvider = Provider.of<TypeProvider>(context);
    final makerProvider = Provider.of<MakerProvider>(context);
    final unitProvider = Provider.of<UnitProvider>(context);

    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 10),
      child: Column(
        spacing: 20,
        children: [
          DropdownMenu<PartType>(
            label: const IconLabel(labelType: LabelType.type),
            enableFilter: true,
            menuHeight: 400,
            width: 180,
            initialSelection: _selectedType,
            onSelected: (type) {
              if (type != null) _selectedType = type;
            },
            dropdownMenuEntries: typeProvider.typesDropdown,
          ),
          DropdownMenu<PartMaker>(
            label: const IconLabel(labelType: LabelType.maker),
            enableFilter: true,
            menuHeight: 400,
            width: 180,
            initialSelection: _selectedMaker,
            onSelected: (maker) {
              if (maker != null) _selectedMaker = maker;
            },
            dropdownMenuEntries: makerProvider.makersDropdown,
          ),
          DropdownMenu<PartUnit>(
            label: const IconLabel(labelType: LabelType.unit),
            enableFilter: true,
            menuHeight: 400,
            width: 180,
            initialSelection: _selectedUnit,
            onSelected: (unit) {
              if (unit != null) _selectedUnit = unit;
            },
            dropdownMenuEntries: unitProvider.unitsDropdown,
          ),
          SizedBox(
            width: 180,
            child: TextField(
              controller: _specFieldController,
              focusNode: _specFieldFocusNode,
              textAlign: TextAlign.start,
              decoration: const InputDecoration(
                label: IconLabel(labelType: LabelType.specification),
                hintText: "입력 후 엔터",
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _handleAddPart(),
            ),
          ),
          ElevatedButton(
            onPressed: _handleAddPart,
            child: const Icon(Icons.add, size: 30),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    final tableOptionsProvider = context.watch<DataTableOptionsProvider>();

    return SingleChildScrollView(
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
    );
  }

  Widget _buildActionPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SaveAllButton(onPressed: _handleSaveAll),
        const SizedBox(height: 20),
        DeleteButton(onPressed: _handleDeleteSelected),
      ],
    );
  }
}