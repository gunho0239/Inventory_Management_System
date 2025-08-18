import 'package:flutter/material.dart';
import 'package:inventory_management/main.dart';
import 'package:inventory_management/screens/location_register_screen.dart';
import 'package:inventory_management/screens/maker_register_screen.dart';
import 'package:inventory_management/screens/part_register_screen.dart';
import 'package:inventory_management/screens/section_register_screen.dart';
import 'package:inventory_management/screens/type_register_screen.dart';
import 'package:inventory_management/screens/unit_register_screen.dart';
import 'package:inventory_management/style/style.dart';

class GoBackButton extends StatelessWidget {
  final bool refresh;

  // const GoBackButton({super.key});
  const GoBackButton({super.key, this.refresh = false});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: AppButtonStyle.backPage,
      onPressed: () {
        Navigator.pop(context, refresh);
        // Navigator.pop(context);
      },
      child: Icon(Icons.arrow_back, size: 30),
    );
  }
}

class RegisterPageButton extends StatelessWidget {
  late final String menuName;
  late final Widget? registerScreen;
  final VoidCallback? onPressed;

  RegisterPageButton(InventoryMenu menu, {super.key, this.onPressed}) {
    switch (menu) {
      case InventoryMenu.stockRegister:
        menuName = '재고';
        // registerScreen = const StockRegisterScreen();
        break;
      case InventoryMenu.partRegister:
        menuName = '부품';
        registerScreen = const PartRegisterScreen();
        break;
      case InventoryMenu.typeRegister:
        menuName = '품명';
        registerScreen = const TypeRegisterScreen();
        break;
      case InventoryMenu.makerRegister:
        menuName = '제조사';
        registerScreen = const MakerRegisterScreen();
        break;
      case InventoryMenu.unitRegister:
        menuName = '단위';
        registerScreen = const UnitRegisterScreen();
        break;
      case InventoryMenu.locationRegister:
        menuName = '위치';
        registerScreen = const LocationRegisterScreen();
        break;
      case InventoryMenu.sectionRegister:
        menuName = '구역';
        registerScreen = const SectionRegisterScreen();
        break;
      default:
        menuName = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: AppButtonStyle.newPage,
      onPressed: onPressed ?? () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => registerScreen!),
        );
      },
      child: Row(
        spacing: 10,
        children: [
          Icon(Icons.add, size: 20),
          Text('새로운 $menuName', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}

class RefreshButton extends StatelessWidget {
  final VoidCallback onPressed;

  const RefreshButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: AppButtonStyle.refresh,
      onPressed: onPressed,
      child: Icon(Icons.refresh, size: 30),
    );
  }
}

class SaveAllButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SaveAllButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Row(
        spacing: 5,
        children: [
          Icon(Icons.save, size: 30),
          Text('전체등록', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}

class DeleteButton extends StatelessWidget {
  final VoidCallback onPressed;

  const DeleteButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Row(
        spacing: 5,
        children: [
          Icon(Icons.delete, size: 30),
          Text('삭제', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}

class ReleaseButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ReleaseButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: AppButtonStyle.newPage,
      child: Row(
        spacing: 5,
        children: [
          Icon(Icons.logout, size: 30),
          Text('출고(사용)', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}

class QuantityChangeButton extends StatelessWidget {
  final VoidCallback onPressed;

  const QuantityChangeButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: AppButtonStyle.newPage,
      child: Row(
        spacing: 5,
        children: [
          Icon(Icons.exposure_plus_1, size: 30),
          Text('수량변경', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}

class LocationChangeButton extends StatelessWidget {
  final VoidCallback onPressed;

  const LocationChangeButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: AppButtonStyle.newPage,
      child: Row(
        spacing: 5,
        children: [
          Icon(Icons.edit_location_outlined, size: 30),
          Text('위치변경', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}