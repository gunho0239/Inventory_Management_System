import 'package:flutter/material.dart';
import 'package:inventory_management/enums/inventory_menu.dart';
import 'package:inventory_management/widgets/icons.dart';

class SideNavigationBar extends StatefulWidget {
  final InventoryMenu selectedMenu;
  final Function(InventoryMenu) onMenuSelect;
  final bool isCollapsed;
  final VoidCallback onToggle;
  final String appVersion;

  const SideNavigationBar({
    super.key,
    required this.selectedMenu,
    required this.onMenuSelect,
    required this.isCollapsed,
    required this.onToggle,
    required this.appVersion,
  });

  @override
  State<SideNavigationBar> createState() => _SideNavigationBarState();
}

class _SideNavigationBarState extends State<SideNavigationBar> with TickerProviderStateMixin {
  late final AnimationController _rotationController;

  Widget _navButton(String title, InventoryMenu menu) {
    return ListTile(
      leading: getIcon(menu),
      title: widget.isCollapsed ? null : Text(title),
      selected: widget.selectedMenu == menu,
      onTap: () => widget.onMenuSelect(menu),
      minLeadingWidth: 0,
    );
  }

  Widget _buildAnimatedIcon() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 1.0),
      child: AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // 원근감 추가
              ..rotateY(_rotationController.value * 2 * 3.14159), // Y축 회전
            child: Image.asset(
              'lib/assets/logo.png',
              width: 150,
              height: 80,
              fit: BoxFit.contain,
            ),
          );
        }
      ),
    );
  }

  Widget _buildVersionInfoText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
      child: Text("v${widget.appVersion}  leegunho", style: TextStyle(color: Colors.grey)),
    );
  }

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(); // 무한 반복
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 0),
      width: widget.isCollapsed ? 100 : 200,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: IconButton(
              icon: Icon(widget.isCollapsed ? Icons.menu : Icons.arrow_back_ios_new),
              onPressed: widget.onToggle,
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _navButton('재고조회', InventoryMenu.stockManagement),
                ExpansionTile(
                    leading: Icon(MenuIcons.register, size: 20),
                    title: widget.isCollapsed ? const SizedBox.shrink() : const Text('신규등록'),
                    childrenPadding: const EdgeInsets.only(left: 16.0),
                    children: [
                      _navButton('재고등록', InventoryMenu.stockRegister),
                      _navButton('부품관리', InventoryMenu.partManagement),
                      _navButton('위치관리', InventoryMenu.locationManagement),
                    ],
                  ),
                _navButton('변동내역', InventoryMenu.stockHistory),
                _navButton('백업 관리', InventoryMenu.backupManagement),
              ],
            ),
          ),
          if (!widget.isCollapsed) _buildAnimatedIcon(),
          if (!widget.isCollapsed) _buildVersionInfoText(),
        ],
      ),
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
      case InventoryMenu.backupManagement:
        return Icon(MenuIcons.backup, size: 20);
      default:
        return Icon(Icons.help, size: 20);
    }
  }
}