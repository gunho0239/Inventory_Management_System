import 'package:flutter/material.dart';
import 'package:inventory_management/constants/default_dropdownmenuitem.dart';
import 'package:inventory_management/models/location_section.dart';
import 'package:inventory_management/repository/location_section_repository.dart';

class SectionProvider extends ChangeNotifier {
  List<LocationSection> _sections = [];
  List<DropdownMenuItem<String>> _sectionsDropdown = [];

  List<LocationSection> get sections => _sections;
  List<DropdownMenuItem<String>> get sectionsDropdown => _sectionsDropdown;

  Future<void> reloadSections() async {
    _sections = await LocationSectionRepository().getAllLocationSections();
    
    _sectionsDropdown = [
      DropdownMenuItem<String>(
        value: defaultId.toString(),
        child: Text(defaultLabel),
      ),
      ..._sections.map((section) => DropdownMenuItem<String>(
        value: section.id.toString(),
        child: Text(section.section!),
      ))
    ];
    notifyListeners();
  }
}