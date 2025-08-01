class PartMaker {
  final int? id;
  final String? maker;

  PartMaker({this.id, required this.maker});

  factory PartMaker.fromJson(Map<String, dynamic> json) =>
      PartMaker(id: json['id'], maker: json['maker']);

  Map<String, dynamic> toJson() => {'id': id, 'maker': maker};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PartMaker && runtimeType == other.runtimeType && id == other.id && maker == other.maker;

  @override
  int get hashCode => Object.hash(id, maker);
}
