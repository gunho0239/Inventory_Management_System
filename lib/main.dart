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
    minimumSize: Size(1000, 600),
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
            debugShowCheckedModeBanner: false,
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
            theme: ThemeData.light().copyWith(
              scrollbarTheme: const ScrollbarThemeData(),
              inputDecorationTheme: _textFieldDecorationTheme(ThemeData.light().colorScheme),
              dropdownMenuTheme: DropdownMenuThemeData(
                inputDecorationTheme: _dropdownDecorationTheme(),
              ),
            ),
            darkTheme: ThemeData.dark().copyWith(
              inputDecorationTheme: _textFieldDecorationTheme(ThemeData.dark().colorScheme),
              dropdownMenuTheme: DropdownMenuThemeData(
                inputDecorationTheme: _dropdownDecorationTheme(),
              ),
            ),
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

InputDecorationTheme _textFieldDecorationTheme(ColorScheme colorScheme) {
  return InputDecorationTheme(
    filled: true,
    fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300, width: 0.8),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300, width: 0.8),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.blueGrey, width: 1.0),
    ),
  );
}

InputDecorationTheme _dropdownDecorationTheme() {
  return InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300, width: 0.8),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300, width: 0.8),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.blueGrey, width: 1.0),
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
  bool _isCollapsed = false;
  String _appVersion = "";

  @override
  void initState() {
    super.initState();

    _getAppVersion();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false).reloadCategories();
    });
  }

  Widget _buildPage() {
    switch (selectedMenu) {
      case InventoryMenu.stockManagement: return const StockManagementScreen();
      case InventoryMenu.stockRegister: return const StockRegisterScreen();
      case InventoryMenu.partManagement: return const PartManagementScreen();
      case InventoryMenu.locationManagement: return const LocationManagementScreen();
      case InventoryMenu.stockHistory: return const StockHistoryScreen();
      case InventoryMenu.backupManagement: return const BackupManagementScreen();
      default: return const Center(child: Text('선택된 메뉴가 없습니다.'));
    }
  }

  Future<void> _getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _appVersion = packageInfo.version);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SideNavigationBar(
            selectedMenu: selectedMenu,
            onMenuSelect: (menu) => setState(() => selectedMenu = menu),
            isCollapsed: _isCollapsed,
            onToggle: () {
              setState(() => _isCollapsed = !_isCollapsed);
            },
            appVersion: _appVersion,
          ),
          Expanded(
            child: Stack(
              children: [
                _buildPage(),
                Positioned(
                  top: 20,
                  right: 20,
                  child: Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return FloatingActionButton(
                        mini: true,
                        elevation: 2,
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

