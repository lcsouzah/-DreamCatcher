import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

enum _RationaleAction { retry, cancel, settings }

class HealthService {
  HealthService();

  final Health _health = Health();
  final List<HealthDataType> _sleepTypes = const <HealthDataType>[
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
  ];

  Future<bool> requestPermissions(BuildContext context) async {
    if (!await _ensureActivityPermission(context)) {
      return false;
    }

    bool granted = await _health.requestAuthorization(_sleepTypes);
    while (!granted) {
      final action = await _showRationaleDialog(
        context,
        title: 'Connect your sleep data',
        message:
        'DreamCatcher needs permission to read your sleep duration from Google Fit so we can reward your rest.',
      );
      if (action == _RationaleAction.retry) {
        granted = await _health.requestAuthorization(_sleepTypes);
        continue;
      }
      if (action == _RationaleAction.settings) {
        await openAppSettings();
        granted = await _health.requestAuthorization(_sleepTypes);
        continue;
      }
      return false;
    }

    return true;
  }

  Future<List<HealthDataPoint>> getSleepData({
    required DateTime start,
    required DateTime end,
  }) {
    return _health.getHealthDataFromTypes(
      types: _sleepTypes,
      startTime: start,
      endTime: end,
    );
  }

  Future<bool> _ensureActivityPermission(BuildContext context) async {
    PermissionStatus status = await Permission.activityRecognition.status;
    if (status.isGranted) {
      return true;
    }

    status = await Permission.activityRecognition.request();
    while (!status.isGranted) {
      final action = await _showRationaleDialog(
        context,
        title: 'Allow activity recognition',
        message:
        'We use activity recognition to securely sync your nightly sleep from Google Fit.',
        showSettings: status.isPermanentlyDenied,
      );
      if (action == _RationaleAction.retry) {
        if (status.isPermanentlyDenied) {
          await openAppSettings();
        }
        status = await Permission.activityRecognition.request();
        continue;
      }
      if (action == _RationaleAction.settings) {
        await openAppSettings();
        status = await Permission.activityRecognition.request();
        continue;
      }
      return false;
    }

    return true;
  }

  Future<_RationaleAction?> _showRationaleDialog(
      BuildContext context, {
        required String title,
        required String message,
        bool showSettings = false,
      }) {
    return showDialog<_RationaleAction>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(_RationaleAction.cancel),
              child: const Text('Not now'),
            ),
            if (showSettings)
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(_RationaleAction.settings),
                child: const Text('Open settings'),
              ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(_RationaleAction.retry),
              child: const Text('Try again'),
            ),
          ],
        );
      },
    );
  }
}
