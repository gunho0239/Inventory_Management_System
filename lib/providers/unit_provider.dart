import 'package:flutter/material.dart';
import 'package:inventory_management/constants/default_dropdownmenuitem.dart';
import 'package:inventory_management/models/part_unit.dart';
import 'package:inventory_management/repository/part_unit_repository.dart';

class UnitProvider extends ChangeNotifier {
  List<PartUnit> _units = [];
  List<DropdownMenuItem<String>> _unitsDropdown = [];

  List<PartUnit> get units => _units;
  List<DropdownMenuItem<String>> get unitsDropdown => _unitsDropdown;

  Future<void> reloadUnits() async {
    _units = await PartUnitRepository().getAllPartUnits();
    
    _unitsDropdown = [
      DropdownMenuItem<String>(
        value: defaultId.toString(),
        child: Text(defaultLabel),
      ),
      ..._units.map((unit) => DropdownMenuItem<String>(
        value: unit.id.toString(),
        child: Text(unit.unit!),
      ))
    ];
    notifyListeners();
  }
}