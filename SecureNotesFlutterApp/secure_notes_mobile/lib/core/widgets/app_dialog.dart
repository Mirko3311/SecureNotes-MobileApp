import 'package:flutter/material.dart';

Future<void> showInfoDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        icon: const Icon(
          Icons.check_circle_outline,
          size: 40,
          color: Colors.green,
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('U redu'),
          ),
        ],
      );
    },
  );
}

Future<void> showErrorDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        icon: Icon(
          Icons.error_outline,
          size: 40,
          color: Theme.of(dialogContext).colorScheme.error,
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('U redu'),
          ),
        ],
      );
    },
  );
}

Future<void> showSuccessDialog(
  BuildContext context, {
  required String message,
}) async {
  final NavigatorState navigator = Navigator.of(context);
  bool isOpen = true;

  final Future<void> dialogFuture =
      showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            icon: const Icon(
              Icons.check_circle_outline,
              size: 48,
              color: Colors.green,
            ),
            title: Text(message, textAlign: TextAlign.center),
          );
        },
      ).then((_) {
        isOpen = false;
      });

  await Future.delayed(const Duration(milliseconds: 1500));

  if (isOpen) {
    navigator.pop();
  }

  await dialogFuture;
}
