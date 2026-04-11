import 'package:flutter/material.dart';
import 'package:inventory_management/constants/menu_name.dart';
import 'package:inventory_management/enums/inventory_menu.dart';
import 'package:inventory_management/screens/location_register_screen.dart';
import 'package:inventory_management/screens/maker_register_screen.dart';
import 'package:inventory_management/screens/part_register_screen.dart';
import 'package:inventory_management/screens/section_register_screen.dart';
import 'package:inventory_management/screens/type_register_screen.dart';
import 'package:inventory_management/screens/unit_register_screen.dart';
import 'package:inventory_management/style/style.dart';
import 'package:inventory_management/widgets/icons.dart';

class GoBackButton extends StatelessWidget {
  final bool refresh;

  const GoBackButton({super.key, this.refresh = false});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: AppButtonStyle.backPage,
      onPressed: () {
        Navigator.pop(context, refresh);
      },
      child: const Icon(Icons.arrow_back, size: 30), // const 추가
    );
  }
}

class GoFirstButton extends StatelessWidget {
  final bool refresh;

  const GoFirstButton({super.key, this.refresh = false});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: AppButtonStyle.home,
      onPressed: () {
        while (Navigator.canPop(context)) {
          Navigator.pop(context, refresh);
        }
      },
      child: const Icon(Icons.home, size: 30), // const 추가
    );
  }
}

class RegisterPageButton extends StatelessWidget {
  final InventoryMenu menu;
  final VoidCallback? onPressed;

  // 1. [개선] 생성자를 const로 변경하여 성능 최적화
  const RegisterPageButton(this.menu, {super.key, this.onPressed});

  // 2. [개선] Dart 3 Switch 표현식과 Record 활용
  (String, Widget?) get _info => switch (menu) {
        InventoryMenu.partRegister => ('부품', const PartRegisterScreen()),
        InventoryMenu.typeRegister => ('품명', const TypeRegisterScreen()),
        InventoryMenu.makerRegister => ('제조사', const MakerRegisterScreen()),
        InventoryMenu.unitRegister => ('단위', const UnitRegisterScreen()),
        InventoryMenu.locationRegister => ('위치', const LocationRegisterScreen()),
        InventoryMenu.sectionRegister => ('구역', const SectionRegisterScreen()),
        _ => ('', null),
      };

  @override
  Widget build(BuildContext context) {
    final (menuName, registerScreen) = _info;

    return ElevatedButton(
      style: AppButtonStyle.newPage,
      // 3. [개선] Null Safety 적용: registerScreen이 null일 때의 방어 코드 추가
      onPressed: onPressed ?? () {
        if (registerScreen != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => registerScreen),
          );
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min, // 버튼 내부 Row가 불필요하게 늘어나는 것 방지
        spacing: 10,
        children: [
          const Icon(Icons.add, size: 20),
          Text('새로운 $menuName', style: const TextStyle(fontSize: 18)),
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
      child: const Icon(Icons.refresh, size: 30),
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
      child: const Row(
        mainAxisSize: MainAxisSize.min,
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
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 5,
        children: [
          Icon(Icons.delete, size: 30),
          Text('삭제', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}

class EditButton extends StatelessWidget {
  final VoidCallback onPressed;

  const EditButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(Icons.edit, size: 30),
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
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 5,
        children: [
          Icon(MenuIcons.release, size: 30),
          Text(release, style: TextStyle(fontSize: 18)),
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
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 5,
        children: [
          Icon(MenuIcons.quantityChange, size: 30),
          Text(quantityChange, style: TextStyle(fontSize: 18)),
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
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 5,
        children: [
          Icon(MenuIcons.locationChange, size: 30),
          Text(locationChange, style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}

class PrintReleasedButton extends StatelessWidget {
  final VoidCallback onPressed;

  const PrintReleasedButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: AppButtonStyle.newPage,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 5,
        children: [
          Icon(MenuIcons.print, size: 30),
          Text(printReleased, style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}

class PrintButton extends StatelessWidget {
  final VoidCallback onPressed;

  const PrintButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: AppButtonStyle.newPage,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 5,
        children: [
          Icon(MenuIcons.print, size: 30),
          Text("출력", style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}