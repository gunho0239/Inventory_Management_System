import 'package:inventory_management/models/location.dart';
import 'package:inventory_management/models/part.dart';

class Stock {
  final int? id;
  final Part? part;
  final int? quantity;
  final Location? location;
  final int? version;

  Stock({this.id, this.part, this.quantity, this.location, this.version});

  factory Stock.fromJson(Map<String, dynamic> json) =>
      Stock(
        id: json['id'],
        part: Part.fromJson(json['part']),
        quantity: json['quantity'],
        location: Location.fromJson(json['location']),
        version: json['version'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'part': part?.toJson(),
        'quantity': quantity,
        'location': location?.toJson(),
        'version': version,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Stock &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          part == other.part &&
          quantity == other.quantity &&
          location == other.location &&
          version == other.version;

  @override
  int get hashCode => id.hashCode ^ part.hashCode ^ quantity.hashCode ^ location.hashCode ^ version.hashCode;
}