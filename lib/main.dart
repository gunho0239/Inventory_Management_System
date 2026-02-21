import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:inventory_management/screens/backup_management_screen.dart';
import 'package:window_manager/window_manager.dart';
import 'package:inventory_management/enums/inventory_menu.dart';
import 'package:inventory_management/providers/category_provider.dart';
import 'package:inventory_management/providers/data_table_options_provider.dart';
import 'package:inventory_management/providers/maker_provider.dart';
import 'package:inventory_management/providers/person_provider.dart';
import 'package:inventory_management/providers/theme_provider.dart';
import 'package:inventory_management/providers/type_provider.dart';
import 'package:inventory_management/providers/unit_provider.dart';
import 'package:inventory_management/screens/part_management_screen.dart';
import 'package:inventory_management/screens/stock_history_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/providers/section_provider.dart';
import 'package:inventory_management/widgets/navigationbar.dart';
import 'screens/location_management_screen.dart';
import 'screens/stock_management_screen.dart';
import 'screens/stock_register_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await windowManager.ensureInitialized();
  WindowOptions windowOptions = const WindowOptions(
    minimumSize: Size(1000, 500),
    center: true,
    title: "LSENG 재고 관리 시스템",
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.maximize();
    await windowManager.show();
    await windowManager.focus();
  });
  
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
        ChangeNotifierProvider(create: (_) => DataTableOptionsProvider()),
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
            scrollBehavior: MyMaterialScrollBehavior(),
            theme: ThemeData.light().copyWith( // 기본 라이트 테마
              scrollbarTheme: ScrollbarThemeData(
                // thumbVisibility: WidgetStateProperty.all<bool>(true),
              ),
            ),
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

class MyMaterialScrollBehavior extends MaterialScrollBehavior {
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return Scrollbar(
      controller: details.controller,
      thumbVisibility: true,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: child,
      ),
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  InventoryMenu selectedMenu = InventoryMenu.stockManagement;
  bool _isCollapsed = false;
  String _appVersion = "";

  final Map<InventoryMenu, Widget> pages = {
    InventoryMenu.stockManagement: StockManagementScreen(),
    InventoryMenu.stockRegister: StockRegisterScreen(),
    InventoryMenu.partManagement: PartManagementScreen(),
    InventoryMenu.locationManagement: LocationManagementScreen(),
    InventoryMenu.stockHistory: StockHistoryScreen(),
    InventoryMenu.backupManagement: BackupManagementScreen(),
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

    getAppVersion();
    Provider.of<CategoryProvider>(context, listen: false).reloadCategories();
  }

  Future<void> getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    setState(() {
      _appVersion = packageInfo.version;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SideNavigationBar(
            selectedMenu: selectedMenu,
            onMenuSelect: onMenuSelect,
            isCollapsed: _isCollapsed,
            onToggle: () {
              setState(() => _isCollapsed = !_isCollapsed);
            },
            appVersion: _appVersion,
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

