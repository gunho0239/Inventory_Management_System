import 'package:flutter/material.dart';
import 'package:inventory_management/main.dart';
import 'package:inventory_management/widgets/icons.dart';

class ScreenTitle extends StatelessWidget {
  final InventoryMenu menu;

  const ScreenTitle({super.key, required this.menu});

  Widget getIcon() {
    switch (menu) {
      case InventoryMenu.partManagement:
      case InventoryMenu.partRegister:
        return Icon(MenuIcons.part, size: 30);
      case InventoryMenu.typeManagement:
      case InventoryMenu.typeRegister:
        return Icon(MenuIcons.type, size: 30);
      case InventoryMenu.makerManagement:
      case InventoryMenu.makerRegister:
        return Icon(MenuIcons.maker, size: 30);
      case InventoryMenu.unitManagement:
      case InventoryMenu.unitRegister:
        return Icon(MenuIcons.unit, size: 30);
      case InventoryMenu.locationManagement:
      case InventoryMenu.locationRegister:
        return Icon(MenuIcons.location, size: 30);
      case InventoryMenu.sectionManagement:
      case InventoryMenu.sectionRegister:
        return Icon(MenuIcons.section, size: 30);
      default:
        return Icon(Icons.inventory, size: 30);
    }
  }

  String get title {
    switch (menu) {
      case InventoryMenu.stockManagement:
        return '재고 조회';
      case InventoryMenu.stockRegister:
        return '재고 등록';
      case InventoryMenu.partManagement:
        return '부품 관리';
      case InventoryMenu.partRegister:
        return '부품 등록';
      case InventoryMenu.typeManagement:
        return '품명 관리';
      case InventoryMenu.typeRegister:
        return '품명 등록';
      case InventoryMenu.makerManagement:
        return '제조사 관리';
      case InventoryMenu.makerRegister:
        return '제조사 등록';
      case InventoryMenu.unitManagement:
        return '단위 관리';
      case InventoryMenu.unitRegister:
        return '단위 등록';
      case InventoryMenu.locationManagement:
        return '위치 관리';
      case InventoryMenu.locationRegister:
        return '위치 등록';
      case InventoryMenu.sectionManagement:
        return '구역 관리';
      case InventoryMenu.sectionRegister:
        return '구역 등록';
      case InventoryMenu.history:
        return '변동 내역';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 20.0),
      child: Row(
        spacing: 10,
        children: [
          getIcon(),
          Text(
            title,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
