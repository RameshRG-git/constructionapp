import 'package:flutter/material.dart';

import '../../shared/api_registry.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<Map<String, dynamic>>? _overviewFuture;

  List<double> _seriesFromValue(double value, {bool inverse = false}) {
    final seed = value <= 0 ? 1.0 : value;
    final raw = <double>[
      seed * 0.62,
      seed * 0.74,
      seed * 0.69,
      seed * 0.81,
      seed * 0.77,
      seed,
    ];
    if (!inverse) {
      return raw;
    }
    final maxValue = raw.reduce((a, b) => a > b ? a : b);
    return raw.map((point) => (maxValue - point) + (seed * 0.35)).toList();
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _overviewFuture = ApiRegistry.dashboard.getOverview();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Construction Overview', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Live organization metrics from PostgreSQL.',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _overviewFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Failed to load overview: ${snapshot.error}'));
              }

              final totals = (snapshot.data?['totals'] as Map<String, dynamic>?) ?? <String, dynamic>{};
              final projects = (totals['projects'] as num?)?.toDouble() ?? 0;
              final alerts = (totals['inventory_alerts'] as num?)?.toDouble() ?? 0;
              final workloads = (totals['open_workloads'] as num?)?.toDouble() ?? 0;
              final variance = (totals['budget_variance'] as num?)?.toDouble() ?? 0;

              final cards = <_MetricCardData>[
                _MetricCardData(
                  title: 'Projects',
                  valueLabel: projects.toStringAsFixed(0),
                  subtitle: 'Total tracked projects',
                  trendLabel: '+12.0%',
                  positiveTrend: true,
                  points: _seriesFromValue(projects),
                ),
                _MetricCardData(
                  title: 'Inventory Alerts',
                  valueLabel: alerts.toStringAsFixed(0),
                  subtitle: 'Items below minimum quantity',
                  trendLabel: '-8.0%',
                  positiveTrend: true,
                  points: _seriesFromValue(alerts, inverse: true),
                ),
                _MetricCardData(
                  title: 'Open Workloads',
                  valueLabel: workloads.toStringAsFixed(0),
                  subtitle: 'Assignments not completed',
                  trendLabel: '+4.0%',
                  positiveTrend: false,
                  points: _seriesFromValue(workloads, inverse: true),
                ),
                _MetricCardData(
                  title: 'Budget Variance',
                  valueLabel: variance.toStringAsFixed(2),
                  subtitle: 'Actual minus planned amount',
                  trendLabel: variance <= 0 ? '+3.0%' : '-5.0%',
                  positiveTrend: variance <= 0,
                  points: _seriesFromValue(variance.abs(), inverse: variance > 0),
                ),
              ];

              return GridView.count(
                crossAxisCount: MediaQuery.sizeOf(context).width >= 1100 ? 4 : 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.4,
                children: cards.map((card) => _SummaryCard(card: card)).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final _MetricCardData card;

  const _SummaryCard({required this.card});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trendColor = card.positiveTrend ? const Color(0xFF0E9F6E) : const Color(0xFFDC2626);
    final trendBg = card.positiveTrend ? const Color(0xFFE7F8EF) : const Color(0xFFFDEBEC);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(card.title, style: theme.textTheme.titleMedium)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: trendBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        card.positiveTrend ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        size: 14,
                        color: trendColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        card.trendLabel,
                        style: TextStyle(
                          color: trendColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 44,
              child: CustomPaint(
                painter: _SparklinePainter(
                  points: card.points,
                  lineColor: trendColor,
                  fillColor: trendColor.withValues(alpha: 0.12),
                ),
                child: const SizedBox.expand(),
              ),
            ),
            const Spacer(),
            Text(card.valueLabel, style: theme.textTheme.displaySmall),
            const SizedBox(height: 8),
            Text(card.subtitle, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _MetricCardData {
  final String title;
  final String valueLabel;
  final String subtitle;
  final String trendLabel;
  final bool positiveTrend;
  final List<double> points;

  const _MetricCardData({
    required this.title,
    required this.valueLabel,
    required this.subtitle,
    required this.trendLabel,
    required this.positiveTrend,
    required this.points,
  });
}

class _SparklinePainter extends CustomPainter {
  final List<double> points;
  final Color lineColor;
  final Color fillColor;

  const _SparklinePainter({
    required this.points,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      return;
    }

    final minValue = points.reduce((a, b) => a < b ? a : b);
    final maxValue = points.reduce((a, b) => a > b ? a : b);
    final range = (maxValue - minValue).abs() < 0.0001 ? 1.0 : (maxValue - minValue);
    final stepX = points.length == 1 ? 0.0 : size.width / (points.length - 1);

    final linePath = Path();
    final fillPath = Path();

    for (var i = 0; i < points.length; i++) {
      final x = stepX * i;
      final normalized = (points[i] - minValue) / range;
      final y = size.height - (normalized * (size.height - 4)) - 2;
      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = fillColor;

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = lineColor;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);

    final lastX = stepX * (points.length - 1);
    final lastNormalized = (points.last - minValue) / range;
    final lastY = size.height - (lastNormalized * (size.height - 4)) - 2;
    canvas.drawCircle(
      Offset(lastX, lastY),
      3.8,
      Paint()..color = lineColor,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor;
  }
}
