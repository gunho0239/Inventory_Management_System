import 'package:flutter/material.dart';
import 'package:inventory_management/datatable_source/part_data.dart';
import 'package:inventory_management/dto/bulk_request_result.dart';
import 'package:inventory_management/enums/inventory_menu.dart';
import 'package:inventory_management/enums/label_type.dart';
import 'package:inventory_management/models/part.dart';
import 'package:inventory_management/models/part_maker.dart';
import 'package:inventory_management/models/part_type.dart';
import 'package:inventory_management/providers/data_table_options_provider.dart';
import 'package:inventory_management/providers/maker_provider.dart';
import 'package:inventory_management/providers/type_provider.dart';
import 'package:inventory_management/repository/part_repository.dart';
import 'package:inventory_management/screens/part_register_screen.dart';
import 'package:inventory_management/widgets/buttons.dart';
import 'package:inventory_management/widgets/dialogs.dart';
import 'package:inventory_management/widgets/icon_label.dart';
import 'package:inventory_management/widgets/title.dart';
import 'package:provider/provider.dart';

class PartManagementScreen extends StatefulWidget {
  const PartManagementScreen({super.key});

  @override
  State<PartManagementScreen> createState() => _PartManagementScreenState();
}

class _PartManagementScreenState extends State<PartManagementScreen> {
  late PartType _selectedType;
  late PartMaker _selectedMaker;

  final TextEditingController _specFieldController = TextEditingController();
  final PartRepository _partRepo = PartRepository(); // Repository는 인스턴스화하여 재사용

  final List<DataColumn> _columns = const [
    DataColumn(label: Text('품명')),
    DataColumn(label: Text('규격')),
    DataColumn(label: Text('제조사')),
    DataColumn(label: Text('단위')),
  ];
  
  late PartDataSource _dataSource;
  Key _dataTableKey = UniqueKey();
  List<Part> _inquiredParts = [];
  Set<Part> _selectedParts = {};
  bool _isLoading = false; // 데이터 로딩 상태 표시용

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _specFieldController.dispose();
    super.dispose();
  }

  void _initializeData() {
    final typeProvider = Provider.of<TypeProvider>(context, listen: false);
    final makerProvider = Provider.of<MakerProvider>(context, listen: false);
    
    _selectedType = typeProvider.allType;
    _selectedMaker = makerProvider.allMaker;

    _dataSource = PartDataSource(
      parts: _inquiredParts,
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

    // 빌드 완료 직후 프로바이더 데이터 로딩 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      typeProvider.reloadTypes();
      makerProvider.reloadMakers();
      _getParts();
    });
  }

  Future<void> _getParts() async {
    setState(() => _isLoading = true);

    final typeProvider = Provider.of<TypeProvider>(context, listen: false);
    final makerProvider = Provider.of<MakerProvider>(context, listen: false);
    
    final isAllType = _selectedType == typeProvider.allType;
    final isAllMaker = _selectedMaker == makerProvider.allMaker;
    final specText = _specFieldController.text.trim();
    
    final result = await switch ((isAllType, isAllMaker, specText.isEmpty)) {
      (true, true, true) => _partRepo.getAllParts(),
      (false, true, true) => _partRepo.getPartsByType(_selectedType.id!),
      (true, false, true) => _partRepo.getPartsByMaker(_selectedMaker.id!),
      _ => _partRepo.getPartsByFilter(
            isAllType ? null : _selectedType.id!,
            isAllMaker ? null : _selectedMaker.id!,
            specText.isEmpty ? null : specText,
          ),
    };

    if (!mounted) return; // 비동기 대기 후 반드시 확인
    
    setState(() {
      _inquiredParts = result;
      _selectedParts.clear();
      _isLoading = false;
    });
    
    _dataSource.updateData(_inquiredParts);
  }

  Future<void> _handleRegister() async {
    final refresh = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PartRegisterScreen()),
    );
  
    if (!mounted) return;

    if (refresh == true) {
      _dataTableKey = UniqueKey();
      _getParts();
    }
  }

  Future<void> _handleDelete() async {
    if (_selectedParts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('삭제할 부품을 선택해주세요.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmDialog(message: "선택한 부품을 삭제하시겠습니까?"),
    );

    if (!mounted || confirmed != true) return;
    
    List<int> partIds = _selectedParts.map((part) => part.id!).toList();
    BulkRequestResult result = await _partRepo.removeParts(partIds);
  
    if (!mounted) return;

    String message = "";
    if (result.successCount > 0) {
      _dataTableKey = UniqueKey();
      message = "${result.successCount}개의 부품을 삭제하였습니다.\n";
    }
    if (result.failedCount > 0) {
      message = "${result.successCount}개 삭제 완료\n${result.failedCount}개 삭제 실패!";
    }

    await showDialog(
      context: context,
      builder: (context) => ResultDialog(message: message),
    );

    if (!mounted) return;
    
    _selectedParts.clear();
    _getParts();
  }

  // 4. [개선] UI 렌더링 코드 분할
  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ScreenTitle(menu: InventoryMenu.partManagement),
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
                    width: 1400,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0),
                            child: _buildDataTable(),
                          ),
                        ),
                        DeleteButton(onPressed: _handleDelete),
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
    final typeProvider = Provider.of<TypeProvider>(context);
    final makerProvider = Provider.of<MakerProvider>(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 20,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: DropdownMenu<PartType>(
              label: const IconLabel(labelType: LabelType.type),
              enableFilter: true,
              menuHeight: 400,
              width: 150,
              initialSelection: _selectedType,
              onSelected: (type) {
                if (type != null) {
                  _selectedType = type;
                  _dataTableKey = UniqueKey();
                  _getParts();
                }
              },
              dropdownMenuEntries: typeProvider.typesDropdownWithAll,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: DropdownMenu<PartMaker>(
              label: const IconLabel(labelType: LabelType.maker),
              enableFilter: true,
              menuHeight: 400,
              width: 160,
              initialSelection: _selectedMaker,
              onSelected: (maker) {
                if (maker != null) {
                  _selectedMaker = maker;
                  _dataTableKey = UniqueKey();
                  _getParts();
                }
              },
              dropdownMenuEntries: makerProvider.makersDropdownWithAll,
            ),
          ),
          SizedBox(
            width: 180,
            child: TextField(
              controller: _specFieldController,
              decoration: const InputDecoration(
                label: IconLabel(labelType: LabelType.specification),
                hintText: "입력 후 엔터",
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) {
                _dataTableKey = UniqueKey();
                _getParts();
              },
            ),
          ),
          RegisterPageButton(
            InventoryMenu.partRegister,
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

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: PaginatedDataTable(
        key: _dataTableKey,
        columns: _columns,
        source: _dataSource,
        rowsPerPage: tableOptionsProvider.rowsPerPage,
        availableRowsPerPage: tableOptionsProvider.availableRowsPerPage,
        showCheckboxColumn: true,
        showEmptyRows: false,
        showFirstLastButtons: true,
        onRowsPerPageChanged: (value) {
          if (value != null) {
            tableOptionsProvider.updateRowsPerPage(value);
          }
        },
      ),
    );
  }
}