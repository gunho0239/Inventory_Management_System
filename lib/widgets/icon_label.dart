import 'package:flutter/material.dart';
import 'package:inventory_management/enums/label_type.dart';
import 'package:inventory_management/widgets/icons.dart';

class IconLabel extends StatelessWidget {
  final LabelType labelType;

  const IconLabel({super.key, required this.labelType});

  (IconData, String) get _info => switch (labelType) {
        LabelType.category => (MenuIcons.category, '구분'),
        LabelType.type => (MenuIcons.type, '품명'),
        LabelType.specification => (MenuIcons.specification, '규격'),
        LabelType.maker => (MenuIcons.makerOutlined, '제조사'),
        LabelType.unit => (MenuIcons.unit, '단위'),
        LabelType.memo => (MenuIcons.memo, '메모 키워드'),
        LabelType.section => (MenuIcons.section, '구역'),
        LabelType.number => (MenuIcons.number, '번호'),
        LabelType.startNumber => (MenuIcons.startNumber, '시작 번호'),
        LabelType.endNumber => (MenuIcons.endNumber, '종료 번호'),
        LabelType.quantity => (MenuIcons.quantity, '수량'),
      };

  @override
  Widget build(BuildContext context) {
    // Record 구조 분해 할당
    final (icon, text) = _info; 

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 5,
      children: [
        Icon(icon),
        Text(text),
      ],
    );
  }
}