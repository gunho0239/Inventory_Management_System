class StockHistoryCategory {
  final int? id;
  final StockHistoryCategoryType category;

  StockHistoryCategory({this.id, required this.category});

  factory StockHistoryCategory.fromJson(Map<String, dynamic> json) =>
      StockHistoryCategory(
        id: json['id'],
        category: StockHistoryCategoryType.fromCode(json['category']),
      );

  Map<String, dynamic> toJson() => {'id': id, 'category': category.name};

  bool get isRegister => category == StockHistoryCategoryType.register;
  bool get isRelease => category == StockHistoryCategoryType.release;
  bool get isQuantityChange => category == StockHistoryCategoryType.quantityChange;
  bool get isLocationChange => category == StockHistoryCategoryType.locationChange;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockHistoryCategory && runtimeType == other.runtimeType && id == other.id && category == other.category;

  @override
  int get hashCode => Object.hash(id, category);
}

enum StockHistoryCategoryType {
  all('전체'),
  register("재고등록"),
  release("출고(사용)"),
  quantityChange("수량변경"),
  locationChange("위치변경");

  const StockHistoryCategoryType(this.value);
  final String value;

  // JSON에서 들어온 영어 문자열("register" 등)을 Enum 객체로 변환
  static StockHistoryCategoryType fromCode(String code) {
    return StockHistoryCategoryType.values.firstWhere(
      (e) => e.name == code, // e.name은 "register", "release" 등의 기본 속성입니다.
      orElse: () => StockHistoryCategoryType.register, // 매칭되는 값이 없을 때의 안전장치
    );
  }
}
