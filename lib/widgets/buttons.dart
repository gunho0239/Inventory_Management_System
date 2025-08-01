import 'package:flutter/material.dart';
import 'package:inventory_management/style/style.dart';

class GoBackButton extends StatelessWidget {
  const GoBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: AppButtonStyle.backPage,
      onPressed: () {
        Navigator.pop(context);
      },
      child: Icon(Icons.arrow_back, size: 30),
    );
  }
}

class SaveAllButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SaveAllButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Row(
        spacing: 5,
        children: [
          Icon(Icons.save, size: 30),
          Text('전체등록', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}

class DeleteButton extends StatelessWidget {
  final VoidCallback onPressed;

  const DeleteButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Row(
        spacing: 5,
        children: [
          Icon(Icons.delete, size: 30),
          Text('삭제', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}
