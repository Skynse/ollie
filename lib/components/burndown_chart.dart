import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Data point for the burndown chart
class BurndownDataPoint {
  final DateTime date;
  final double remainingHours;
  final double? actualHours;

  BurndownDataPoint({
    required this.date,
    required this.remainingHours,
    this.actualHours,
  });
}

/// Burndown chart widget showing ideal vs actual progress
class BurndownChart extends StatefulWidget {
  final List<BurndownDataPoint> dataPoints;
  final double targetHours;
  final DateTime startDate;
  final DateTime endDate;
  final String title;
  final Color idealLineColor;
  final Color actualLineColor;

  const BurndownChart({
    super.key,
    required this.dataPoints,
    required this.targetHours,
    required this.startDate,
    required this.endDate,
    this.title = 'Sprint Burndown',
    this.idealLineColor = Colors.blue,
    this.actualLineColor = Colors.orange,
  });

  @override
  State<BurndownChart> createState() => _BurndownChartState();
}

class _BurndownChartState extends State<BurndownChart> {
  @override
  Widget build(BuildContext context) {
    if (widget.dataPoints.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend
        _buildLegend(),
        const SizedBox(height: 16),

        // Chart
        SizedBox(
          height: 320,
          child: Padding(
            padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            child: LineChart(
              _buildChartData(),
              duration: const Duration(milliseconds: 250),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        _LegendItem(
          color: const Color(0xff94a3b8),
          label: 'Ideal',
          isDashed: true,
        ),
        const SizedBox(width: 20),
        _LegendItem(color: const Color(0xff3b82f6), label: 'Actual'),
      ],
    );
  }

  LineChartData _buildChartData() {
    final durationDays = widget.endDate.difference(widget.startDate).inDays;
    final idealPoints = _generateIdealLine(durationDays);
    final actualPoints = _generateActualLine();

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: widget.targetHours / 5,
        getDrawingHorizontalLine: (value) {
          return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
        },
        getDrawingVerticalLine: (value) {
          return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
        },
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 42,
            interval: widget.targetHours / 5,
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.right,
                ),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: durationDays > 14 ? (durationDays / 7).ceilToDouble() : 2,
            getTitlesWidget: (value, meta) {
              // Don't show label if it's beyond the max
              if (value > durationDays) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      lineBarsData: [
        // Ideal line
        LineChartBarData(
          spots: idealPoints,
          isCurved: false,
          color: const Color(0xff94a3b8),
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          dashArray: [6, 4],
          belowBarData: BarAreaData(show: false),
        ),
        // Actual line
        if (actualPoints.isNotEmpty)
          LineChartBarData(
            spots: actualPoints,
            isCurved: true,
            curveSmoothness: 0.3,
            color: const Color(0xff3b82f6),
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: const Color(0xff3b82f6),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xff3b82f6).withOpacity(0.08),
            ),
          ),
      ],
      minX: 0,
      maxX: durationDays.toDouble(),
      minY: 0,
      maxY: widget.targetHours * 1.1,
      clipData: const FlClipData.all(),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final date = widget.startDate.add(Duration(days: spot.x.toInt()));
              final dateStr = '${date.month}/${date.day}/${date.year}';
              return LineTooltipItem(
                '$dateStr\n${spot.y.toStringAsFixed(1)}h',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  List<FlSpot> _generateIdealLine(int durationDays) {
    final spots = <FlSpot>[];
    final decrementPerDay = widget.targetHours / durationDays;

    for (int i = 0; i <= durationDays; i++) {
      spots.add(
        FlSpot(
          i.toDouble(),
          (widget.targetHours - (i * decrementPerDay)).clamp(
            0,
            widget.targetHours,
          ),
        ),
      );
    }

    return spots;
  }

  List<FlSpot> _generateActualLine() {
    final spots = <FlSpot>[];

    for (final point in widget.dataPoints) {
      if (point.actualHours != null) {
        final dayIndex = point.date
            .difference(widget.startDate)
            .inDays
            .toDouble();
        spots.add(FlSpot(dayIndex, point.actualHours!));
      }
    }

    return spots;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 64,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No burndown data available',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start logging time to see the burndown chart',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDashed;

  const _LegendItem({
    required this.color,
    required this.label,
    this.isDashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDashed)
          CustomPaint(
            size: const Size(24, 2),
            painter: _DashedLinePainter(color: color),
          )
        else
          Container(
            width: 24,
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
