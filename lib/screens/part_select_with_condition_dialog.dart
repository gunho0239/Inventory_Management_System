import 'package:flutter/material.dart';
import 'package:inventory_management/constants/columns.dart';
import 'package:inventory_management/datatable_source/part_data.dart';
import 'package:inventory_management/enums/label_type.dart';
import 'package:inventory_management/models/part.dart';
import 'package:inventory_management/models/part_type.dart';
import 'package:inventory_management/models/part_maker.dart';
import 'package:inventory_management/providers/data_table_options_provider.dart';
import 'package:inventory_management/providers/type_provider.dart';
import 'package:inventory_management/providers/maker_provider.dart';
import 'package:inventory_management/repository/part_repository.dart';
import 'package:inventory_management/widgets/dialogs.dart';
import 'package:inventory_management/widgets/icon_label.dart';
import 'package:provider/provider.dart';

class PartSelectWithConditionDialog extends StatefulWidget {
  final PartType? selectedType;
  final PartMaker? selectedMaker;
  final String? specFilter;

  const PartSelectWithConditionDialog({
    super.key,
    this.selectedType,
    this.selectedMaker,
    this.specFilter,
  });

  @override
  State<PartSelectWithConditionDialog> createState() => _PartSelectWithConditionDialogState();
}

class _PartSelectWithConditionDialogState extends State<PartSelectWithConditionDialog> {
  final TextEditingController _typeFieldController = TextEditingController();
  final TextEditingController _makerFieldController = TextEditingController();
  final TextEditingController _specFieldController = TextEditingController();
  final PartRepository _partRepo = PartRepository();

  late PartType _selectedType;
  late PartMaker _selectedMaker;

  final List<DataColumn> _columns = const [
    DataColumn(label: Text(type)),
    DataColumn(label: Text(specification)),
    DataColumn(label: Text(maker)),
    DataColumn(label: Text(unit)),
  ];

  late PartDataSource _dataSource;
  Key _dataTableKey = UniqueKey();
  
  List<Part> _inquiredParts = [];
  Part? _selectedPart;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // 1. [개선] 컨트롤러 메모리 누수 방지
  @override
  void dispose() {
    _typeFieldController.dispose();
    _makerFieldController.dispose();
    _specFieldController.dispose();
    super.dispose();
  }

  // 2. [개선] 초기값 세팅 및 DataSource 1회 생성
  void _initializeData() {
    final typeProvider = Provider.of<TypeProvider>(context, listen: false);
    final makerProvider = Provider.of<MakerProvider>(context, listen: false);

    _selectedType = widget.selectedType ?? typeProvider.allType;
    _selectedMaker = widget.selectedMaker ?? makerProvider.allMaker;
    
    if (widget.specFilter != null) {
      _specFieldController.text = widget.specFilter!;
    }

    _dataSource = PartDataSource(
      parts: _inquiredParts,
      selectedParts: {},
      onSelectChanged: (part, selected) {
        setState(() {
          if (selected) {
            _selectedPart = part;
            _dataSource.selectedParts = {part};
          } else {
            _selectedPart = null;
            _dataSource.selectedParts = {};
          }
          _dataSource.updateSelected(); // UI 체크박스 상태만 갱신
        });
      },
    );

    // 렌더링 직후 데이터 호출
    WidgetsBinding.instance.addPostFrameCallback((_) {
      typeProvider.reloadTypes();
      makerProvider.reloadMakers();
      _getParts();
    });
  }

  // 3. [개선] 비동기 로딩 처리 및 mounted 안전성 확보
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

    if (!mounted) return;

    setState(() {
      _inquiredParts = result;
      _selectedPart = null;
      _isLoading = false;
      _dataTableKey = UniqueKey(); // 페이지네이션 초기화

      _dataSource.selectedParts = {};
      _dataSource.updateData(_inquiredParts);
    });
  }

  void _handleConfirm() {
    if (_selectedPart != null) {
      Navigator.of(context).pop(_selectedPart);
    } else {
      showDialog(
        context: context,
        builder: (context) => const ErrorDialog(message: '부품을 선택해주세요.'),
      );
    }
  }

  // 4. [개선] UI 구조화 및 다이얼로그 오버플로우 방지
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('부품 선택', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 1200, // 테이블 컬럼이 많으므로 넉넉하게 고정
        height: 650, // 세로 오버플로우 방지
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
    final typeProvider = Provider.of<TypeProvider>(context);
    final makerProvider = Provider.of<MakerProvider>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 20,
        children: [
          DropdownMenu<PartType>(
            controller: _typeFieldController,
            label: const IconLabel(labelType: LabelType.type),
            enableFilter: true,
            menuHeight: 400,
            width: 180,
            initialSelection: _selectedType,
            onSelected: (type) {
              if (type != null) {
                _selectedType = type;
                _getParts();
              }
            },
            dropdownMenuEntries: typeProvider.typesDropdownWithAll,
          ),
          DropdownMenu<PartMaker>(
            controller: _makerFieldController,
            label: const IconLabel(labelType: LabelType.maker),
            enableFilter: true,
            menuHeight: 400,
            width: 180,
            initialSelection: _selectedMaker,
            onSelected: (maker) {
              if (maker != null) {
                _selectedMaker = maker;
                _getParts();
              }
            },
            dropdownMenuEntries: makerProvider.makersDropdownWithAll,
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
              onSubmitted: (_) => _getParts(),
            ),
          ),
        ],
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