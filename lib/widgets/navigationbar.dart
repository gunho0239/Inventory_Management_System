import 'package:flutter/material.dart';
import 'package:inventory_management/enums/inventory_menu.dart';
import 'package:inventory_management/widgets/icons.dart';

class SideNavigationBar extends StatelessWidget {
  final InventoryMenu selectedMenu;
  final Function(InventoryMenu) onMenuSelect;

  const SideNavigationBar({
    super.key,
    required this.selectedMenu,
    required this.onMenuSelect,
  });

  Widget navButton(String title, InventoryMenu menu) {
    return ListTile(
      leading: getIcon(menu),
      title: Text(title),
      selected: selectedMenu == menu,
      onTap: () => onMenuSelect(menu),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        navButton('재고조회', InventoryMenu.stockManagement),
        ExpansionTile(
          leading: Icon(MenuIcons.register, size: 20),
          title: Text('신규등록'),
          childrenPadding: const EdgeInsets.only(left: 16.0),
          children: [
            navButton('재고등록', InventoryMenu.stockRegister),
            navButton('부품관리', InventoryMenu.partManagement),
            navButton('위치관리', InventoryMenu.locationManagement),
          ],
        ),
        navButton('변동내역', InventoryMenu.stockHistory),
      ],
    );
  }

  Widget getIcon(InventoryMenu menu) {
    switch (menu) {
      case InventoryMenu.stockManagement:
        return Icon(MenuIcons.stockInquiry, size: 20);
      case InventoryMenu.stockRegister:
        return Icon(MenuIcons.stockRegister, size: 20);
      case InventoryMenu.partManagement:
        return Icon(MenuIcons.part, size: 20);
      case InventoryMenu.locationManagement:
        return Icon(MenuIcons.location, size: 20);
      case InventoryMenu.stockHistory:
        return Icon(MenuIcons.history, size: 20);
      default:
        return Icon(Icons.help, size: 20);
    }
  }
}