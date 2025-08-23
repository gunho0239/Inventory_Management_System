import 'package:flutter/material.dart';
import 'package:inventory_management/datatable_source/part_data.dart';
import 'package:inventory_management/enums/label_type.dart';
import 'package:inventory_management/models/part.dart';
import 'package:inventory_management/models/part_type.dart';
import 'package:inventory_management/models/part_maker.dart';
import 'package:inventory_management/providers/type_provider.dart';
import 'package:inventory_management/providers/maker_provider.dart';
import 'package:inventory_management/repository/part_repository.dart';
import 'package:inventory_management/widgets/dialogs.dart';
import 'package:inventory_management/widgets/icon_label.dart';
import 'package:provider/provider.dart';

class PartSelectDialog extends StatefulWidget {

  const PartSelectDialog({super.key});

  @override
  State<PartSelectDialog> createState() => _PartSelectDialogState();
}

class _PartSelectDialogState extends State<PartSelectDialog> {
  late PartType selectedType;
  late PartMaker selectedMaker;

  final TextEditingController specFieldController = TextEditingController();

  final List<DataColumn> columns = [
    DataColumn(label: Text('품명')),
    DataColumn(label: Text('규격')),
    DataColumn(label: Text('제조사')),
    DataColumn(label: Text('단위')),
  ];
  late PartDataSource _dataSource;
  Key dataTableKey = UniqueKey();
  List<Part> inquiredParts = [];
  Part? selectedPart;

  @override
  void initState() {
    super.initState();
    final typeProvider = Provider.of<TypeProvider>(context, listen: false);
    selectedType = typeProvider.allType;
    typeProvider.reloadTypes();

    final makerProvider = Provider.of<MakerProvider>(context, listen: false);
    selectedMaker = makerProvider.allMaker;
    makerProvider.reloadMakers();
  }

  void getParts() async {
    final typeProvider = Provider.of<TypeProvider>(context, listen: false);
    final makerProvider = Provider.of<MakerProvider>(context, listen: false);
    PartRepository partRepo = PartRepository();
    
    final isAllType = selectedType == typeProvider.allType;
    final isAllMaker = selectedMaker == makerProvider.allMaker;
    final specText = specFieldController.text.trim();
    
    inquiredParts = await switch ((isAllType, isAllMaker, specText.isEmpty)) {
      (true, true, true) => partRepo.getAllParts(),
      (false, true, true) => partRepo.getPartsByType(selectedType.id!),
      (true, false, true) => partRepo.getPartsByMaker(selectedMaker.id!),
      _ => partRepo.getPartsByFilter(
              isAllType ? null : selectedType.id!,
              isAllMaker ? null : selectedMaker.id!,
              specText.isEmpty ? null : specText,
            ),
    };

    selectedPart = null;
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    final typeProvider = Provider.of<TypeProvider>(context);
    final makerProvider = Provider.of<MakerProvider>(context);

    _dataSource = PartDataSource(
      parts: inquiredParts,
      selectedParts: (selectedPart == null) ? {} : {selectedPart!},
      onSelectChanged: (part, selected) {
        setState(() {
          if (selected) {
            selectedPart = part;
          } else {
            selectedPart = null;
          }
        });
      },
    );

    return AlertDialog(
      title: Text('부품 선택'),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                DropdownMenu<PartType>(
                  label: IconLabel(labelType: LabelType.type),
                  enableFilter: true,
                  menuHeight: 400,
                  width: 180,
                  onSelected: (type) {
                    selectedType = type!;
                    getParts();
                    dataTableKey = UniqueKey();
                  },
                  dropdownMenuEntries:
                      typeProvider.typesDropdownWithAll,
                ),
                DropdownMenu<PartMaker>(
                  label: IconLabel(labelType: LabelType.maker),
                  enableFilter: true,
                  menuHeight: 400,
                  width: 180,
                  onSelected: (maker) {
                    selectedMaker = maker!;
                    getParts();
                    dataTableKey = UniqueKey();
                  },
                  dropdownMenuEntries:
                      makerProvider.makersDropdownWithAll,
                ),
                SizedBox(
                  width: 180,
                  child: TextField(
                    controller: specFieldController,
                    decoration: InputDecoration(
                      label: IconLabel(labelType: LabelType.specification),
                      hintText: "입력 후 엔터",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (sectionName) {
                      dataTableKey = UniqueKey();
                      getParts();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SizedBox(
              width: 700,
              child: SingleChildScrollView(
                child: PaginatedDataTable(
                  key: dataTableKey,
                  columns: columns,
                  source: _dataSource,
                  rowsPerPage: 10,
                  showCheckboxColumn: true,
                  onSelectAll: (selected) {},
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            if (selectedPart != null) {
              Navigator.of(context).pop(selectedPart);              
            }
            else {
              showDialog(
                context: context,
                builder: (context) => ErrorDialog(
                  message: '부품을 선택해주세요.',
                ),
              );
            }
          },
          child: Text('확인'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('취소'),
        ),
      ],
    );
  }
}