import 'package:flutter/material.dart';
import 'package:inventory_management/providers/maker_provider.dart';
import 'package:inventory_management/providers/part_provider.dart';
import 'package:inventory_management/providers/type_provider.dart';
import 'package:inventory_management/providers/unit_provider.dart';
import 'package:inventory_management/screens/part_management_screen.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/providers/section_provider.dart';
import 'package:inventory_management/widgets/navigationbar.dart';

import 'screens/location_management_screen.dart';
import 'screens/stock_management_screen.dart';
import 'screens/stock_register_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SectionProvider()),
        ChangeNotifierProvider(create: (_) => PartProvider()),
        ChangeNotifierProvider(create: (_) => TypeProvider()),
        ChangeNotifierProvider(create: (_) => MakerProvider()),
        ChangeNotifierProvider(create: (_) => UnitProvider()),
      ],
      child: MaterialApp(home: const MainApp())
    ),
  );
    
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  InventoryMenu selectedMenu = InventoryMenu.stockManagement;

  final Map<InventoryMenu, Widget> pages = {
    InventoryMenu.stockManagement: StockManagementScreen(),
    InventoryMenu.stockRegister: StockRegisterScreen(),
    InventoryMenu.partManagement: PartManagementScreen(),
    InventoryMenu.locationManagement: LocationManagementScreen(),
  };

  void onMenuSelect(InventoryMenu menu) {
    setState(() {
      selectedMenu = menu;
    });
  }

  Widget buildPage() => pages[selectedMenu] ?? Center(child: Text('선택된 메뉴가 없습니다.'));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            width: 200,
            child: SideNavigationBar(
              selectedMenu: selectedMenu,
              onMenuSelect: onMenuSelect,
            ),
          ),
          Expanded(child: buildPage()),
        ],
      ),
    );
  }
}

enum InventoryMenu {
    stockManagement,   // 재고 조회
    stockRegister,    // 재고 등록
    partManagement,   // 부품 관리
    partRegister,     // 부품 등록
    typeManagement,   // 품명 관리
    typeRegister,     // 품명명 등록
    makerManagement,  // 제조사 관리
    makerRegister,    // 제조사 등록
    unitManagement,   // 단위 관리
    unitRegister,     // 단위 등록
    locationManagement,    // 위치 관리
    locationRegister,      // 위치 등록
    sectionManagement,     // 구역 관리
    sectionRegister,       // 구역 등록
    history,     // 변동 내역
}