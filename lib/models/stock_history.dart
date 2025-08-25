import 'package:inventory_management/models/stock_history_category.dart';

class StockHistory {
  final int? id;
  final DateTime? date;
  final StockHistoryCategory category;
  final String memo;
  final String type;
  final String specification;
  final String maker;
  final String unit;
  final int beforeQuantity;
  final int afterQuantity;
  final String beforeLocation;
  final String afterLocation;
  final String person;

  StockHistory({this.id, this.date, required this.category, required this.memo, required this.type, required this.specification, required this.maker, required this.unit, required this.beforeQuantity, required this.afterQuantity, required this.beforeLocation, required this.afterLocation, required this.person});


  String get formattedQuantity {
    if (category.isRelease) {
      return '${beforeQuantity - afterQuantity}';
    }
    else if (category.isQuantityChange) {
      return '$beforeQuantity -> $afterQuantity';
    }
    else { // stockHistory.category.isLocationChange || stockHistory.category.isRegister
      return afterQuantity.toString();
    }
  }

  String get formattedLocation {
    if (category.isLocationChange) {
      return '$beforeLocation -> $afterLocation';
    }
    else { // stockHistory.category.isRegister || stockHistory.category.isRelease || stockHistory.category.isQuantityChange
      return afterLocation;
    }
  }

  factory StockHistory.fromJson(Map<String, dynamic> json) =>
      StockHistory(
        id: json['id'],
        date: DateTime.parse(json['date']),
        category: StockHistoryCategory.fromJson(json['category']),
        memo: json['memo'],
        type: json['type'],
        specification: json['specification'],
        maker: json['maker'],
        unit: json['unit'],
        beforeQuantity: json['beforeQuantity'],
        afterQuantity: json['afterQuantity'],
        beforeLocation: json['beforeLocation'],
        afterLocation: json['afterLocation'],
        person: json['person'],
      );

  Map<String, dynamic> toJson() => {
        'memo': memo,
        'category': category.toJson(),
        'type': type,
        'specification': specification,
        'maker': maker,
        'unit': unit,
        'beforeQuantity': beforeQuantity,
        'afterQuantity': afterQuantity,
        'beforeLocation': beforeLocation,
        'afterLocation': afterLocation,
        'person': person,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockHistory &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          date == other.date &&
          memo == other.memo &&
          type == other.type &&
          specification == other.specification &&
          maker == other.maker &&
          unit == other.unit &&
          beforeQuantity == other.beforeQuantity &&
          afterQuantity == other.afterQuantity &&
          beforeLocation == other.beforeLocation &&
          afterLocation == other.afterLocation &&
          person == other.person;

  @override
  int get hashCode => id.hashCode ^ date.hashCode ^ memo.hashCode ^ type.hashCode ^ specification.hashCode ^ maker.hashCode ^ unit.hashCode ^ beforeQuantity.hashCode ^ afterQuantity.hashCode ^ beforeLocation.hashCode ^ afterLocation.hashCode ^ person.hashCode;
}