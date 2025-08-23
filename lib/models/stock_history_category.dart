class StockHistoryCategory {
  final int? id;
  final String category;

  StockHistoryCategory({this.id, required this.category});

  factory StockHistoryCategory.fromJson(Map<String, dynamic> json) =>
      StockHistoryCategory(id: json['id'], category: json['category']);

  Map<String, dynamic> toJson() => {'id': id, 'category': category};

  bool get isRegister => category == StockHistoryCategoryType.register.value;
  bool get isRelease => category == StockHistoryCategoryType.release.value;
  bool get isQuantityChange => category == StockHistoryCategoryType.quantityChange.value;
  bool get isLocationChange => category == StockHistoryCategoryType.locationChange.value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockHistoryCategory && runtimeType == other.runtimeType && id == other.id && category == other.category;

  @override
  int get hashCode => Object.hash(id, category);
}

enum StockHistoryCategoryType {
  register("재고등록"),
  release("출고(사용)"),
  quantityChange("수량변경"),
  locationChange("위치변경");

  const StockHistoryCategoryType(this.value);
  final String value;
}
