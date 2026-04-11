import 'package:flutter/material.dart';
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

class TypeRegisterScreen extends StatefulWidget {
  const TypeRegisterScreen({super.key});

  @override
  State<TypeRegisterScreen> createState() => _TypeRegisterScreenState();
}

class _TypeRegisterScreenState extends State<TypeRegisterScreen> {
  final TextEditingController _typeFieldController = TextEditingController();
  final FocusNode _typeFieldFocusNode = FocusNode();

  final List<DataColumn> _columns = const [DataColumn(label: Text('품명'))];
  late PartTypeDataSource _dataSource;
  Key _dataTableKey = UniqueKey();

  final Set<PartType> _types = {};
  final Set<PartType> _selectedTypes = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // 1. [개선] 메모리 누수 방지
  @override
  void dispose() {
    _typeFieldController.dispose();
    _typeFieldFocusNode.dispose();
    super.dispose();
  }

  // 2. [개선] DataSource 1회 초기화 (성능 최적화)
  void _initializeData() {
    _dataSource = PartTypeDataSource(
      types: _types.toList(),
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
  }

  // 스낵바 공통 함수
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // 3. [개선] 로직 메서드 분리
  void _handleAddType(String typeName) {
    if (typeName.isNotEmpty) {
      PartType newType = PartType(type: typeName);
      setState(() {
        _types.add(newType);
        _dataSource.updateData(_types.toList()); // DataSource 갱신
      });
      _typeFieldController.clear();
      FocusScope.of(context).requestFocus(_typeFieldFocusNode);
    } else {
      _showSnackBar('품명 이름을 입력해주세요.');
    }
  }

  Future<int> _registerAllTypes() async {
    if (_types.isEmpty) return 0;

    List<PartType> typeList = _types.toList();
    typeList.sort((a, b) => a.type!.compareTo(b.type!));

    List<PartType> registeredTypes = await PartTypeRepository().addPartTypes(typeList);
    return registeredTypes.length;
  }

  Future<void> _handleSaveAll() async {
    if (_types.isEmpty) {
      _showSnackBar('등록할 품명이 없습니다.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmDialog(message: "전체등록 하시겠습니까?"),
    );

    if (!mounted || confirmed != true) return;

    int count = await _registerAllTypes();

    if (!mounted) return;

    if (count > 0) {
      setState(() {
        _types.clear();
        _selectedTypes.clear();
        _dataSource.updateData([]); // 표 데이터 비우기
        _dataTableKey = UniqueKey();
      });
      
      // 등록 후 Provider 상태 업데이트
      Provider.of<TypeProvider>(context, listen: false).reloadTypes();
      
      _showSnackBar('$count개의 품명이 등록되었습니다.');
    } else {
      showDialog(
        context: context,
        builder: (context) => const ErrorDialog(message: '이미 등록된 품명입니다.'),
      );
    }
  }

  void _handleDeleteSelected() {
    if (_selectedTypes.isEmpty) {
      _showSnackBar('삭제할 품명을 선택해주세요.');
      return;
    }
    setState(() {
      _types.removeAll(_selectedTypes);
      _selectedTypes.clear();
      _dataSource.updateData(_types.toList());
    });
  }

  // 4. [개선] UI 렌더링 코드 분리
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScreenTitle(menu: InventoryMenu.typeRegister),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopButtonsRow(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputPanel(),
                        const Spacer(flex: 1),
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

  Widget _buildTopButtonsRow() {
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

  Widget _buildInputPanel() {
    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 10),
      child: SizedBox(
        width: 180,
        child: TextField(
          controller: _typeFieldController,
          focusNode: _typeFieldFocusNode,
          decoration: const InputDecoration(
            labelText: "품명 입력",
            hintText: "입력 후 엔터",
            border: OutlineInputBorder(),
          ),
          onSubmitted: (typeName) {
            _handleAddType(typeName.trim());
          },
        ),
      ),
    );
  }

  Widget _buildDataTable() {
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

  Widget _buildActionPanel() {
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