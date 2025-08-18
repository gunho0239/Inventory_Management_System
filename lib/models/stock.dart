import 'package:inventory_management/models/location.dart';
import 'package:inventory_management/models/part.dart';

class Stock {
  final int? id;
  final Part? part;
  final int? quantity;
  final Location? location;

  Stock({this.id, this.part, this.quantity, this.location});

  factory Stock.fromJson(Map<String, dynamic> json) =>
      Stock(
        id: json['id'],
        part: Part.fromJson(json['part']),
        quantity: json['quantity'],
        location: Location.fromJson(json['location']),
      );

  Map<String, dynamic> toJson() => {
        'part': part?.toJson(),
        'quantity': quantity,
        'location': location?.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Stock &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          part == other.part &&
          quantity == other.quantity &&
          location == other.location;

  @override
  int get hashCode => id.hashCode ^ part.hashCode ^ quantity.hashCode ^ location.hashCode;
}