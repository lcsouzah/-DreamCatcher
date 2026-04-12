import 'dart:developer';
import 'package:flutter/material.dart';
import '../services/health_connect_service.dart';

class HealthTestScreen extends StatefulWidget {
  const HealthTestScreen({super.key});

  @override
  State<HealthTestScreen> createState() => _HealthTestScreenState();
}

class _HealthTestScreenState extends State<HealthTestScreen> {
  final HealthConnectService _healthService = HealthConnectService();
  String _status = 'Idle';

  Future<void> _checkPermissions() async {
    setState(() => _status = 'Checking permissions...');
    try {
      final has = await _healthService.hasPermissions();
      setState(() => _status = 'Has Permissions: $has');
      log('[HealthTest] hasPermissions result: $has');
    } catch (e) {
      setState(() => _status = 'Error: $e');
      log('[HealthTest] hasPermissions error: $e');
    }
  }

  Future<void> _requestPermissions() async {
    setState(() => _status = 'Requesting permissions...');
    try {
      final ok = await _healthService.requestPermissions();
      setState(() => _status = 'Request Permissions Result: $ok');
      log('[HealthTest] requestPermissions result: $ok');
    } catch (e) {
      setState(() => _status = 'Error: $e');
      log('[HealthTest] requestPermissions error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health Connect Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Status: $_status', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _checkPermissions,
              child: const Text('Check Permissions'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _requestPermissions,
              child: const Text('Request Permissions'),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Note: If "Needs updating" persists, ensure you have the latest Health Connect app installed and that the package name matches exactly in Google Play Console (if applicable).',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
