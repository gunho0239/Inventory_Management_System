import 'package:flutter/material.dart';
import 'package:inventory_management/datatable_source/part_maker_data.dart';
import 'package:inventory_management/main.dart';
import 'package:inventory_management/models/part_maker.dart';
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
  final TextEditingController makerFieldController = TextEditingController();
  final FocusNode _makerFieldFocusNode = FocusNode();

  final List<DataColumn> columns = [DataColumn(label: Text('제조사'))];
  late PartMakerDataSource _dataSource;
  Key dataTableKey = UniqueKey();

  Set<PartMaker> makers = {};
  Set<PartMaker> selectedMakers = {};

  void addMaker(BuildContext context, String makerName) {
    if (makerName.isNotEmpty) {
      PartMaker newMaker = PartMaker(maker: makerName);
      makers.add(newMaker);
      makerFieldController.clear();
      setState(() {});
      FocusScope.of(context).requestFocus(_makerFieldFocusNode);
    } 
    else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('제조사 이름을 입력해주세요.')));
    }
  }

  Future<int> registerAllMakers() async {
    if (makers.isEmpty) return 0;

    List<PartMaker> makerList = makers.toList();
    makerList.sort((a, b) => a.maker!.compareTo(b.maker!));

    List<PartMaker> registeredMakers = await PartMakerRepository()
        .addPartMakers(makerList);

    return registeredMakers.length;
  }

  @override
  Widget build(BuildContext context) {
    _dataSource = PartMakerDataSource(
      makers: makers.toList(),
      selectedMakers: selectedMakers,
      onSelectChanged: (maker, selected) {
        setState(() {
          if (selected) {
            selectedMakers.add(maker);
          } else {
            selectedMakers.remove(maker);
          }
        });
      },
    );

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenTitle(menu: InventoryMenu.makerRegister),
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
                        SizedBox(width: 10),
                        SizedBox(
                          width: 180,
                          child: TextField(
                            controller: makerFieldController,
                            focusNode: _makerFieldFocusNode,
                            decoration: InputDecoration(
                              labelText: "제조사 입력",
                              hintText: "입력 후 엔터",
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (makerName) {
                              addMaker(context, makerName.trim());
                            },
                          ),
                        ),
                        SizedBox(width: 50),
                        Padding(
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SaveAllButton(
                              onPressed: () async {
                                if (makers.isEmpty) {
                                  showDialog(
                                    context: context,
                                    builder: (context) =>
                                        ErrorDialog(message: '등록할 제조사가 없습니다.'),
                                  );
                                  return;
                                }

                                final confirmed = await showDialog(
                                  context: context,
                                  builder: (context) =>
                                      ConfirmDialog(message: "전체등록 하시겠습니까?"),
                                );

                                if (confirmed == null || confirmed == false) return;

                                int count = await registerAllMakers();

                                if (!mounted) return;

                                if (count > 0) {
                                  makers.clear();
                                  dataTableKey = UniqueKey();
                                  Provider.of<MakerProvider>(
                                    context,
                                    listen: false,
                                  ).reloadMakers();
                                  setState(() {});
                                  showDialog(
                                    context: context,
                                    builder: (context) => ResultDialog(
                                      message: '$count개의 제조사가 등록되었습니다.',
                                    ),
                                  );
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (context) =>
                                        ErrorDialog(message: '이미 등록된 제조사입니다.'),
                                  );
                                  return;
                                }
                              },
                            ),
                            SizedBox(height: 20),
                            DeleteButton(
                              onPressed: () {
                                if (selectedMakers.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('삭제할 제조사를 선택해주세요.')),
                                  );
                                  return;
                                }
                                setState(() {
                                  makers.removeAll(selectedMakers);
                                  selectedMakers.clear();
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
