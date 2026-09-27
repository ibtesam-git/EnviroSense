import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../../../app/motion/enviro_motion.dart';
import '../../../app/motion/motion_widgets.dart';
import '../../../core/preferences/app_preferences.dart';
import '../../../core/providers/local_demo_history_provider.dart';
import '../../../core/providers/sensor_providers.dart';
import '../../../core/repositories/local_demo_history_repository.dart';

enum _Metric { temperature, humidity }
enum _Range { day, week, month }

class TrendsScreen extends ConsumerStatefulWidget {
  const TrendsScreen({super.key});

  @override
  ConsumerState<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends ConsumerState<TrendsScreen> {
  _Metric _metric = _Metric.temperature;
  _Range _range = _Range.day;

  List<DemoHistoryPoint> _pointsFor(List<DemoHistoryPoint> history) {
    final duration = switch (_range) {
      _Range.day => const Duration(hours: 24),
      _Range.week => const Duration(days: 7),
      _Range.month => const Duration(days: 30),
    };
    final cutoff = DateTime.now().subtract(duration);
    return history
        .where((point) => !point.timestamp.isBefore(cutoff))
        .toList(growable: false);
  }

  List<double> _valuesFor(
      List<DemoHistoryPoint> points,
      TemperatureUnit unit,
      ) {
    final values = points
        .map((point) => _metric == _Metric.temperature
        ? point.temperatureC
        : point.humidityPercent)
        .toList(growable: false);
    if (_metric == _Metric.temperature && unit == TemperatureUnit.fahrenheit) {
      return values.map(unit.fromCelsius).toList(growable: false);
    }
    return values;
  }

  String get _name => _metric == _Metric.temperature ? 'Temperature' : 'Humidity';
  Color get _accent => _metric == _Metric.temperature
      ? EnviroPalette.amberWarm
      : EnviroPalette.teal;
  String get _rangeName => switch (_range) {
    _Range.day => 'last 24 hours',
    _Range.week => 'last 7 days',
    _Range.month => 'last 30 days',
  };

  String _format(double value) => _metric == _Metric.temperature
      ? value.toStringAsFixed(1)
      : value.round().toString();

  void _selectMetric(_Metric value) => setState(() => _metric = value);
  void _selectRange(_Range value) => setState(() => _range = value);

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(appPreferencesProvider);
    final points = _pointsFor(ref.watch(localDemoHistoryProvider));
    final values = _valuesFor(points, preferences.temperatureUnit);
    final unit = _metric == _Metric.temperature
        ? preferences.temperatureUnit.symbol
        : '%';
    final reduceMotion = MediaQuery.of(context).disableAnimations ||
        preferences.reducedMotion;
    if (values.isEmpty) return _emptyHistory(reduceMotion);

    final average = values.reduce((a, b) => a + b) / values.length;
    final low = values.reduce((a, b) => math.min(a, b).toDouble());
    final high = values.reduce((a, b) => math.max(a, b).toDouble());

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 124),
          children: [
            SpringReveal(reduceMotion: reduceMotion, child: _header()),
            const SizedBox(height: 18),
            _sampleNotice(),
            const SizedBox(height: 24),
            _sectionLabel('EXPLORE A SIGNAL'),
            const SizedBox(height: 10),
            _metricChoices(),
            const SizedBox(height: 16),
            _rangeChoices(),
            const SizedBox(height: 13),
            SpringReveal(
              delay: const Duration(milliseconds: 80),
              reduceMotion: reduceMotion,
              child: _chartCard(values, average, unit),
            ),
            const SizedBox(height: 22),
            _sectionLabel('AT A GLANCE'),
            const SizedBox(height: 10),
            Row(
              children: [
                _stat('AVERAGE', average, _accent, unit),
                const SizedBox(width: 9),
                _stat('LOW', low, AppTheme.teal, unit),
                const SizedBox(width: 9),
                _stat('HIGH', high, AppTheme.brass, unit),
              ],
            ),
            const SizedBox(height: 18),
            _contextCard(values.last, unit),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'HISTORY VIEW · STORED DEMO SAMPLES',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 9,
                  letterSpacing: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyHistory(bool reduceMotion) => Scaffold(
    backgroundColor: Colors.transparent,
    body: SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 124),
        children: [
          SpringReveal(reduceMotion: reduceMotion, child: _header()),
          const SizedBox(height: 18),
          _sampleNotice(),
          const SizedBox(height: 24),
          _sectionLabel('EXPLORE A SIGNAL'),
          const SizedBox(height: 10),
          _metricChoices(),
          const SizedBox(height: 16),
          _rangeChoices(),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: EnviroPalette.hairline),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.history_rounded,
                  color: AppTheme.brass,
                  size: 25,
                ),
                const SizedBox(height: 10),
                const Text(
                  'No stored samples in this range',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Refresh the demo reading to add a local sample. History is kept for up to 30 days.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => ref.invalidate(sensorSnapshotProvider),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Add demo sample'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _header() => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'ENVIRONMENT / HISTORY',
        style: TextStyle(
          color: AppTheme.brass,
          fontSize: 10,
          letterSpacing: 1.6,
          fontWeight: FontWeight.w700,
        ),
      ),
      SizedBox(height: 7),
      Text(
        'Trends',
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 29,
          height: 1,
          letterSpacing: -0.7,
          fontWeight: FontWeight.w700,
        ),
      ),
      SizedBox(height: 7),
      Text(
        'See how your space changes over time.',
        style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
      ),
    ],
  );

  Widget _sampleNotice() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
    decoration: BoxDecoration(
      color: AppTheme.brass.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: AppTheme.brass.withValues(alpha: 0.18)),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.science_outlined, color: AppTheme.brass, size: 17),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'History is stored on this device. Seed entries are illustrative demo values; connected-sensor history is not available yet.',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      color: AppTheme.textMuted,
      fontSize: 9,
      letterSpacing: 1.35,
      fontWeight: FontWeight.w700,
    ),
  );

  Widget _metricChoices() => Row(
    children: [
      Expanded(
        child: _choice(
          'Temperature',
          Icons.thermostat_rounded,
          _metric == _Metric.temperature,
          EnviroPalette.amberWarm,
              () => _selectMetric(_Metric.temperature),
        ),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: _choice(
          'Humidity',
          Icons.water_drop_rounded,
          _metric == _Metric.humidity,
          AppTheme.teal,
              () => _selectMetric(_Metric.humidity),
        ),
      ),
    ],
  );

  Widget _choice(
      String title,
      IconData icon,
      bool selected,
      Color color,
      VoidCallback onTap,
      ) => Semantics(
    button: true,
    selected: selected,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.10) : AppTheme.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.40) : EnviroPalette.hairline,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? color : AppTheme.textMuted, size: 16),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? AppTheme.textPrimary : AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _rangeChoices() => Row(
    children: [
      for (final item in _Range.values) ...[
        if (item != _Range.day) const SizedBox(width: 7),
        Expanded(
          child: InkWell(
            onTap: () => _selectRange(item),
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: item == _range ? AppTheme.surfaceRaised : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: item == _range ? EnviroPalette.hairline : Colors.transparent,
                ),
              ),
              child: Text(
                switch (item) {
                  _Range.day => '24 HOURS',
                  _Range.week => '7 DAYS',
                  _Range.month => '30 DAYS',
                },
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: item == _range ? AppTheme.brass : AppTheme.textMuted,
                  fontSize: 8,
                  letterSpacing: 0.75,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    ],
  );

  Widget _chartCard(List<double> values, double average, String unit) => Container(
    padding: const EdgeInsets.fromLTRB(15, 16, 15, 13),
    decoration: BoxDecoration(
      color: AppTheme.surface.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(21),
      border: Border.all(color: EnviroPalette.hairline),
      boxShadow: [
        BoxShadow(color: _accent.withValues(alpha: 0.035), blurRadius: 20),
      ],
    ),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _name.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 9,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _rangeName,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
            Text(
              '${_format(values.last)} $unit',
              style: TextStyle(
                color: _accent,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 158,
          width: double.infinity,
          child: CustomPaint(
            painter: _TrendPainter(values: values, color: _accent, average: average),
          ),
        ),
        const SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _axisLabels.map((text) => Text(
            text,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 8),
          )).toList(),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Container(width: 7, height: 7, decoration: BoxDecoration(color: _accent, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(_name, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
            const Spacer(),
            Container(width: 14, height: 1, color: Colors.white24),
            const SizedBox(width: 6),
            const Text('AVERAGE', style: TextStyle(color: AppTheme.textMuted, fontSize: 8, letterSpacing: 0.7)),
            const SizedBox(width: 5),
            Text('${_format(average)} $unit', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 9, fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    ),
  );

  List<String> get _axisLabels => switch (_range) {
    _Range.day => const ['6 AM', '12 PM', '6 PM', 'NOW'],
    _Range.week => const ['MON', 'WED', 'FRI', 'SUN'],
    _Range.month => const ['WEEK 1', 'WEEK 2', 'WEEK 3', 'NOW'],
  };

  Widget _stat(String label, double value, Color color, String unit) => Expanded(
    child: Container(
      padding: const EdgeInsets.fromLTRB(11, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: EnviroPalette.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 8, letterSpacing: 0.7, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              '${_format(value)} $unit',
              style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _contextCard(double latest, String unit) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.surfaceRaised.withValues(alpha: 0.76),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: EnviroPalette.hairline),
    ),
    child: Row(
      children: [
        Icon(Icons.insights_rounded, color: _accent, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, height: 1.4),
              children: [
                TextSpan(text: 'The sample ${_name.toLowerCase()} ends at '),
                TextSpan(text: '${_format(latest)} $unit', style: TextStyle(color: _accent, fontWeight: FontWeight.w700)),
                TextSpan(text: ' for the $_rangeName.'),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter({required this.values, required this.color, required this.average});

  final List<double> values;
  final Color color;
  final double average;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.isEmpty) return;

    const inset = 4.0;
    final plot = Rect.fromLTRB(inset, 9, size.width - inset, size.height - 9);
    final low = values.reduce((a, b) => math.min(a, b).toDouble());
    final high = values.reduce((a, b) => math.max(a, b).toDouble());
    final spread = math.max(high - low, 1.0).toDouble();
    final gridPaint = Paint()..color = Colors.white.withValues(alpha: 0.075);

    for (var i = 0; i < 4; i++) {
      final y = plot.top + plot.height * i / 3;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
    }

    final points = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(
          values.length == 1
              ? plot.center.dx
              : plot.left + plot.width * i / (values.length - 1),
          plot.bottom - (values[i] - low) / spread * plot.height * 0.78 - plot.height * 0.1,
        ),
    ];
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      final middle = (a.dx + b.dx) / 2;
      line.cubicTo(middle, a.dy, middle, b.dy, b.dx, b.dy);
    }

    final area = Path.from(line)
      ..lineTo(points.last.dx, plot.bottom)
      ..lineTo(points.first.dx, plot.bottom)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.20), color.withValues(alpha: 0.005)],
        ).createShader(plot),
    );

    final avgY = plot.bottom - (average - low) / spread * plot.height * 0.78 - plot.height * 0.1;
    final dashPaint = Paint()..color = Colors.white.withValues(alpha: 0.24);
    for (var x = plot.left; x < plot.right; x += 9) {
      canvas.drawLine(Offset(x, avgY), Offset(math.min(x + 4, plot.right).toDouble(), avgY), dashPaint);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(points.last, 6, Paint()..color = color.withValues(alpha: 0.18));
    canvas.drawCircle(points.last, 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.values != values || old.color != color || old.average != average;
}
