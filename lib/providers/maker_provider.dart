import 'package:flutter/material.dart';
import 'package:inventory_management/constants/default_dropdownmenuitem.dart';
import 'package:inventory_management/models/part_maker.dart';
import 'package:inventory_management/repository/part_maker_repository.dart';

class MakerProvider extends ChangeNotifier {
  List<PartMaker> _makers = [];
  List<DropdownMenuItem<String>> _makersDropdown = [];

  List<PartMaker> get makers => _makers;
  List<DropdownMenuItem<String>> get makersDropdown => _makersDropdown;

  Future<void> reloadMakers() async {
    _makers = await PartMakerRepository().getAllPartMakers();
    
    _makersDropdown = [
      DropdownMenuItem<String>(
        value: defaultId.toString(),
        child: Text(defaultLabel),
      ),
      ..._makers.map((maker) => DropdownMenuItem<String>(
        value: maker.id.toString(),
        child: Text(maker.maker!),
      ))
    ];
    notifyListeners();
  }
}