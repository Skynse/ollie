import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'ollie_ui/theme_extensions.dart';

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
        // Title and legend
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _buildLegend(),
            ],
          ),
        ),

        // Chart
        SizedBox(
          height: 300,
          child: Padding(
            padding: const EdgeInsets.only(right: 16, top: 8),
            child: LineChart(
              _buildChartData(),
              duration: const Duration(milliseconds: 250),
            ),
          ),
        ),

        // Stats summary
        const SizedBox(height: 16),
        _buildStats(),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LegendItem(
          color: widget.idealLineColor,
          label: 'Ideal',
          isDashed: true,
        ),
        const SizedBox(width: 16),
        _LegendItem(color: widget.actualLineColor, label: 'Actual'),
      ],
    );
  }

  Widget _buildStats() {
    final latestPoint = widget.dataPoints.lastOrNull;
    final remaining = latestPoint?.actualHours ?? widget.targetHours;
    final completed = widget.targetHours - remaining;
    final percentComplete = (completed / widget.targetHours * 100).clamp(
      0,
      100,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _StatItem(
                label: 'Target Hours',
                value: widget.targetHours.toStringAsFixed(1),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Expanded(
              child: _StatItem(
                label: 'Completed',
                value: completed.toStringAsFixed(1),
                color: Colors.green,
              ),
            ),
            Expanded(
              child: _StatItem(
                label: 'Remaining',
                value: remaining.toStringAsFixed(1),
                color: Colors.orange,
              ),
            ),
            Expanded(
              child: _StatItem(
                label: 'Progress',
                value: '${percentComplete.toInt()}%',
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
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
        verticalInterval: durationDays / 7,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Theme.of(context).colorScheme.outlineVariant,
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Theme.of(context).colorScheme.outlineVariant,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          axisNameWidget: const Text(
            'Hours Remaining',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            interval: widget.targetHours / 5,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
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
          axisNameWidget: const Text(
            'Days',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: (durationDays / 7).ceilToDouble(),
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Day ${value.toInt()}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      lineBarsData: [
        // Ideal line
        LineChartBarData(
          spots: idealPoints,
          isCurved: false,
          color: widget.idealLineColor,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          dashArray: [5, 5],
          belowBarData: BarAreaData(show: false),
        ),
        // Actual line
        if (actualPoints.isNotEmpty)
          LineChartBarData(
            spots: actualPoints,
            isCurved: true,
            color: widget.actualLineColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: widget.actualLineColor,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: widget.actualLineColor.withOpacity(0.1),
            ),
          ),
      ],
      minX: 0,
      maxX: durationDays.toDouble(),
      minY: 0,
      maxY: widget.targetHours * 1.1,
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

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
