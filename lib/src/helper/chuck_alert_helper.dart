import 'package:flutter/material.dart';

sealed class ChuckAlertHelper {
  const ChuckAlertHelper._();

  ///Helper method used to open alarm with given title and description.
  static void showAlert(
    BuildContext context,
    String title,
    String description, {
    String firstButtonTitle = 'Accept',
    String? secondButtonTitle,
    void Function()? firstButtonAction,
    void Function()? secondButtonAction,
    Brightness? brightness,
  }) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        final List<Widget> actions = [
          TextButton(
            onPressed: () {
              if (firstButtonAction != null) {
                firstButtonAction();
              }
              Navigator.of(dialogContext).pop();
            },
            child: Text(firstButtonTitle),
          ),
        ];

        if (secondButtonTitle != null) {
          actions.add(
            TextButton(
              onPressed: () {
                if (secondButtonAction != null) {
                  secondButtonAction();
                }
                Navigator.of(dialogContext).pop();
              },
              child: Text(secondButtonTitle),
            ),
          );
        }

        return Theme(
          data: ThemeData(brightness: brightness ?? Brightness.light),
          child: AlertDialog(title: Text(title), content: Text(description), actions: actions),
        );
      },
    );
  }
}