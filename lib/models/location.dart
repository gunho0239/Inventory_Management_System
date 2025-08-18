import 'package:inventory_management/models/location_section.dart';

class Location {
  final int? id;
  final LocationSection section;
  final int number;

  Location({this.id, required this.section, required this.number});

  factory Location.fromJson(Map<String, dynamic> json) =>
      Location(
        id: json['id'],
        section: LocationSection.fromJson(json['section']),
        number: json['number'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'section': section.toJson(),
        'number': number,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Location &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          section == other.section &&
          number == other.number;

  @override
  int get hashCode => id.hashCode;
}