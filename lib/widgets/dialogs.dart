import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ConfirmDialog extends StatelessWidget {
  final String message;

  const ConfirmDialog({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('알림'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('확인'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('취소'),
        ),
      ],
    );
  }
}


class ResultDialog extends StatelessWidget {
  final String message;

  const ResultDialog({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('알림'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('확인'),
        ),
      ],
    );
  }
}

class ErrorDialog extends StatelessWidget {
  final String message;

  const ErrorDialog({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('오류'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('확인'),
        ),
      ],
    );
  }
}

class NumberInputDialog extends StatelessWidget {
  final String title;
  final String hintText;
  final TextEditingController controller = TextEditingController();

  NumberInputDialog({
    super.key,
    required this.title,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(hintText: hintText),
      ),
      actions: [
        TextButton(
          onPressed: () {
            final value = controller.text;
            if (value != "") {
              Navigator.of(context).pop(int.parse(value));
            }
          },
          child: Text('확인'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('취소'),
        ),
      ],
    );
  }
}