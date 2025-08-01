class PartType {
  final int? id;
  final String? type;

  PartType({this.id, required this.type});

  factory PartType.fromJson(Map<String, dynamic> json) =>
      PartType(id: json['id'], type: json['type']);

  Map<String, dynamic> toJson() => {'id': id, 'type': type};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PartType && runtimeType == other.runtimeType && id == other.id && type == other.type;

  @override
  int get hashCode => Object.hash(id, type);
}
