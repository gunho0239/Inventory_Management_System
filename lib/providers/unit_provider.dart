import 'package:flutter/material.dart';
import 'package:inventory_management/constants/default_dropdownmenuitem.dart';
import 'package:inventory_management/models/part_unit.dart';
import 'package:inventory_management/repository/part_unit_repository.dart';

class UnitProvider extends ChangeNotifier {
  PartUnit allUnit = PartUnit(id: defaultId, unit: defaultLabel);
  List<PartUnit> _units = [];
  List<DropdownMenuEntry<PartUnit>> _unitsDropdown = [];

  List<PartUnit> get units => _units;
  List<DropdownMenuEntry<PartUnit>> get unitsDropdown => _unitsDropdown;
  List<DropdownMenuEntry<PartUnit>> get unitsDropdownWithAll => [
        DropdownMenuEntry<PartUnit>(
          value: allUnit,
          label: allUnit.unit!,
        ),
        ..._unitsDropdown
      ];

  Future<void> reloadUnits() async {
    _units = await PartUnitRepository().getAllPartUnits();
    
    _unitsDropdown = _units.map((unit) => DropdownMenuEntry<PartUnit>(
        value: unit,
        label: unit.unit!,
      )).toList();
      
    notifyListeners();
  }
}