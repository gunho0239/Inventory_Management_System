import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:inventory_management/enums/inventory_menu.dart';
import 'package:inventory_management/providers/category_provider.dart';
import 'package:inventory_management/providers/maker_provider.dart';
import 'package:inventory_management/providers/person_provider.dart';
import 'package:inventory_management/providers/theme_provider.dart';
import 'package:inventory_management/providers/type_provider.dart';
import 'package:inventory_management/providers/unit_provider.dart';
import 'package:inventory_management/screens/part_management_screen.dart';
import 'package:inventory_management/screens/stock_history_screen.dart';
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
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SectionProvider()),
        ChangeNotifierProvider(create: (_) => TypeProvider()),
        ChangeNotifierProvider(create: (_) => MakerProvider()),
        ChangeNotifierProvider(create: (_) => UnitProvider()),
        ChangeNotifierProvider(create: (_) => PersonProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [
              const Locale('ko', 'KR'),
              const Locale('en', 'US'),
            ],
            theme: ThemeData.light(), // 기본 라이트 테마
            darkTheme: ThemeData.dark(),
            themeMode: themeProvider.themeMode,
            title: 'LSENG Inventory Management System',
            home: const MainApp()
          );
        }
      )
    ),
  );
    
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  InventoryMenu selectedMenu = InventoryMenu.stockManagement;

  final Map<InventoryMenu, Widget> pages = {
    InventoryMenu.stockManagement: StockManagementScreen(),
    InventoryMenu.stockRegister: StockRegisterScreen(),
    InventoryMenu.partManagement: PartManagementScreen(),
    InventoryMenu.locationManagement: LocationManagementScreen(),
    InventoryMenu.stockHistory: StockHistoryScreen(),
  };

  void onMenuSelect(InventoryMenu menu) {
    setState(() {
      selectedMenu = menu;
    });
  }

  Widget buildPage() => pages[selectedMenu] ?? Center(child: Text('선택된 메뉴가 없습니다.'));

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(); // 무한 반복

    Provider.of<CategoryProvider>(context, listen: false).reloadCategories();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Column(
            children: [
              Expanded(
                child: SizedBox(
                  width: 200,
                  child: SideNavigationBar(
                    selectedMenu: selectedMenu,
                    onMenuSelect: onMenuSelect,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
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
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("2025.08.25    leegunho", style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
          Expanded(
            child: Stack(
              children: [
                buildPage(),
                Positioned(
                  top: 20,
                  right: 20,
                  child: Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return FloatingActionButton(
                        mini: true,
                        onPressed: themeProvider.toggleTheme,
                        tooltip: themeProvider.isDarkMode ? '라이트 모드로 전환' : '다크 모드로 전환',
                        child: Icon(
                          themeProvider.isDarkMode 
                            ? Icons.light_mode 
                            : Icons.dark_mode,
                        ),
                      );
                    },
                  ),
                ),
              ]
            )
          ),
        ],
      ),
    );
  }
}

