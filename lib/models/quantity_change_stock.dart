import 'package:inventory_management/models/stock.dart';

class QuantityChangedStock {
  final Stock stock;
  int newQuantity;

  QuantityChangedStock({
    required this.stock,
  }) : newQuantity = stock.quantity ?? 0;
}