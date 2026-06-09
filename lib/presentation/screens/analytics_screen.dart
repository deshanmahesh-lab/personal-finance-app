import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/account_repository_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  bool _isIncome = false;
  bool _isYearlyView = false; // Monthly ද Yearly ද යන්න තීරණය කරයි

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
      if (_isYearlyView) {
        _currentYear--;
      } else {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
      }
    });
  }

  void _nextPeriod() {
    setState(() {
      if (_isYearlyView) {
        _currentYear++;
      } else {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // --- 1. View Type Toggle (Monthly / Yearly) ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Monthly View')),
                ButtonSegment(value: true, label: Text('Yearly View')),
              ],
              selected: {_isYearlyView},
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() {
                  _isYearlyView = newSelection.first;
                });
              },
            ),
          ),

          // --- 2. Income / Expense Toggle ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Expenses')),
                ButtonSegment(value: true, label: Text('Income')),
              ],
              selected: {_isIncome},
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() {
                  _isIncome = newSelection.first;
                });
              },
            ),
          ),

          // --- 3. Date / Year Selector ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: _prevPeriod),
              SizedBox(
                width: 150,
                child: Text(
                  _isYearlyView
                      ? '$_currentYear'
                      : '${_monthNames[_currentMonth.month - 1]} ${_currentMonth.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: _nextPeriod),
            ],
          ),
          const SizedBox(height: 16),

          // --- 4. Chart Display (Pie or Bar) ---
          Expanded(
            child: _isYearlyView ? _buildYearlyBarChart() : _buildMonthlyPieChart(),
          ),
        ],
      ),
    );
  }

  // --- මාසික Pie Chart එක සෑදීමේ කේතය (කලින් තිබූ කොටස) ---
  Widget _buildMonthlyPieChart() {
    final endMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);

    return StreamBuilder<Map<String, double>>(
      stream: ref.watch(accountRepositoryProvider).watchCategorySummary(_isIncome, _currentMonth, endMonth),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data ?? {};
        if (data.isEmpty) return Center(child: Text('No data for this month.', style: TextStyle(color: Colors.grey.shade600)));

        final colors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.pink, Colors.amber];
        int colorIndex = 0;
        final List<PieChartSectionData> sections = [];
        final List<Widget> indicators = [];

        data.forEach((categoryName, amount) {
          final color = colors[colorIndex % colors.length];
          sections.add(PieChartSectionData(color: color, value: amount, title: '', radius: 60));
          indicators.add(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Container(width: 16, height: 16, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(categoryName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
                    Text('Rs. ${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
          );
          colorIndex++;
        });

        return Column(
          children: [
            SizedBox(height: 250, child: PieChart(PieChartData(sections: sections, centerSpaceRadius: 70, sectionsSpace: 4))),
            const SizedBox(height: 32),
            Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 24), children: indicators)),
          ],
        );
      },
    );
  }

  // --- අලුත් කොටස: වාර්ෂික Bar Chart එක සෑදීමේ කේතය ---
  Widget _buildYearlyBarChart() {
    return StreamBuilder<Map<int, double>>(
      stream: ref.watch(accountRepositoryProvider).watchMonthlySummary(_currentYear, _isIncome),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final data = snapshot.data ?? {for (var i = 1; i <= 12; i++) i: 0.0};

        // දත්ත නොමැති දැයි පරීක්ෂා කිරීම
        bool hasData = data.values.any((amount) => amount > 0);
        if (!hasData) return Center(child: Text('No data for this year.', style: TextStyle(color: Colors.grey.shade600)));

        // Bar Chart එක සඳහා දත්ත සකස් කිරීම
        List<BarChartGroupData> barGroups = [];
        final barColor = _isIncome ? Colors.green.shade600 : Colors.red.shade600;

        for (int month = 1; month <= 12; month++) {
          final amount = data[month] ?? 0.0;
          barGroups.add(
              BarChartGroupData(
                x: month,
                barRods: [
                  BarChartRodData(
                    toY: amount,
                    color: barColor,
                    width: 16,
                    borderRadius: BorderRadius.circular(4),
                  )
                ],
              )
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
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
                      if (index >= 0 && index < 12) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(monthInitials[index], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const Text('');
                      // අගයන් කෙටි කර පෙන්වීම (උදා: 1000 -> 1k)
                      return Text('${(value / 1000).toStringAsFixed(0)}k', style: const TextStyle(fontSize: 10));
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
}