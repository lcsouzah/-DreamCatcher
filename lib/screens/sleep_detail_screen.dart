import 'package:flutter/material.dart';
import '../models/sleep_entry.dart';
import '../models/sleep_record.dart';
import '../widgets/card.dart';

class SleepDetailScreen extends StatelessWidget {
  const SleepDetailScreen({super.key, required this.entry});

  final SleepEntry entry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<SleepRecord> records = entry.records;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Sleep Detail',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  DreamCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(context, entry.date),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${entry.totalHours.toStringAsFixed(1)} hrs total",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Sleep stages",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 🟪 Stage timeline visualization
                  Expanded(
                    child: DreamCard(
                      padding: const EdgeInsets.all(16),
                      child: CustomPaint(
                        painter: _SleepTimelinePainter(records),
                        child: Container(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 💤 Legend
                  _buildLegend(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(ThemeData theme) {
    const legendItems = [
      {'color': Color(0xFF9B5DE5), 'label': 'REM'},
      {'color': Color(0xFF00BBF9), 'label': 'Light'},
      {'color': Color(0xFF00F5D4), 'label': 'Deep'},
      {'color': Color(0xFFFFB5A7), 'label': 'Awake'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: legendItems
          .map((item) => Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: item['color'] as Color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            item['label'] as String,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ))
          .toList(),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final MaterialLocalizations localizations =
    MaterialLocalizations.of(context);
    return localizations.formatFullDate(date);
  }
}

/// 🎨 Paints a colorful timeline based on mock sleep records.
class _SleepTimelinePainter extends CustomPainter {
  _SleepTimelinePainter(this.records);

  final List<SleepRecord> records;

  final Map<String, Color> stageColors = const {
    'rem': Color(0xFF9B5DE5),
    'light': Color(0xFF00BBF9),
    'deep': Color(0xFF00F5D4),
    'awake': Color(0xFFFFB5A7),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final double totalDurationMinutes = records.fold(
      0.0,
          (sum, r) => sum + r.end.difference(r.start).inMinutes.toDouble(),
    );

    if (totalDurationMinutes == 0) return;

    double x = 0;
    for (final record in records) {
      final double durationMinutes =
      record.end.difference(record.start).inMinutes.toDouble();
      final double segmentWidth =
          (durationMinutes / totalDurationMinutes) * size.width;

      final paint = Paint()
        ..color = stageColors[record.type.toLowerCase()] ?? Colors.grey
        ..style = PaintingStyle.fill;

      final rect = Rect.fromLTWH(x, 0, segmentWidth, size.height);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
      canvas.drawRRect(rrect, paint);
      x += segmentWidth + 2; // small gap
    }
  }

  @override
  bool shouldRepaint(_SleepTimelinePainter oldDelegate) => true;
}
