import 'package:flutter/material.dart';

import '../models/sleep_entry.dart';
import '../widgets/card.dart';

class SleepDetailScreen extends StatelessWidget {
  const SleepDetailScreen({super.key, required this.entry});

  final SleepEntry entry;

  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations localizations =
    MaterialLocalizations.of(context);
    final Duration duration = entry.duration;
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    final String dayLabel = localizations.formatFullDate(entry.date);
    final String start = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(entry.start),
    );
    final String end = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(entry.end),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Sleep details'),
      ),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Image.asset(
              'assets/screens/history_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    dayLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  DreamCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _DetailRow(label: 'Start', value: start),
                        const SizedBox(height: 12),
                        _DetailRow(label: 'End', value: end),
                        const Divider(height: 32, color: Colors.white12),
                        _DetailRow(
                          label: 'Duration',
                          value: '${entry.totalHours.toStringAsFixed(2)} hours',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '≈ ${hours}h ${minutes}m of tracked rest',
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}