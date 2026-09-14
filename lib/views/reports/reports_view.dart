import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import '../../controllers/report_controller.dart';
import '../../controllers/task_controller.dart';
import '../../models/report_model.dart';
import '../../utils/app_theme.dart';

enum _ChartKind { bar, pie, line }

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  _ChartKind _kind = _ChartKind.bar;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ReportController());
    final today = DateTime.now();

    return Column(
      children: [
        Material(
          color: Theme.of(context).appBarTheme.backgroundColor,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: AppColors.signalTeal,
            tabs: const [Tab(text: 'Daily'), Tab(text: 'Weekly'), Tab(text: 'Monthly')],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _DailyTab(controller: controller, date: today),
              _PeriodTab(
                report: controller.weeklyReport(today),
                title: 'This Week',
                kind: _kind,
                onKindChanged: (k) => setState(() => _kind = k),
              ),
              _PeriodTab(
                report: controller.monthlyReport(today.year, today.month),
                title: 'This Month',
                kind: _kind,
                onKindChanged: (k) => setState(() => _kind = k),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DailyTab extends StatelessWidget {
  final ReportController controller;
  final DateTime date;
  const _DailyTab({required this.controller, required this.date});

  @override
  Widget build(BuildContext context) {
    final report = controller.dailyReportFor(date);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${date.toLocal()}'.split(' ')[0],
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${report.completionPercent.toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('completed', style: TextStyle(color: Colors.grey[600])),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _statChip('Total', report.total.toString(), Colors.blueGrey),
                    const SizedBox(width: 10),
                    _statChip('Done', report.completed.toString(), AppColors.sageGreen),
                    const SizedBox(width: 10),
                    _statChip('Missed', report.missed.toString(), AppColors.emberCoral),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (report.occasionalSummary != null) ...[
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.event_note_rounded, color: AppColors.amberGold),
              title: const Text('Occasional task today'),
              subtitle: Text(report.occasionalSummary!),
            ),
          ),
        ],
      ],
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }
}

class _PeriodTab extends StatelessWidget {
  final PeriodReport report;
  final String title;
  final _ChartKind kind;
  final ValueChanged<_ChartKind> onKindChanged;

  const _PeriodTab({
    required this.report,
    required this.title,
    required this.kind,
    required this.onKindChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        SegmentedButton<_ChartKind>(
          segments: const [
            ButtonSegment(value: _ChartKind.bar, icon: Icon(Icons.bar_chart_rounded), label: Text('Bar')),
            ButtonSegment(value: _ChartKind.pie, icon: Icon(Icons.pie_chart_rounded), label: Text('Pie')),
            ButtonSegment(value: _ChartKind.line, icon: Icon(Icons.show_chart_rounded), label: Text('Trend')),
          ],
          selected: {kind},
          onSelectionChanged: (s) => onKindChanged(s.first),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 230,
              child: _buildChart(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _priorityRow('High priority', report.high, AppColors.emberCoral),
        _priorityRow('Medium priority', report.medium, AppColors.amberGold),
        _priorityRow('Low priority', report.low, AppColors.sageGreen),
        const SizedBox(height: 16),
        if (report.occasionalItems.isNotEmpty) ...[
          const Text('Occasional Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...report.occasionalItems.map((o) => Card(
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.event_note_rounded, size: 20, color: AppColors.amberGold),
                  title: Text(o['title']),
                  subtitle: Text('${o['date'].toString().split(' ')[0]} • ${o['status']}'),
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildChart() {
    switch (kind) {
      case _ChartKind.bar:
        return _barChart();
      case _ChartKind.pie:
        return _pieChart();
      case _ChartKind.line:
        return _lineChart();
    }
  }

  Widget _barChart() {
    return BarChart(
      BarChartData(
        maxY: 100,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const labels = ['High', 'Medium', 'Low'];
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(labels[value.toInt()], style: const TextStyle(fontSize: 11)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          _bar(0, report.high.completedPercent, AppColors.emberCoral),
          _bar(1, report.medium.completedPercent, AppColors.amberGold),
          _bar(2, report.low.completedPercent, AppColors.sageGreen),
        ],
      ),
    );
  }

  BarChartGroupData _bar(int x, double value, Color color) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(toY: value, width: 26, color: color, borderRadius: BorderRadius.circular(6)),
    ]);
  }

  Widget _pieChart() {
    final total = report.high.total + report.medium.total + report.low.total;
    final completed = report.high.completed + report.medium.completed + report.low.completed;
    final missed = total - completed;
    if (total == 0) {
      return const Center(child: Text('No data for this period yet'));
    }
    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 36,
              sections: [
                PieChartSectionData(
                  value: completed.toDouble(),
                  color: AppColors.signalTeal,
                  title: '$completed',
                  radius: 50,
                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                PieChartSectionData(
                  value: missed.toDouble(),
                  color: AppColors.emberCoral.withOpacity(0.7),
                  title: '$missed',
                  radius: 50,
                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _legendDot('Completed', AppColors.signalTeal),
            const SizedBox(height: 8),
            _legendDot('Missed', AppColors.emberCoral.withOpacity(0.7)),
          ],
        ),
      ],
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _lineChart() {
    final taskCtrl = Get.find<TaskController>();
    final reportCtrl = Get.find<ReportController>();
    final days = <DateTime>[];
    for (DateTime d = report.start; !d.isAfter(report.end); d = d.add(const Duration(days: 1))) {
      days.add(d);
    }
    final spots = <FlSpot>[];
    for (int i = 0; i < days.length; i++) {
      final daily = reportCtrl.dailyReportFor(days[i]);
      spots.add(FlSpot(i.toDouble(), daily.completionPercent));
    }
    if (spots.isEmpty) return const Center(child: Text('No data for this period yet'));

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, interval: 25, reservedSize: 32,
                getTitlesWidget: (v, m) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10))),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (days.length / 6).clamp(1, days.length).toDouble(),
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= days.length) return const Text('');
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('${days[i].day}', style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.signalTeal,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: AppColors.signalTeal.withOpacity(0.15)),
          ),
        ],
      ),
    );
  }

  Widget _priorityRow(String label, PriorityStats stats, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Text('${stats.completed}/${stats.total} • ${stats.completedPercent.toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
