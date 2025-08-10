import 'package:flutter/material.dart';
import 'package:inventory_management/constants/default_dropdownmenuitem.dart';
import 'package:inventory_management/models/part.dart';
import 'package:inventory_management/models/part_maker.dart';
import 'package:inventory_management/models/part_type.dart';
import 'package:inventory_management/models/part_unit.dart';
import 'package:inventory_management/repository/part_repository.dart';

class PartProvider extends ChangeNotifier {
  Part allPart = Part(
    id: defaultId, 
    specification: defaultLabel, 
    type: PartType(id: defaultId, type: defaultLabel), 
    maker: PartMaker(id: defaultId, maker: defaultLabel), 
    unit: PartUnit(id: defaultId, unit: defaultLabel));
  List<Part> _parts = [];
  List<DropdownMenuEntry<Part>> _partsDropdown = [];

  List<Part> get parts => _parts;
  List<DropdownMenuEntry<Part>> get partsDropdown => _partsDropdown;
  List<DropdownMenuEntry<Part>> get partsDropdownWithAll => [
    DropdownMenuEntry<Part>(
      value: allPart,
      label: allPart.specification,
    ),
    ..._partsDropdown,
  ];

  Future<void> reloadParts() async {
    _parts = await PartRepository().getAllParts();
    
    _partsDropdown = _parts.map((part) => DropdownMenuEntry<Part>(
        value: part,
        label: '${part.specification} (${part.maker.maker})',
      )).toList();

    notifyListeners();
  }
}