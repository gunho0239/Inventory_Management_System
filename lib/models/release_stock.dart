import 'package:inventory_management/models/stock.dart';

class ReleaseStock {
  final Stock stock;
  int useQuantity;

  ReleaseStock({
    required this.stock,
  }) : useQuantity = 0;

}