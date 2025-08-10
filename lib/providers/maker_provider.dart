import 'package:flutter/material.dart';
import 'package:inventory_management/constants/default_dropdownmenuitem.dart';
import 'package:inventory_management/models/part_maker.dart';
import 'package:inventory_management/repository/part_maker_repository.dart';

class MakerProvider extends ChangeNotifier {
  PartMaker allMaker = PartMaker(id: defaultId, maker: defaultLabel);
  List<PartMaker> _makers = [];
  List<DropdownMenuEntry<PartMaker>> _makersDropdown = [];

  List<PartMaker> get makers => _makers;
  List<DropdownMenuEntry<PartMaker>> get makersDropdown => _makersDropdown;
  List<DropdownMenuEntry<PartMaker>> get makersDropdownWithAll => [
    DropdownMenuEntry<PartMaker>(
      value: allMaker,
      label: allMaker.maker!,
    ),
    ..._makersDropdown,
  ];

  Future<void> reloadMakers() async {
    _makers = await PartMakerRepository().getAllPartMakers();
    
    _makersDropdown = _makers.map((maker) => DropdownMenuEntry<PartMaker>(
        value: maker,
        label: maker.maker!,
      )).toList();

    notifyListeners();
  }
}