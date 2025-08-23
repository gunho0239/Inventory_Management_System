import 'package:flutter/material.dart';
import 'package:inventory_management/datatable_source/location_section_data.dart';
import 'package:inventory_management/enums/inventory_menu.dart';
import 'package:inventory_management/models/location_section.dart';
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
  
  final TextEditingController sectionFieldController = TextEditingController();
  final FocusNode _sectionFieldFocusNode = FocusNode();

  final List<DataColumn> columns = [DataColumn(label: Text('구역'))];
  late LocationSectionDataSource _dataSource;
  Key dataTableKey = UniqueKey();

  Set<LocationSection> sections = {};
  Set<LocationSection> selectedSections = {};

  void addSection(BuildContext context, String sectionName) {
    if (sectionName.isNotEmpty) {
      LocationSection newSection = LocationSection(section: sectionName);
      sections.add(newSection);
      sectionFieldController.clear();
      setState(() {});
      FocusScope.of(context).requestFocus(_sectionFieldFocusNode);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('구역 이름을 입력해주세요.')));
    }
  }

  Future<int> registerAllSections() async {
    if (sections.isEmpty) return 0;

    List<LocationSection> sectionList = sections.toList();
    sectionList.sort((a, b) => a.section!.compareTo(b.section!));

    List<LocationSection> registeredSections = await LocationSectionRepository()
        .addLocationSections(sectionList);

    return registeredSections.length;
  }

  @override
  Widget build(BuildContext context) {
    _dataSource = LocationSectionDataSource(
      sections: sections.toList(),
      selectedSections: selectedSections,
      onSelectChanged: (section, selected) {
        setState(() {
          if (selected) {
            selectedSections.add(section);
          } else {
            selectedSections.remove(section);
          }
        });
      },
    );

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenTitle(menu: InventoryMenu.sectionRegister),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 5.0,
                  ),
                  child: GoBackButton(),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30.0,
                      vertical: 20.0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 10.0, top: 10.0),
                          child: SizedBox(
                            width: 190,
                            child: TextField(
                              controller: sectionFieldController,
                              focusNode: _sectionFieldFocusNode,
                              decoration: InputDecoration(
                                labelText: "구역 입력",
                                hintText: '번호를 제외하고 입력',
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: (sectionName) {
                                addSection(context, sectionName.trim());
                              },
                            ),
                          ),
                        ),
                        Spacer(flex: 1,),
                        Flexible(
                          flex: 30,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: SingleChildScrollView(
                              child: SizedBox(
                                width: 500,
                                child: PaginatedDataTable(
                                  key: dataTableKey,
                                  columns: columns,
                                  source: _dataSource,
                                  rowsPerPage: 10,
                                  showCheckboxColumn: true,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SaveAllButton(
                              onPressed: () async {
                                if (sections.isEmpty) {
                                  showDialog(
                                    context: context,
                                    builder: (context) =>
                                        ErrorDialog(message: '등록할 구역이 없습니다.'),
                                  );
                                  return;
                                }

                                final confirmed = await showDialog(
                                  context: context,
                                  builder: (context) =>
                                      ConfirmDialog(message: "전체등록 하시겠습니까?"),
                                );

                                if (confirmed == null || confirmed == false) return;

                                int count = await registerAllSections();

                                if (!context.mounted) return;

                                if (count > 0) {
                                  sections.clear();
                                  dataTableKey = UniqueKey();
                                  Provider.of<SectionProvider>(
                                    context,
                                    listen: false,
                                  ).reloadSections();
                                  setState(() {});
                                  showDialog(
                                    context: context,
                                    builder: (context) => ResultDialog(
                                      message: '$count개의 구역이 등록되었습니다.',
                                    ),
                                  );
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (context) =>
                                        ErrorDialog(message: '이미 등록된 구역입니다.'),
                                  );
                                  return;
                                }
                              },
                            ),
                            SizedBox(height: 20),
                            DeleteButton(
                              onPressed: () {
                                if (selectedSections.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('삭제할 구역을 선택해주세요.')),
                                  );
                                  return;
                                }
                                setState(() {
                                  sections.removeAll(selectedSections);
                                  selectedSections.clear();
                                });
                              },
                            ),
                          ],
                        ),
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
}
