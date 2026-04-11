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

class SectionRegisterScreen extends StatefulWidget {
  const SectionRegisterScreen({super.key});

  @override
  State<SectionRegisterScreen> createState() => _SectionRegisterScreenState();
}

class _SectionRegisterScreenState extends State<SectionRegisterScreen> {
  final TextEditingController _sectionFieldController = TextEditingController();
  final FocusNode _sectionFieldFocusNode = FocusNode();

  final List<DataColumn> _columns = const [DataColumn(label: Text('구역'))];
  late LocationSectionDataSource _dataSource;
  Key _dataTableKey = UniqueKey();

  final Set<LocationSection> _sections = {};
  final Set<LocationSection> _selectedSections = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // 1. [개선] 메모리 누수 방지
  @override
  void dispose() {
    _sectionFieldController.dispose();
    _sectionFieldFocusNode.dispose();
    super.dispose();
  }

  // 2. [개선] DataSource 1회 초기화 및 뼈대 구축
  void _initializeData() {
    _dataSource = LocationSectionDataSource(
      sections: _sections.toList(),
      selectedSections: _selectedSections,
      onSelectChanged: (section, selected) {
        setState(() {
          if (selected) {
            _selectedSections.add(section);
          } else {
            _selectedSections.remove(section);
          }
        });
        _dataSource.updateSelected();
      },
    );
  }

  // 스낵바 공통 함수
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // 3. [개선] 구역 추가 로직 분리 및 최적화
  void _handleAddSection(String sectionName) {
    if (sectionName.isNotEmpty) {
      LocationSection newSection = LocationSection(section: sectionName);
      setState(() {
        _sections.add(newSection);
        _dataSource.updateData(_sections.toList()); // DataSource 갱신
      });
      _sectionFieldController.clear();
      FocusScope.of(context).requestFocus(_sectionFieldFocusNode);
    } else {
      _showSnackBar('구역 이름을 입력해주세요.');
    }
  }

  Future<int> _registerAllSections() async {
    if (_sections.isEmpty) return 0;

    List<LocationSection> sectionList = _sections.toList();
    sectionList.sort((a, b) => a.section!.compareTo(b.section!));

    List<LocationSection> registeredSections = await LocationSectionRepository().addLocationSections(sectionList);
    return registeredSections.length;
  }

  // 4. [개선] 저장 비즈니스 로직 추출 및 안전한 화면 갱신
  Future<void> _handleSaveAll() async {
    if (_sections.isEmpty) {
      _showSnackBar('등록할 구역이 없습니다.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmDialog(message: "전체등록 하시겠습니까?"),
    );

    if (!mounted || confirmed != true) return;

    int count = await _registerAllSections();

    if (!mounted) return;

    if (count > 0) {
      setState(() {
        _sections.clear();
        _selectedSections.clear();
        _dataSource.updateData([]); // 표 데이터 비우기
        _dataTableKey = UniqueKey();
      });

      // Provider를 통한 전역 상태 새로고침
      Provider.of<SectionProvider>(context, listen: false).reloadSections();

      _showSnackBar('$count개의 구역이 등록되었습니다.');
    } else {
      showDialog(
        context: context,
        builder: (context) => const ErrorDialog(message: '이미 등록된 구역입니다.'),
      );
    }
  }

  void _handleDeleteSelected() {
    if (_selectedSections.isEmpty) {
      _showSnackBar('삭제할 구역을 선택해주세요.');
      return;
    }
    setState(() {
      _sections.removeAll(_selectedSections);
      _selectedSections.clear();
      _dataSource.updateData(_sections.toList()); // 테이블 갱신
    });
  }

  // 5. [개선] 거대한 UI 코드를 가독성 좋게 분할
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScreenTitle(menu: InventoryMenu.sectionRegister),
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
      padding: const EdgeInsets.only(left: 10.0, top: 10.0),
      child: SizedBox(
        width: 190,
        child: TextField(
          controller: _sectionFieldController,
          focusNode: _sectionFieldFocusNode,
          decoration: const InputDecoration(
            labelText: "구역 입력",
            hintText: '번호를 제외하고 입력',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (sectionName) => _handleAddSection(sectionName.trim()),
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