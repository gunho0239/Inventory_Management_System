import 'package:flutter/material.dart';
import 'package:inventory_management/enums/label_type.dart';
import 'package:inventory_management/widgets/icons.dart';

class IconLabel extends StatelessWidget {
  final LabelType labelType;
  late final IconData iconData;
  late final String labelName;


  IconLabel({super.key, required this.labelType}) {
    switch (labelType) {
      case LabelType.category:
        iconData = MenuIcons.category;
        labelName = '구분';
        break;
      case LabelType.type:
        iconData = MenuIcons.type;
        labelName = '품명';
        break;
      case LabelType.specification:
        iconData = MenuIcons.specification;
        labelName = '규격';
        break;
      case LabelType.maker:
        iconData = MenuIcons.makerOutlined;
        labelName = '제조사';
        break;
      case LabelType.unit:
        iconData = MenuIcons.unit;
        labelName = '단위';
        break;
      case LabelType.memo:
        iconData = MenuIcons.memo;
        labelName = '메모 키워드';
        break;
      case LabelType.section:
        iconData = MenuIcons.section;
        labelName = '구역';
        break;
      case LabelType.number:
        iconData = MenuIcons.number;
        labelName = '번호';
        break;
      case LabelType.startNumber:
        iconData = MenuIcons.startNumber;
        labelName = '시작 번호';
        break;
      case LabelType.endNumber:
        iconData = MenuIcons.endNumber;
        labelName = '종료 번호';
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 5,
      children: [
        Icon(iconData),
        Text(labelName)
      ],
    );
  }
}