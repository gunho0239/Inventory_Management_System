import 'package:flutter/material.dart';

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
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Colors.deepPurple),
            foregroundColor: WidgetStateProperty.all(Colors.white),
          ),
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
  final TextStyle? style;

  const ErrorDialog({super.key, required this.message, this.style});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('오류'),
      content: Text(
        message,
        style: style,
      ),
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
  final String labelText;
  final TextEditingController controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  NumberInputDialog({
    super.key,
    required this.title,
    required this.labelText,
  });

  void _popWithValue(BuildContext context) {
    Navigator.of(context).pop<int?>(int.tryParse(controller.text));
  }

  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).requestFocus(_focusNode);

    return AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        focusNode: _focusNode,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => _popWithValue(context),
      ),
      actions: [
        TextButton(
          onPressed: () => _popWithValue(context),
          child: Text('확인'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop<int?>(null),
          child: Text('취소'),
        ),
      ],
    );
  }
}

