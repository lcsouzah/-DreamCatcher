import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Health _health = Health(); // ✅ Correct for v13+
  String _sleepResult = "Fetching sleep data...";

  Future<void> _fetchSleepData() async {
    // ✅ Runtime permission for Android 10+
    if (await Permission.activityRecognition.request().isDenied) {
      setState(() {
        _sleepResult = "Activity Recognition permission denied";
      });
      return;
    }

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    final types = [
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.SLEEP_DEEP,
      HealthDataType.SLEEP_REM,
    ];

    bool granted = await _health.requestAuthorization(types);

    if (!granted) {
      setState(() => _sleepResult = "Google Fit permission not granted");
      return;
    }

    try {
      final healthData = await _health.getHealthDataFromTypes(
        types: types,
        startTime: yesterday,
        endTime: now,
      );

      double totalMinutes = 0;
      for (var point in healthData) {
        final duration = point.dateTo.difference(point.dateFrom).inMinutes;
        totalMinutes += duration;
      }

      setState(() {
        _sleepResult =
        "Total Sleep: ${(totalMinutes / 60).toStringAsFixed(1)} hours";
      });
    } catch (e) {
      setState(() => _sleepResult = "Error: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    // ✅ Delay avoids "Permission launcher not found" issue
    Future.delayed(const Duration(milliseconds: 500), _fetchSleepData);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/screens/home_bg.png',
            fit: BoxFit.cover,
          ),
        ),
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              const Text(
                'DreamCatcher',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontFamily: 'DreamFont',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Sleep to Earn',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 50),
              Text(
                _sleepResult,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
