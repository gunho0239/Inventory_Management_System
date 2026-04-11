import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataTableOptionsProvider with ChangeNotifier {
  static const int defaultRows = 50;
  static const List<int> availableRows = [5, 10, 20, 30, 40, 50, 100];
  static const String _key = 'rows_per_page';

  int _rowsPerPage = defaultRows;

  int get rowsPerPage => _rowsPerPage;
  List<int> get availableRowsPerPage => availableRows;


  DataTableOptionsProvider() {
    _loadFromPrefs();
  }


  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    int savedValue = prefs.getInt(_key) ?? defaultRows;

    if (availableRows.contains(savedValue)) {
      _rowsPerPage = savedValue;
    } else {
      _rowsPerPage = defaultRows;
    }
    notifyListeners();
  }

  Future<void> updateRowsPerPage(int value) async {
    _rowsPerPage = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, value);
  }
}