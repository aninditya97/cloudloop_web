import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AlarmActionScreen extends StatelessWidget {
  final String? payload;

  AlarmActionScreen({this.payload});

  void snoozeAlarm(BuildContext context, String? payload) {
    // Implement snooze logic here
    // For example, delaying the alarm notification for a certain period

    // Placeholder: Show a dialog
    showDialog<BuildContext>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Snooze Alarm"),
        content: Text("Alarm snoozed for 5 minutes. Payload: $payload"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void stopAlarm(BuildContext context, String? payload) {
    // Implement stop logic here
    // For example, canceling the alarm notification

    // Placeholder: Show a dialog
    showDialog<BuildContext>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Stop Alarm"),
        content: Text("Alarm stopped. Payload: $payload"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Alarm Actions')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () => snoozeAlarm(context, payload),
              child: Text('Snooze'),
            ),
            ElevatedButton(
              onPressed: () => stopAlarm(context, payload),
              child: Text('Stop'),
            ),
          ],
        ),
      ),
    );
  }
}
