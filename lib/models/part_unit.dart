class PartUnit {
  final int? id;
  final String? unit;

  PartUnit({this.id, required this.unit});

  factory PartUnit.fromJson(Map<String, dynamic> json) =>
      PartUnit(id: json['id'], unit: json['unit']);

  Map<String, dynamic> toJson() => {'id': id, 'unit': unit};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PartUnit && runtimeType == other.runtimeType && id == other.id && unit == other.unit;

  @override
  int get hashCode => Object.hash(id, unit);
}
