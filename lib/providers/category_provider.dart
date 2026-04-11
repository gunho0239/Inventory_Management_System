import 'package:flutter/material.dart';
import 'package:inventory_management/constants/default_dropdownmenuitem.dart';
import 'package:inventory_management/models/stock_history_category.dart';
import 'package:inventory_management/repository/stock_history_category_repository.dart';

class CategoryProvider extends ChangeNotifier {
  StockHistoryCategory allCategory = StockHistoryCategory(id: defaultId, category: StockHistoryCategoryType.all);
  List<StockHistoryCategory> _categories = [];
  List<DropdownMenuEntry<StockHistoryCategory>> _categoriesDropdown = [];

  List<StockHistoryCategory> get categories => _categories;
  List<DropdownMenuEntry<StockHistoryCategory>> get categoriesDropdown => _categoriesDropdown;
  List<DropdownMenuEntry<StockHistoryCategory>> get categoriesDropdownWithAll => [
    DropdownMenuEntry<StockHistoryCategory>(
      value: allCategory,
      label: allCategory.category.value,
    ),
    ..._categoriesDropdown,
  ];

  Future<void> reloadCategories() async {
    _categories = await StockHistoryCategoryRepository().getAllStockHistoryCategories();

    _categoriesDropdown = _categories.map((category) => DropdownMenuEntry<StockHistoryCategory>(
        value: category,
        label: category.category.value,
      )).toList();

    notifyListeners();
  }

  StockHistoryCategory getCategory(StockHistoryCategoryType categoryType) {
    return _categories.firstWhere((category) => category.category.value == categoryType.value);
  }
}