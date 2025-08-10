import 'package:flutter/material.dart';
import 'package:inventory_management/constants/default_dropdownmenuitem.dart';
import 'package:inventory_management/models/part_type.dart';
import 'package:inventory_management/repository/part_type_repository.dart';

class TypeProvider extends ChangeNotifier {
  PartType allType = PartType(id: defaultId, type: defaultLabel);
  List<PartType> _types = [];
  List<DropdownMenuEntry<PartType>> _typesDropdown = [];

  List<PartType> get types => _types;
  List<DropdownMenuEntry<PartType>> get typesDropdown => _typesDropdown;
  List<DropdownMenuEntry<PartType>> get typesDropdownWithAll => [
    DropdownMenuEntry<PartType>(
      value: allType,
      label: allType.type!,
    ),
    ..._typesDropdown,
  ];

  Future<void> reloadTypes() async {
    _types = await PartTypeRepository().getAllPartTypes();
    
    _typesDropdown = _types.map((type) => DropdownMenuEntry<PartType>(
        value: type,
        label: type.type!,
      )).toList();

    notifyListeners();
  }
}