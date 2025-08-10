import 'package:flutter/material.dart';
import 'package:inventory_management/constants/default_dropdownmenuitem.dart';
import 'package:inventory_management/models/location_section.dart';
import 'package:inventory_management/repository/location_section_repository.dart';

class SectionProvider extends ChangeNotifier {
  LocationSection allSection = LocationSection(id: defaultId, section: defaultLabel);
  List<LocationSection> _sections = [];
  List<DropdownMenuEntry<LocationSection>> _sectionsDropdown = [];

  List<LocationSection> get sections => _sections;
  List<DropdownMenuEntry<LocationSection>> get sectionsDropdown => _sectionsDropdown;
  List<DropdownMenuEntry<LocationSection>> get sectionsDropdownWithAll => [
    DropdownMenuEntry<LocationSection>(
      value: allSection,
      label: allSection.section!,
    ),
    ..._sectionsDropdown,
  ];

  Future<void> reloadSections() async {
    _sections = await LocationSectionRepository().getAllLocationSections();
    
    _sectionsDropdown = _sections.map((section) => DropdownMenuEntry<LocationSection>(
        value: section,
        label: section.section!,
      )).toList();

    notifyListeners();
  }
}