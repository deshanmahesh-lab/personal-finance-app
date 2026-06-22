import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/database_provider.dart';
import '../providers/language_provider.dart';
import '../../utils/app_translations.dart';
import '../../services/ema_forecast_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class AppColors {
  static const bgLight = Color(0xFFFCFDFC);
  static const bgDark = Color(0xFF121212);
  static const premiumBlue = Color(0xFF182D92);
  static const income = Color(0xFF10B981);
  static const expense = Color(0xFFEF4444);
  static const safe = Color(0xFF10B981);
  static const danger = Color(0xFFF59E0B);
}

enum RangeMode { monthly, yearly }
enum FlowMode { expense, income }
enum ChartMode { donut, bar }

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> with TickerProviderStateMixin {
  RangeMode _range = RangeMode.monthly;
  FlowMode _flow = FlowMode.expense;
  ChartMode _chart = ChartMode.donut;

  late DateTime _currentDate;
  int? _touchedDonutIndex;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  static const _catColors = [
    Color(0xFF6366F1), Color(0xFF10B981), Color(0xFFF59E0B), Color(0xFFEF4444),
    Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFF14B8A6), Color(0xFF3B82F6),
    Color(0xFFF43F5E), Color(0xFF84CC16), Color(0xFFEAB308), Color(0xFF06B6D4)
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentDate = DateTime(now.year, now.month, 1);
  }

  void _shiftDate(int delta) {
    setState(() {
      _touchedDonutIndex = null;
      if (_range == RangeMode.monthly) {
        _currentDate = DateTime(_currentDate.year, _currentDate.month + delta, 1);
      } else {
        _currentDate = DateTime(_currentDate.year + delta, _currentDate.month, 1);
      }
    });
  }

  String get _dateLabel => _range == RangeMode.monthly
      ? '${_months[_currentDate.month - 1]} ${_currentDate.year}'
      : '${_currentDate.year}';

  String _fmt(double v) {
    return v.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgDark : AppColors.bgLight;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final lang = ref.watch(languageProvider);

    final isIncome = _flow == FlowMode.income;
    final isYearly = _range == RangeMode.yearly;
    final accentColor = isIncome ? AppColors.income : AppColors.expense;

    final isCurrentRealMonth = _currentDate.month == DateTime.now().month && _currentDate.year == DateTime.now().year;
    final showForecast = !isYearly && !isIncome && isCurrentRealMonth;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Ambient glow
          Positioned(
            top: -120, right: -80,
            child: _Glow(color: AppColors.premiumBlue.withOpacity(isDark ? 0.18 : 0.08), size: 360),
          ),
          Positioned(
            top: 200, left: -100,
            child: _Glow(color: accentColor.withOpacity(isDark ? 0.12 : 0.05), size: 300),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _header(fg, lang),
                      const SizedBox(height: 20),
                      _dateNavigator(fg, isDark),

                      // AI Forecast Card (Animated Size for smooth appearance)
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        child: showForecast ? Column(
                          children: [
                            const SizedBox(height: 24),
                            _buildEmaForecastCard(isDark),
                          ],
                        ) : const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 24),
                      _segmented<RangeMode>(
                        isDark: isDark,
                        value: _range,
                        items: {
                          RangeMode.monthly: AppTranslations.getText('monthly', lang),
                          RangeMode.yearly: AppTranslations.getText('yearly', lang),
                        },
                        onChanged: (v) => setState(() {
                          _range = v;
                          _touchedDonutIndex = null;
                        }),
                      ),
                      const SizedBox(height: 12),
                      _segmented<FlowMode>(
                        isDark: isDark,
                        value: _flow,
                        accent: accentColor,
                        items: {
                          FlowMode.expense: AppTranslations.getText('expense', lang),
                          FlowMode.income: AppTranslations.getText('income', lang),
                        },
                        onChanged: (v) => setState(() {
                          _flow = v;
                          _touchedDonutIndex = null;
                        }),
                      ),
                      const SizedBox(height: 20),
                      _chartTypeSwitch(isDark, fg, lang),
                      const SizedBox(height: 16),
                      _chartContainer(isDark, fg, lang, isYearly, isIncome),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _header(Color fg, String lang) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppTranslations.getText('title_analytics', lang),
                style: TextStyle(color: fg, fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -0.8)),
            const SizedBox(height: 2),
            Text('Insights into your money',
                style: TextStyle(color: fg.withOpacity(0.55), fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: fg.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: fg.withOpacity(0.08)),
          ),
          child: Icon(Icons.auto_graph_rounded, color: fg, size: 20),
        ),
      ],
    );
  }

  // ── DATE NAVIGATOR ────────────────────────────────────────────────────────
  Widget _dateNavigator(Color fg, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _chevronBtn(Icons.chevron_left_rounded, fg, () => _shiftDate(-1)),
        Expanded(
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
              child: Text(
                _dateLabel,
                key: ValueKey(_dateLabel),
                style: TextStyle(color: fg, fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.5),
              ),
            ),
          ),
        ),
        _chevronBtn(Icons.chevron_right_rounded, fg, () => _shiftDate(1)),
      ],
    );
  }

  Widget _chevronBtn(IconData icon, Color fg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: fg.withOpacity(0.04),
          shape: BoxShape.circle,
          border: Border.all(color: fg.withOpacity(0.08)),
        ),
        child: Icon(icon, color: fg.withOpacity(0.85), size: 22),
      ),
    );
  }

  // ── AI FORECAST CARD ──────────────────────────────────────────────────────
  Widget _buildEmaForecastCard(bool isDark) {
    return FutureBuilder<ForecastResult>(
      future: ref.read(emaForecastProvider).getMonthlyForecast(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) return const SizedBox.shrink();

        final result = snapshot.data!;

        // AI Logic: Check if projected total is much higher than spent
        final bool safe = result.forecastedTotal <= (result.currentSpent * 1.5) || result.currentSpent == 0;
        final tint = safe ? AppColors.safe : AppColors.danger;
        final projected = result.forecastedTotal;
        final velocity = result.currentVelocity;

        return ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [tint.withOpacity(isDark ? 0.22 : 0.16), tint.withOpacity(isDark ? 0.08 : 0.04)],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: tint.withOpacity(0.35), width: 1),
                boxShadow: [BoxShadow(color: tint.withOpacity(0.25), blurRadius: 40, spreadRadius: -8, offset: const Offset(0, 12))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _aiBadge(tint),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: tint.withOpacity(0.18), borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(safe ? Icons.trending_down_rounded : Icons.warning_amber_rounded, size: 13, color: tint),
                            const SizedBox(width: 4),
                            Text(safe ? 'On track' : 'High Velocity', style: TextStyle(color: tint, fontSize: 11, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text('Projected Month-End Total', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text('Rs. ${_fmt(projected)}', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0A0A0A), fontSize: 38, fontWeight: FontWeight.w700, letterSpacing: -1.2, height: 1.05)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(Icons.bolt_rounded, size: 16, color: tint),
                      const SizedBox(width: 6),
                      Text('Velocity  ', style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
                      Text('Rs. ${_fmt(velocity)}/day', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0A0A0A), fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _aiBadge(Color tint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [tint.withOpacity(0.9), tint.withOpacity(0.6)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: tint.withOpacity(0.55), blurRadius: 14, spreadRadius: -2)],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('✨', style: TextStyle(fontSize: 12)),
          SizedBox(width: 5),
          Text('AI Forecast', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
        ],
      ),
    );
  }

  // ── SEGMENTED CONTROL ─────────────────────────────────────────────────────
  Widget _segmented<T>({required bool isDark, required T value, required Map<T, String> items, required ValueChanged<T> onChanged, Color? accent}) {
    final keys = items.keys.toList();
    final index = keys.indexOf(value);
    final bg = isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFEFEFF4);
    final activeBg = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);

    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: LayoutBuilder(
        builder: (context, c) {
          final itemW = (c.maxWidth - 6) / keys.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                left: index * itemW, top: 0, bottom: 0, width: itemW,
                child: Container(
                  decoration: BoxDecoration(
                    color: activeBg,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.4 : 0.08), blurRadius: 8, offset: const Offset(0, 2))],
                    border: accent != null ? Border.all(color: accent.withOpacity(0.3)) : null,
                  ),
                ),
              ),
              Row(
                children: keys.map((k) {
                  final active = k == value;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(k),
                      child: Center(
                        child: Text(
                          items[k]!,
                          style: TextStyle(
                            color: active ? (accent ?? fg) : fg.withOpacity(0.55),
                            fontSize: 13.5, fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── CHART TYPE SWITCH ───────────────────────────────────────
  Widget _chartTypeSwitch(bool isDark, Color fg, String lang) {
    Widget btn(IconData icon, ChartMode mode) {
      final active = _chart == mode;
      return GestureDetector(
        onTap: () => setState(() => _chart = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: active ? AppColors.premiumBlue : fg.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: fg.withOpacity(0.08)),
          ),
          child: Icon(icon, color: active ? Colors.white : fg.withOpacity(0.7), size: 20),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Breakdown', style: TextStyle(color: fg, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
        Row(children: [
          btn(Icons.donut_large_rounded, ChartMode.donut),
          const SizedBox(width: 8),
          btn(Icons.bar_chart_rounded, ChartMode.bar),
        ]),
      ],
    );
  }

  // ── CHART CONTAINER (Streams Logic) ───────────────────────────────────────────────────────
  Widget _chartContainer(bool isDark, Color fg, String lang, bool isYearly, bool isIncome) {
    final endMonth = DateTime(_currentDate.year, _currentDate.month + 1, 1);
    final txDao = ref.watch(transactionDaoProvider);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: fg.withOpacity(0.07)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.4 : 0.04), blurRadius: 30, offset: const Offset(0, 10))],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            child: isYearly
            // Yearly Data Stream
                ? StreamBuilder<Map<int, double>>(
              stream: txDao.watchMonthlySummary(_currentDate.year, isIncome),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                final data = snapshot.data ?? {for (var i = 1; i <= 12; i++) i: 0.0};
                bool hasData = data.values.any((amount) => amount > 0);
                if (!hasData) return _buildEmptyState(AppTranslations.getText('no_data', lang), fg);

                return _chart == ChartMode.donut
                    ? _yearlyDonutView(data, isDark, fg, lang)
                    : _yearlyBarView(data, isDark, fg, isIncome);
              },
            )
            // Monthly Data Stream
                : StreamBuilder<Map<String, double>>(
              stream: txDao.watchCategorySummary(isIncome, _currentDate, endMonth),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                final data = snapshot.data ?? {};
                if (data.isEmpty) return _buildEmptyState(AppTranslations.getText('no_data', lang), fg);

                return _chart == ChartMode.donut
                    ? _monthlyDonutView(data, isDark, fg, isIncome)
                    : _monthlyBarView(data, isDark, fg, isIncome);
              },
            ),
          ),
        ),
      ),
    );
  }

  // ── CHART VIEWS ────────────────────────────────────────────────────────────

  Widget _monthlyDonutView(Map<String, double> data, bool isDark, Color fg, bool isIncome) {
    double totalAmount = data.values.fold(0, (sum, item) => sum + item);
    int colorIndex = 0;
    final List<PieChartSectionData> sections = [];
    final List<Widget> legend = [];

    data.forEach((categoryName, amount) {
      final color = _catColors[colorIndex % _catColors.length];
      double percent = (totalAmount > 0) ? (amount / totalAmount) * 100 : 0;
      final isTouched = colorIndex == _touchedDonutIndex;

      sections.add(PieChartSectionData(
        color: color, value: amount, title: '',
        radius: isTouched ? 30 : 22,
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color, color.withOpacity(0.75)]),
      ));

      legend.add(_legendRow(color, categoryName, percent, amount, fg, colorIndex == data.length - 1));
      colorIndex++;
    });

    return Column(
      key: const ValueKey('monthly_donut'),
      children: [
        _buildDonutCore(sections, totalAmount, data.length, fg, isIncome),
        const SizedBox(height: 16),
        ...legend,
      ],
    );
  }

  Widget _yearlyDonutView(Map<int, double> data, bool isDark, Color fg, String lang) {
    double totalAmount = data.values.fold(0, (sum, item) => sum + item);
    int colorIndex = 0;
    final List<PieChartSectionData> sections = [];
    final List<Widget> legend = [];

    data.forEach((month, amount) {
      if (amount > 0) {
        final color = _catColors[colorIndex % _catColors.length];
        double percent = (totalAmount > 0) ? (amount / totalAmount) * 100 : 0;
        final isTouched = colorIndex == _touchedDonutIndex;

        sections.add(PieChartSectionData(
          color: color, value: amount, title: '',
          radius: isTouched ? 30 : 22,
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color, color.withOpacity(0.75)]),
        ));

        legend.add(_legendRow(color, _months[month - 1], percent, amount, fg, false)); // false to show all dividers
        colorIndex++;
      }
    });

    return Column(
      key: const ValueKey('yearly_donut'),
      children: [
        _buildDonutCore(sections, totalAmount, colorIndex, fg, _flow == FlowMode.income),
        const SizedBox(height: 16),
        ...legend,
      ],
    );
  }

  Widget _buildDonutCore(List<PieChartSectionData> sections, double totalAmount, int count, Color fg, bool isIncome) {
    return SizedBox(
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(PieChartData(
            startDegreeOffset: -90, sectionsSpace: 3, centerSpaceRadius: 80,
            pieTouchData: PieTouchData(touchCallback: (event, resp) {
              setState(() {
                if (!event.isInterestedForInteractions || resp == null || resp.touchedSection == null) {
                  _touchedDonutIndex = null; return;
                }
                _touchedDonutIndex = resp.touchedSection!.touchedSectionIndex;
              });
            }),
            sections: sections,
          )),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isIncome ? 'Total earned' : 'Total spent', style: TextStyle(color: fg.withOpacity(0.55), fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text('Rs. ${_fmt(totalAmount)}', style: TextStyle(color: fg, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.8)),
              const SizedBox(height: 2),
              Text('$count items', style: TextStyle(color: fg.withOpacity(0.45), fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendRow(Color color, String name, double pct, double amount, Color fg, bool isLast) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: fg.withOpacity(0.06)))),
      child: Row(
        children: [
          Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(color: fg, fontSize: 14.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text('${pct.toStringAsFixed(1)}%', style: TextStyle(color: fg.withOpacity(0.55), fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Text('Rs. ${_fmt(amount)}', style: TextStyle(color: fg, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
        ],
      ),
    );
  }

  // ── BAR VIEWS ──────────────────────────────────────────────────────────────
  Widget _yearlyBarView(Map<int, double> data, bool isDark, Color fg, bool isIncome) {
    final color = isIncome ? AppColors.income : AppColors.expense;
    final maxY = (data.values.reduce((a, b) => a > b ? a : b)) * 1.25;
    final total = data.values.fold(0.0, (s, v) => s + v);

    return Column(
      key: const ValueKey('yearly_bar'),
      children: [
        _buildBarHeader(fg, color, isIncome, total, 'Monthly'),
        const SizedBox(height: 28),
        SizedBox(
          height: 240,
          child: BarChart(BarChartData(
            maxY: maxY == 0 ? 100 : maxY,
            alignment: BarChartAlignment.spaceAround,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => isDark ? const Color(0xFF2C2C2E) : const Color(0xFF0A0A0A),
                getTooltipItem: (group, gi, rod, ri) => BarTooltipItem('Rs. ${_fmt(rod.toY)}', const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ),
            gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxY == 0 ? 25 : maxY / 4, getDrawingHorizontalLine: (_) => FlLine(color: fg.withOpacity(0.06), strokeWidth: 1)),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              show: true, topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true, reservedSize: 28,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt() - 1;
                    if (i < 0 || i >= 12) return const SizedBox();
                    const monthInitials = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                    return Padding(padding: const EdgeInsets.only(top: 8), child: Text(monthInitials[i], style: TextStyle(color: fg.withOpacity(0.55), fontSize: 11, fontWeight: FontWeight.w600)));
                  },
                ),
              ),
            ),
            barGroups: List.generate(12, (i) {
              return BarChartGroupData(
                x: i + 1,
                barRods: [
                  BarChartRodData(
                    toY: data[i + 1] ?? 0.0, width: 14, borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color, color.withOpacity(0.4)]),
                    backDrawRodData: BackgroundBarChartRodData(show: true, toY: maxY == 0 ? 100 : maxY, color: fg.withOpacity(0.04)),
                  ),
                ],
              );
            }),
          )),
        ),
      ],
    );
  }

  Widget _monthlyBarView(Map<String, double> data, bool isDark, Color fg, bool isIncome) {
    final color = isIncome ? AppColors.income : AppColors.expense;

    // මාසික Bar Chart එක සඳහා වැඩිම අගයන් ඇති Categories 5 ක් තෝරාගැනීම
    var sortedEntries = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    var top5 = sortedEntries.take(5).toList();

    final maxY = top5.isEmpty ? 100 : (top5.map((e) => e.value).reduce((a, b) => a > b ? a : b)) * 1.25;
    final total = data.values.fold(0.0, (s, v) => s + v);

    return Column(
      key: const ValueKey('monthly_bar'),
      children: [
        _buildBarHeader(fg, color, isIncome, total, 'Top Categories'),
        const SizedBox(height: 28),
        SizedBox(
          height: 240,
          child: BarChart(BarChartData(
            maxY: maxY == 0 ? 100 : maxY.toDouble(),
            alignment: BarChartAlignment.spaceAround,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => isDark ? const Color(0xFF2C2C2E) : const Color(0xFF0A0A0A),
                getTooltipItem: (group, gi, rod, ri) => BarTooltipItem('Rs. ${_fmt(rod.toY)}', const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ),
            gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxY == 0 ? 25 : maxY / 4, getDrawingHorizontalLine: (_) => FlLine(color: fg.withOpacity(0.06), strokeWidth: 1)),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              show: true, topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true, reservedSize: 28,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= top5.length) return const SizedBox();
                    // නමේ මුල් අකුරු 3 පමණක් පෙන්වීම
                    String name = top5[i].key;
                    String shortName = name.length > 3 ? name.substring(0, 3) : name;
                    return Padding(padding: const EdgeInsets.only(top: 8), child: Text(shortName, style: TextStyle(color: fg.withOpacity(0.55), fontSize: 11, fontWeight: FontWeight.w600)));
                  },
                ),
              ),
            ),
            barGroups: List.generate(top5.length, (i) {
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: top5[i].value, width: 22, borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color, color.withOpacity(0.4)]),
                    backDrawRodData: BackgroundBarChartRodData(show: true, toY: maxY == 0 ? 100 : maxY.toDouble(), color: fg.withOpacity(0.04)),
                  ),
                ],
              );
            }),
          )),
        ),
      ],
    );
  }

  Widget _buildBarHeader(Color fg, Color color, bool isIncome, double total, String chipText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isIncome ? 'Total earned' : 'Total spent', style: TextStyle(color: fg.withOpacity(0.55), fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text('Rs. ${_fmt(total)}', style: TextStyle(color: fg, fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.8)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
          child: Text(chipText, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, Color fg) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.query_stats_rounded, size: 64, color: fg.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(message, style: TextStyle(color: fg.withOpacity(0.6), fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  final double size;
  const _Glow({required this.color, required this.size});
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, color.withOpacity(0)])),
      ),
    );
  }
}