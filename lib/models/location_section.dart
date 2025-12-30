class LocationSection {
  final int? id;
  final String? section;

  LocationSection({this.id, required this.section});

  factory LocationSection.fromJson(Map<String, dynamic> json) =>
      LocationSection(id: json['id'], section: json['section']);

  Map<String, dynamic> toJson() => {'id': id, 'section': section};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationSection && 
      runtimeType == other.runtimeType && 
      id == other.id && section == other.section;

  @override
  int get hashCode => Object.hash(id, section);
}
