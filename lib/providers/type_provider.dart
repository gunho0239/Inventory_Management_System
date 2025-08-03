import 'package:flutter/material.dart';
import 'package:inventory_management/constants/default_dropdownmenuitem.dart';
import 'package:inventory_management/models/part_type.dart';
import 'package:inventory_management/repository/part_type_repository.dart';

class TypeProvider extends ChangeNotifier {
  List<PartType> _types = [];
  List<DropdownMenuItem<String>> _typesDropdown = [];

  List<PartType> get types => _types;
  List<DropdownMenuItem<String>> get typesDropdown => _typesDropdown;

  Future<void> reloadTypes() async {
    _types = await PartTypeRepository().getAllPartTypes();
    
    _typesDropdown = [
      DropdownMenuItem<String>(
        value: defaultId.toString(),
        child: Text(defaultLabel),
      ),
      ..._types.map((type) => DropdownMenuItem<String>(
        value: type.id.toString(),
        child: Text(type.type!),
      ))
    ];
    notifyListeners();
  }
}