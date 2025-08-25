import 'package:flutter/material.dart';
import 'package:inventory_management/api/api_response_entity.dart';
import 'package:inventory_management/datatable_source/person_data.dart';
import 'package:inventory_management/models/person.dart';
import 'package:inventory_management/providers/person_provider.dart';
import 'package:inventory_management/repository/person_repository.dart';
import 'package:inventory_management/widgets/buttons.dart';
import 'package:inventory_management/widgets/dialogs.dart';
import 'package:provider/provider.dart';

class UserManagementDialog extends StatefulWidget {

  const UserManagementDialog({super.key});

  @override
  State<UserManagementDialog> createState() => _UserManagementDialogState();
}

class _UserManagementDialogState extends State<UserManagementDialog> {
  final TextEditingController _nameFieldController = TextEditingController();
  final FocusNode _nameFieldFocusNode = FocusNode();

  final List<DataColumn> _columns = [DataColumn(label: Text('이름')),];
  late PersonDataSource _dataSource;
  Key _dataTableKey = UniqueKey();
  List<Person> _inquiredPersons = [];
  Set<Person> _selectedPersons = {};

  @override
  void initState() {
    super.initState();
    final personProvider = Provider.of<PersonProvider>(context, listen: false);
    personProvider.reloadPersons();

    _inquiredPersons = personProvider.persons;
  }


  Future<void> registerPerson() async {
    final name = _nameFieldController.text.trim();

    if (name.isEmpty) return;

    final proceed = await showDialog<bool>(
      context: context,
      builder:(context) => ConfirmDialog(message: '사용자를 등록 하시겠습니까?'),
    );

    if(proceed == true) {
      final personRepo = PersonRepository();
      final personProvider = Provider.of<PersonProvider>(context, listen: false);

      await personRepo.addPerson(Person(name: name));
      if (!mounted) return;

      await personProvider.reloadPersons();
      _inquiredPersons = personProvider.persons;
      _dataTableKey = UniqueKey();

      setState(() {
        _nameFieldController.clear();
      });
    }
  }

  Future<void> deletePersons() async {
    if (_selectedPersons.isEmpty) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => ConfirmDialog(
          message: "선택한 사용자를 삭제하시겠습니까?",
        ),
      );
  
      if (confirmed == true) {
        List<int> personIds = _selectedPersons
            .map((person) => person.id!)
            .toList();
        BulkRequestResult result = await PersonRepository()
            .removePersons(personIds);
    
        if (!mounted) return;

        showDialog(
          context: context,
          builder: (context) => ResultDialog(
            message: "삭제 성공 : ${result.successCount}\n삭제 실패 : ${result.failedCount}",
          ),
        );

        final personProvider = Provider.of<PersonProvider>(context, listen: false);

        await personProvider.reloadPersons();
        _inquiredPersons = personProvider.persons;
        _dataTableKey = UniqueKey();
        _selectedPersons.clear();

        setState(() {});
      }
  }


  @override
  Widget build(BuildContext context) {

    _dataSource = PersonDataSource(
      persons: _inquiredPersons,
      selectedPersons: _selectedPersons,
      onSelectChanged: (person, selected) {
        setState(() {
          if (selected) {
            _selectedPersons.add(person);
          } else {
            _selectedPersons.remove(person);
          }
        });
      },
    );

    return AlertDialog(
      title: Text('시스템 사용자 관리'),
      content: Row(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: PaginatedDataTable(
                  key: _dataTableKey,
                  columns: _columns,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: 10,
                children: [
                  SizedBox(
                    width: 180,
                    child: TextField(
                      controller: _nameFieldController,
                      focusNode: _nameFieldFocusNode,
                      textAlign: TextAlign.start,
                      decoration: InputDecoration(
                        labelText: "사용자 이름",
                        hintText: "입력 후 엔터",
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (sectionName) {
                        registerPerson();
                      },
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      registerPerson();
                    },
                    child: Text('등록', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
              Spacer(flex: 1),
              Flexible(
                flex: 5,
                child: DeleteButton(
                  onPressed: () async {
                    deletePersons();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('닫기'),
        ),
      ],
    );
  }
}