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
  bool _isAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final available = await _healthService.isAvailable();
    setState(() {
      _isAvailable = available;
      _status = available ? 'Health Connect Available' : 'Health Connect NOT Available';
    });
  }

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

  Future<void> _readData() async {
    setState(() => _status = 'Reading sleep data...');
    try {
      final data = await _healthService.readSleepSessions();
      setState(() => _status = 'Read ${data.length} sleep records');
      log('[HealthTest] Read ${data.length} records');
      for (var r in data.take(5)) {
        log(' - ${r.start} to ${r.end} (${r.type})');
      }
    } catch (e) {
      setState(() => _status = 'Error reading data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health Connect Test')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Status: $_status',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              if (!_isAvailable) ...[
                const Text(
                  'Health Connect is not installed or available on this device.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => _healthService.openHealthConnectSettings(),
                  child: const Text('Install / Open Health Connect'),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: _checkPermissions,
                  child: const Text('1. Check Permissions'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _requestPermissions,
                  child: const Text('2. Request Permissions'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _readData,
                  child: const Text('3. Read Sleep Data'),
                ),
              ],
              const SizedBox(height: 40),
              const Text(
                'Manual Steps:\n1. Ensure Health Connect app is installed.\n2. Ensure Sleep data exists in Health Connect (from a provider like Google Fit or Samsung Health).\n3. Package name must match Play Console settings if using Restricted Scopes.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
