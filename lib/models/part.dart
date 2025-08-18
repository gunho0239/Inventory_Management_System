import 'package:inventory_management/models/part_maker.dart';
import 'package:inventory_management/models/part_type.dart';
import 'package:inventory_management/models/part_unit.dart';

class Part {
  final int? id;
  final PartType type;
  final String specification;
  final PartMaker maker;
  final PartUnit unit;

  Part({this.id, required this.type, required this.specification, required this.maker, required this.unit});

  factory Part.fromJson(Map<String, dynamic> json) =>
      Part(
        id: json['id'],
        type: PartType.fromJson(json['type']),
        specification: json['specification'],
        maker: PartMaker.fromJson(json['maker']),
        unit: PartUnit.fromJson(json['unit']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.toJson(),
        'specification': specification,
        'maker': maker.toJson(),
        'unit': unit.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Part &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          specification == other.specification &&
          maker == other.maker &&
          unit == other.unit;

  @override
  int get hashCode => id.hashCode;
}