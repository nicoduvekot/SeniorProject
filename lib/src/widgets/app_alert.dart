import 'package:flutter/material.dart';

class AppAlert {
  static Future<void> showConfirm(
      BuildContext context,
      String message, {
      String title = "Notice",
      String buttonText = "OK",
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AlertBase(
        title: title,
        message: message,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  static Future<bool> showYesNoAlert(
      BuildContext context,
      String message, {
        String title = "Confirm",
        String yesText = "Yes",
        String noText = "No",
        Color titleColor = Colors.black,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AlertBase(
        title: title,
        message: message,
        titleColor: titleColor,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(noText),
          ),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(yesText),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _AlertBase extends StatelessWidget {
  final String title;
  final String message;
  final List<Widget> actions;
  final Color titleColor; // allow caller to change color of title text

  const _AlertBase({
    required this.title,
    required this.message,
    required this.actions,
    this.titleColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.white,
        elevation: 24,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                )),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign:TextAlign.center,
                style: const TextStyle(fontSize:16),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: actions.length == 1
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.spaceBetween,
                children: actions,
              )
            ],
          ),
        ),
      ),
    );
  }
}