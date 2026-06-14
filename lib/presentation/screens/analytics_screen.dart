import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/database_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  bool _isIncome = false;
  bool _isYearlyView = false;

  late DateTime _currentMonth;
  late int _currentYear;

  final List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
    _currentYear = now.year;
  }

  void _prevPeriod() {
    setState(() {
      if (_isYearlyView) _currentYear--;
      else _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextPeriod() {
    setState(() {
      if (_isYearlyView) _currentYear++;
      else _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).colorScheme.surface;
    final primaryColor = _isIncome ? Colors.green.shade600 : Colors.red.shade600;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildPremiumHeader(primaryColor),
            const SizedBox(height: 20),
            _buildSlidingToggles(primaryColor),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: _isYearlyView ? _buildYearlyBarChart(primaryColor) : _buildMonthlyPieChart(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(Color primaryColor) {
    String dateText = _isYearlyView ? 'Year $_currentYear' : '${_monthNames[_currentMonth.month - 1]} ${_currentMonth.year}';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_isIncome ? 'Income Analytics' : 'Expense Analytics', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dateText, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              Container(
                decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                child: Row(
                  children: [
                    IconButton(icon: Icon(Icons.chevron_left_rounded, color: primaryColor), onPressed: _prevPeriod),
                    IconButton(icon: Icon(Icons.chevron_right_rounded, color: primaryColor), onPressed: _nextPeriod),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlidingToggles(Color primaryColor) {
    return Column(
      children: [
        _buildSingleToggle(title: 'Period:', option1: 'Monthly', option2: 'Yearly', isOption2Selected: _isYearlyView, onChanged: (val) => setState(() => _isYearlyView = val)),
        const SizedBox(height: 12),
        _buildSingleToggle(title: 'Type:', option1: 'Expenses', option2: 'Income', isOption2Selected: _isIncome, activeColor: primaryColor, onChanged: (val) => setState(() => _isIncome = val)),
      ],
    );
  }

  Widget _buildSingleToggle({required String title, required String option1, required String option2, required bool isOption2Selected, required Function(bool) onChanged, Color? activeColor}) {
    final themeColor = activeColor ?? Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey))),
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
              child: Stack(
                children: [
                  AnimatedAlign(duration: const Duration(milliseconds: 200), alignment: isOption2Selected ? Alignment.centerRight : Alignment.centerLeft, child: FractionallySizedBox(widthFactor: 0.5, child: Container(decoration: BoxDecoration(color: themeColor, borderRadius: BorderRadius.circular(20))))),
                  Row(
                    children: [
                      Expanded(child: GestureDetector(onTap: () => onChanged(false), behavior: HitTestBehavior.opaque, child: Center(child: Text(option1, style: TextStyle(fontWeight: FontWeight.bold, color: !isOption2Selected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant))))),
                      Expanded(child: GestureDetector(onTap: () => onChanged(true), behavior: HitTestBehavior.opaque, child: Center(child: Text(option2, style: TextStyle(fontWeight: FontWeight.bold, color: isOption2Selected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant))))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyPieChart() {
    final endMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    return StreamBuilder<Map<String, double>>(
      stream: ref.watch(transactionDaoProvider).watchCategorySummary(_isIncome, _currentMonth, endMonth),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data ?? {};
        if (data.isEmpty) return _buildEmptyState('No transactions recorded.');

        final colors = [const Color(0xFF6366F1), const Color(0xFF10B981), const Color(0xFFF59E0B), const Color(0xFFEF4444), const Color(0xFF8B5CF6), const Color(0xFFEC4899), const Color(0xFF14B8A6)];
        double totalAmount = data.values.fold(0, (sum, item) => sum + item);
        int colorIndex = 0;
        final List<PieChartSectionData> sections = [];
        final List<Widget> legend = [];

        data.forEach((categoryName, amount) {
          final color = colors[colorIndex % colors.length];
          double percent = (totalAmount > 0) ? (amount / totalAmount) * 100 : 0;
          sections.add(PieChartSectionData(color: color, value: amount, title: '', radius: 50));
          legend.add(_buildLegendTile(color, categoryName, amount, percent));
          colorIndex++;
        });

        return Column(
          children: [
            SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(PieChartData(sections: sections, centerSpaceRadius: 65, sectionsSpace: 3, startDegreeOffset: -90)),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Total', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      Text('Rs. ${totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            Expanded(child: ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: legend)),
          ],
        );
      },
    );
  }

  Widget _buildLegendTile(Color color, String name, double amount, double percent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                Text('(${percent.toStringAsFixed(1)}%)', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w400)),
              ],
            ),
          ),
          Text('Rs. ${amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildYearlyBarChart(Color primaryColor) {
    return StreamBuilder<Map<int, double>>(
      stream: ref.watch(transactionDaoProvider).watchMonthlySummary(_currentYear, _isIncome),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data ?? {for (var i = 1; i <= 12; i++) i: 0.0};
        bool hasData = data.values.any((amount) => amount > 0);
        if (!hasData) return _buildEmptyState('No data available for $_currentYear.');

        List<BarChartGroupData> barGroups = [];
        final List<Gradient> barGradients = [LinearGradient(colors: [primaryColor, primaryColor.withOpacity(0.6)], begin: Alignment.bottomCenter, end: Alignment.topCenter)];

        for (int month = 1; month <= 12; month++) {
          final amount = data[month] ?? 0.0;
          barGroups.add(BarChartGroupData(x: month, barRods: [BarChartRodData(toY: amount, gradient: barGradients[0], width: 14, borderRadius: BorderRadius.circular(4))]));
        }

        return Padding(
          padding: const EdgeInsets.only(top: 16, right: 8),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barGroups: barGroups,
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const monthInitials = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                      final index = value.toInt() - 1;
                      if (index >= 0 && index < 12) return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(monthInitials[index], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)));
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const Text('');
                      return Text('${(value / 1000).toStringAsFixed(0)}k', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey));
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.query_stats_rounded, size: 64, color: Colors.grey.shade400), const SizedBox(height: 16), Text(message, style: TextStyle(color: Colors.grey.shade600, fontSize: 16))]));
  }
}