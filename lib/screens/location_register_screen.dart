import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_management/datatable_source/location_data.dart';
import 'package:inventory_management/enums/inventory_menu.dart';
import 'package:inventory_management/enums/label_type.dart';
import 'package:inventory_management/models/location.dart';
import 'package:inventory_management/models/location_section.dart';
import 'package:inventory_management/providers/data_table_options_provider.dart';
import 'package:inventory_management/providers/section_provider.dart';
import 'package:inventory_management/repository/location_repository.dart';
import 'package:inventory_management/screens/section_management_screen.dart';
import 'package:inventory_management/style/style.dart';
import 'package:inventory_management/widgets/buttons.dart';
import 'package:inventory_management/widgets/dialogs.dart';
import 'package:inventory_management/widgets/icon_label.dart';
import 'package:inventory_management/widgets/title.dart';
import 'package:provider/provider.dart';

class LocationRegisterScreen extends StatefulWidget {
  const LocationRegisterScreen({super.key});

  @override
  State<LocationRegisterScreen> createState() => _LocationRegisterScreenState();
}

class _LocationRegisterScreenState extends State<LocationRegisterScreen> {
  bool _refresh = false;
  LocationSection? _selectedSection;
  
  final TextEditingController _startNumberController = TextEditingController();
  final TextEditingController _endNumberController = TextEditingController();

  final List<DataColumn> _columns = const [
    DataColumn(label: Text('구역')),
    DataColumn(label: Text('번호')),
  ];
  
  late LocationDataSource _dataSource;
  Key _dataTableKey = UniqueKey();
  
  final Set<Location> _locations = {};
  final Set<Location> _selectedLocations = {};

  final LocationRepository _locationRepo = LocationRepository();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // 1. [개선] 메모리 누수 방지
  @override
  void dispose() {
    _startNumberController.dispose();
    _endNumberController.dispose();
    super.dispose();
  }

  // 2. [개선] DataSource 1회 초기화
  void _initializeData() {
    _dataSource = LocationDataSource(
      locations: _locations.toList(),
      selectedLocations: _selectedLocations,
      onSelectChanged: (location, selected) {
        setState(() {
          if (selected) {
            _selectedLocations.add(location);
          } else {
            _selectedLocations.remove(location);
          }
        });
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SectionProvider>(context, listen: false).reloadSections();
    });
  }

  // 스낵바 공통 함수
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // 3. [개선] 위치 추가 로직 - 렌더링 최적화 적용
  void _addToTable() {
    if (_selectedSection == null || 
        _startNumberController.text.isEmpty || 
        _endNumberController.text.isEmpty) {
      _showSnackBar('구역 및 시작/종료 번호를 모두 입력해주세요.');
      return;
    }

    int start = int.tryParse(_startNumberController.text) ?? 0;
    int end = int.tryParse(_endNumberController.text) ?? 0;

    if (start > end) {
      _showSnackBar('시작 번호가 종료 번호보다 클 수 없습니다.');
      return;
    }

    // Set에 한 번에 추가 후 상태 갱신
    for (int number = start; number <= end; number++) {
      _locations.add(
        Location(
          section: LocationSection(id: _selectedSection!.id, section: _selectedSection!.section),
          number: number,
        ),
      );
    }

    setState(() {
      _dataSource.updateData(_locations.toList()); // DataSource 갱신
      _startNumberController.clear();
      _endNumberController.clear();
    });
  }

  Future<int> _registerAllLocations() async {
    if (_locations.isEmpty) return 0;

    List<Location> allLocations = _locations.toList();
    allLocations.sort((a, b) {
      if (a.section.id != b.section.id) {
        return a.section.id!.compareTo(b.section.id!);
      }
      return a.number.compareTo(b.number);
    });

    List<Location> registeredLocations = await _locationRepo.addLocations(allLocations);
    return registeredLocations.length;
  }

  // 4. [개선] 저장 비즈니스 로직 추출
  Future<void> _handleSaveAll() async {
    if (_locations.isEmpty) {
      _showSnackBar('등록할 위치가 없습니다.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmDialog(message: "전체등록 하시겠습니까?"),
    );

    if (!mounted || confirmed != true) return;

    int count = await _registerAllLocations();

    if (!mounted) return;

    if (count > 0) {
      setState(() {
        _refresh = true;
        _locations.clear();
        _selectedLocations.clear();
        _selectedSection = null;
        _startNumberController.clear();
        _endNumberController.clear();
        _dataSource.updateData([]); // 표 갱신
        _dataTableKey = UniqueKey();
      });
      _showSnackBar('$count개의 위치가 등록되었습니다.');
    } else {
      showDialog(
        context: context,
        builder: (context) => const ErrorDialog(message: '이미 등록된 위치입니다.'),
      );
    }
  }

  void _handleDeleteSelected() {
    if (_selectedLocations.isEmpty) {
      _showSnackBar('삭제할 위치를 선택해주세요.');
      return;
    }
    setState(() {
      _locations.removeAll(_selectedLocations);
      _selectedLocations.clear();
      _dataSource.updateData(_locations.toList()); // 표 갱신
    });
  }

  // 5. [개선] UI 렌더링 코드 분할
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScreenTitle(menu: InventoryMenu.locationRegister),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopButtonsRow(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
                    child: SizedBox(
                      width: 1000,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(width: 10),
                          _buildInputPanel(),
                          const SizedBox(width: 50),
                          _buildDataTable(),
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
              context,
              MaterialPageRoute(builder: (context) => const SectionManagementScreen()),
            ),
            child: const Text('구역관리', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputPanel() {
    final sectionProvider = Provider.of<SectionProvider>(context);

    return Column(
      spacing: 20,
      children: [
        DropdownMenu<LocationSection>(
          label: const IconLabel(labelType: LabelType.section),
          menuHeight: 400,
          initialSelection: _selectedSection,
          onSelected: (section) {
            if (section != null) {
              setState(() => _selectedSection = section);
            }
          },
          dropdownMenuEntries: sectionProvider.sectionsDropdown,
        ),
        SizedBox(
          width: 140,
          child: TextField(
            controller: _startNumberController,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              label: IconLabel(labelType: LabelType.startNumber),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        SizedBox(
          width: 140,
          child: TextField(
            controller: _endNumberController,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              label: IconLabel(labelType: LabelType.endNumber),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _addToTable(),
          ),
        ),
        ElevatedButton(
          onPressed: _addToTable,
          child: const Icon(Icons.add, size: 30),
        ),
      ],
    );
  }

  Widget _buildDataTable() {
    final tableOptionsProvider = context.watch<DataTableOptionsProvider>();

    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: SingleChildScrollView(
          child: PaginatedDataTable(
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
      ),
    );
  }

  Widget _buildActionPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        SaveAllButton(onPressed: _handleSaveAll),
        DeleteButton(onPressed: _handleDeleteSelected),
      ],
    );
  }
}