import 'package:inventory_management/models/location.dart';
import 'package:inventory_management/models/stock.dart';

class LocationChangedStock {
  final Stock stock;
  Location? moveLocation;
  int moveQuantity;

  LocationChangedStock({
    required this.stock,
  }) : moveQuantity = stock.quantity ?? 0;
}