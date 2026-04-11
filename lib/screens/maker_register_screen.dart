import 'package:flutter/material.dart';
import 'package:inventory_management/datatable_source/part_maker_data.dart';
import 'package:inventory_management/enums/inventory_menu.dart';
import 'package:inventory_management/models/part_maker.dart';
import 'package:inventory_management/providers/data_table_options_provider.dart';
import 'package:inventory_management/providers/maker_provider.dart';
import 'package:inventory_management/repository/part_maker_repository.dart';
import 'package:inventory_management/widgets/buttons.dart';
import 'package:inventory_management/widgets/dialogs.dart';
import 'package:inventory_management/widgets/title.dart';
import 'package:provider/provider.dart';

class MakerRegisterScreen extends StatefulWidget {
  const MakerRegisterScreen({super.key});

  @override
  State<MakerRegisterScreen> createState() => _MakerRegisterScreenState();
}

class _MakerRegisterScreenState extends State<MakerRegisterScreen> {
  final TextEditingController _makerFieldController = TextEditingController();
  final FocusNode _makerFieldFocusNode = FocusNode();

  final List<DataColumn> _columns = const [DataColumn(label: Text('제조사'))];
  late PartMakerDataSource _dataSource;
  Key _dataTableKey = UniqueKey();

  final Set<PartMaker> _makers = {};
  final Set<PartMaker> _selectedMakers = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // 1. [개선] 메모리 누수 방지
  @override
  void dispose() {
    _makerFieldController.dispose();
    _makerFieldFocusNode.dispose();
    super.dispose();
  }

  // 2. [개선] DataSource 1회 초기화 (성능 최적화)
  void _initializeData() {
    _dataSource = PartMakerDataSource(
      makers: _makers.toList(),
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
  }

  // 스낵바 공통 함수
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // 3. [개선] 제조사 추가 로직 분리
  void _handleAddMaker(String makerName) {
    if (makerName.isNotEmpty) {
      PartMaker newMaker = PartMaker(maker: makerName);
      setState(() {
        _makers.add(newMaker);
        _dataSource.updateData(_makers.toList()); // DataSource 갱신
      });
      _makerFieldController.clear();
      FocusScope.of(context).requestFocus(_makerFieldFocusNode);
    } else {
      _showSnackBar('제조사 이름을 입력해주세요.');
    }
  }

  Future<int> _registerAllMakers() async {
    if (_makers.isEmpty) return 0;

    List<PartMaker> makerList = _makers.toList();
    makerList.sort((a, b) => a.maker!.compareTo(b.maker!));

    List<PartMaker> registeredMakers = await PartMakerRepository().addPartMakers(makerList);
    return registeredMakers.length;
  }

  // 4. [개선] 저장 비즈니스 로직 추출 및 안전성 강화
  Future<void> _handleSaveAll() async {
    if (_makers.isEmpty) {
      _showSnackBar('등록할 제조사가 없습니다.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmDialog(message: "전체등록 하시겠습니까?"),
    );

    if (!mounted || confirmed != true) return;

    int count = await _registerAllMakers();

    if (!mounted) return;

    if (count > 0) {
      setState(() {
        _makers.clear();
        _selectedMakers.clear();
        _dataSource.updateData([]); // 표 데이터 비우기
        _dataTableKey = UniqueKey();
      });
      
      // 등록 후 Provider 상태 업데이트
      Provider.of<MakerProvider>(context, listen: false).reloadMakers();
      
      _showSnackBar('$count개의 제조사가 등록되었습니다.');
    } else {
      showDialog(
        context: context,
        builder: (context) => const ErrorDialog(message: '이미 등록된 제조사입니다.'),
      );
    }
  }

  void _handleDeleteSelected() {
    if (_selectedMakers.isEmpty) {
      _showSnackBar('삭제할 제조사를 선택해주세요.');
      return;
    }
    setState(() {
      _makers.removeAll(_selectedMakers);
      _selectedMakers.clear();
      _dataSource.updateData(_makers.toList()); // 표 데이터 갱신
    });
  }

  // 5. [개선] UI 렌더링 코드 분할
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScreenTitle(menu: InventoryMenu.makerRegister),
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
          controller: _makerFieldController,
          focusNode: _makerFieldFocusNode,
          decoration: const InputDecoration(
            labelText: "제조사 입력",
            hintText: "입력 후 엔터",
            border: OutlineInputBorder(),
          ),
          onSubmitted: (makerName) {
            _handleAddMaker(makerName.trim());
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