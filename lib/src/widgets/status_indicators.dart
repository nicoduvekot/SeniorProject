import 'package:flutter/material.dart';
import '../models/document_status.dart';

class StatusIndicators extends StatelessWidget {
  final DocumentStatus status;

  const StatusIndicators({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String tooltip;

    switch (status) {
      case DocumentStatus.complete:
        icon = Icons.check_circle;
        color = Colors.green;
        tooltip = "Complete";
        break;

      case DocumentStatus.incomplete:
        icon = Icons.error_outline;
        color = Colors.orange;
        tooltip = "Incomplete";
        break;

      case DocumentStatus.syncing:
        return Tooltip(
          message: "Pending sync",
          child: RotationTransition(
            turns: const AlwaysStoppedAnimation(0.5),
            child: Icon(Icons.sync, color: Colors.blue, size: 20),
          ),
        );
    }

    return Tooltip(
      message: tooltip,
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    );
  }
}