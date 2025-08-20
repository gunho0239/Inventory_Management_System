class Person {
  final int? id;
  final String? name;

  Person({this.id, required this.name});

  factory Person.fromJson(Map<String, dynamic> json) =>
      Person(id: json['id'], name: json['name']);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Person && runtimeType == other.runtimeType && id == other.id && name == other.name;

  @override
  int get hashCode => Object.hash(id, name);
}
