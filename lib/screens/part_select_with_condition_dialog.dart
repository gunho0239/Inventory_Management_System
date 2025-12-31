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

  const PartSelectWithConditionDialog({super.key, this.selectedType, this.selectedMaker, this.specFilter});

  @override
  State<PartSelectWithConditionDialog> createState() => _PartSelectWithConditionDialogState();
}

class _PartSelectWithConditionDialogState extends State<PartSelectWithConditionDialog> {
  late PartType selectedType;
  late PartMaker selectedMaker;

  final TextEditingController _typeFieldController = TextEditingController();
  final TextEditingController _makerFieldController = TextEditingController();
  final TextEditingController _specFieldController = TextEditingController();

  final List<DataColumn> columns = [
    DataColumn(label: Text(type)),
    DataColumn(label: Text(specification)),
    DataColumn(label: Text(maker)),
    DataColumn(label: Text(unit)),
  ];
  late PartDataSource _dataSource;
  Key dataTableKey = UniqueKey();
  List<Part> inquiredParts = [];
  Part? selectedPart;

  @override
  void initState() {
    super.initState();
    final typeProvider = Provider.of<TypeProvider>(context, listen: false);
    if (widget.selectedType != null) {
      selectedType = widget.selectedType!;
    } else {
      selectedType = typeProvider.allType;
    }
    _typeFieldController.text = selectedType.type ?? "";
    typeProvider.reloadTypes();

    final makerProvider = Provider.of<MakerProvider>(context, listen: false);
    if (widget.selectedMaker != null) {
      selectedMaker = widget.selectedMaker!;
    } else {
      selectedMaker = makerProvider.allMaker;
    }
    _makerFieldController.text = selectedMaker.maker ?? "";
    makerProvider.reloadMakers();

    if (widget.specFilter != null) {
      _specFieldController.text = widget.specFilter!;
    }

    getParts();
  }

  void getParts() async {
    final typeProvider = Provider.of<TypeProvider>(context, listen: false);
    final makerProvider = Provider.of<MakerProvider>(context, listen: false);
    PartRepository partRepo = PartRepository();
    
    final isAllType = selectedType == typeProvider.allType;
    final isAllMaker = selectedMaker == makerProvider.allMaker;
    final specText = _specFieldController.text.trim();
    
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
    final tableOptionsProvider = context.watch<DataTableOptionsProvider>();

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
      content: SizedBox(
        width: 1300,
        child: Row(
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
                    controller: _typeFieldController,
                    label: IconLabel(labelType: LabelType.type),
                    enableFilter: true,
                    menuHeight: 400,
                    width: 180,
                    onSelected: (type) {
                      if (type != null) {
                        selectedType = type;
                        getParts();
                        dataTableKey = UniqueKey();
                      }
                    },
                    dropdownMenuEntries:
                        typeProvider.typesDropdownWithAll,
                  ),
                  DropdownMenu<PartMaker>(
                    controller: _makerFieldController,
                    label: IconLabel(labelType: LabelType.maker),
                    enableFilter: true,
                    menuHeight: 400,
                    width: 180,
                    onSelected: (maker) {
                      if (maker != null) {
                        selectedMaker = maker;
                        getParts();
                        dataTableKey = UniqueKey();
                      }
                    },
                    dropdownMenuEntries:
                        makerProvider.makersDropdownWithAll,
                  ),
                  SizedBox(
                    width: 180,
                    child: TextField(
                      controller: _specFieldController,
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
            Flexible(
              child: SingleChildScrollView(
                child: PaginatedDataTable(
                  key: dataTableKey,
                  columns: columns,
                  source: _dataSource,
                  rowsPerPage: tableOptionsProvider.rowsPerPage,
                  availableRowsPerPage: tableOptionsProvider.availableRowsPerPage,
                  onRowsPerPageChanged: (value) {
                    if (value != null) {
                      tableOptionsProvider.updateRowsPerPage(value);
                    }
                  },
                  showCheckboxColumn: true,
                  onSelectAll: (selected) {},
                ),
              ),
            ),
          ],
        ),
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