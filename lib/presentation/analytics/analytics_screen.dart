import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neopay_ai/core/services/pdf_service.dart';
import '../../theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isGeneratingPdf = false;

  final List<Map<String, dynamic>> _categoryData = [
    {'name': 'Food', 'value': 2500000.0, 'color': const Color(0xFF3B82F6)},
    {'name': 'Tech', 'value': 1800000.0, 'color': const Color(0xFF06B6D4)},
    {'name': 'Travel', 'value': 1200000.0, 'color': const Color(0xFF10B981)},
    {'name': 'Shopping', 'value': 900000.0, 'color': const Color(0xFFF59E0B)},
    {'name': 'Others', 'value': 500000.0, 'color': const Color(0xFF94A3B8)},
  ];

  final List<FlSpot> _balanceSpots = [
    FlSpot(0, 5000000), FlSpot(1, 4800000), FlSpot(2, 5200000),
    FlSpot(3, 4700000), FlSpot(4, 5300000), FlSpot(5, 4900000),
    FlSpot(6, 5500000),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _generatePdf() async {
    setState(() => _isGeneratingPdf = true);
    final transactions = [
      TransactionRecord(id: '1', merchant: 'Warung Pak Budi', amount: 45000, currency: 'IDR', date: DateTime.now().subtract(const Duration(days: 1)), category: 'Food'),
      TransactionRecord(id: '2', merchant: 'Tokopedia', amount: 1250000, currency: 'IDR', date: DateTime.now().subtract(const Duration(days: 2)), category: 'Tech'),
      TransactionRecord(id: '3', merchant: 'Grab', amount: 85000, currency: 'IDR', date: DateTime.now().subtract(const Duration(days: 3)), category: 'Travel'),
      TransactionRecord(id: '4', merchant: 'Shopee', amount: 320000, currency: 'IDR', date: DateTime.now().subtract(const Duration(days: 4)), category: 'Shopping'),
      TransactionRecord(id: '5', merchant: 'Netflix', amount: 149000, currency: 'IDR', date: DateTime.now().subtract(const Duration(days: 5)), category: 'Others'),
    ];
    try {
      final path = await PdfService.instance.generateMonthlyReport(
        year: DateTime.now().year,
        month: DateTime.now().month,
        transactions: transactions,
      );
      await PdfService.instance.shareReport(path);
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Analytics', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        actions: [
          IconButton(
            icon: _isGeneratingPdf
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                : const Icon(Icons.share_outlined, color: AppTheme.textSecondary),
            onPressed: _isGeneratingPdf ? null : _generatePdf,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMuted,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          tabs: const [Tab(text: 'Categories'), Tab(text: 'Trends')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildCategoryTab(), _buildTrendsTab()],
      ),
    );
  }

  Widget _buildCategoryTab() {
    final total = _categoryData.fold<double>(0, (s, d) => s + (d['value'] as double));
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(
            height: 240,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: _categoryData.map((d) {
                  final pct = total > 0 ? (d['value'] as double) / total * 100 : 0.0;
                  return PieChartSectionData(
                    value: d['value'] as double,
                    color: d['color'] as Color,
                    radius: 40,
                    title: '${pct.toStringAsFixed(0)}%',
                    titleStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                    titlePositionPercentageOffset: 0.6,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _categoryData.length,
              itemBuilder: (context, i) {
                final d = _categoryData[i];
                final pct = total > 0 ? (d['value'] as double) / total * 100 : 0.0;
                return _buildLegendItem(d['name'] as String, d['color'] as Color, d['value'] as double, pct);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Balance History', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text('Last 7 days', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted)),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 500000, getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.glassBorder, strokeWidth: 0.5)),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 60, getTitlesWidget: (v, _) => Text('${(v/1000000).toStringAsFixed(1)}M', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                  final idx = (v as num).toInt();
                  return Text(['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][idx % 7], style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted));
                })),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0, maxX: 6, minY: 4000000, maxY: 6000000,
                lineBarsData: [
                  LineChartBarData(
                    spots: _balanceSpots,
                    isCurved: true,
                    gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.accent]),
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(colors: [AppTheme.primary.withAlpha(51), AppTheme.primary.withAlpha(0)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                    ),
                    dotData: FlDotData(show: true, getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 4, color: AppTheme.primary, strokeWidth: 2, strokeColor: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String name, Color color, double value, double pct) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary))),
          Text('${pct.toStringAsFixed(1)}%', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          const SizedBox(width: 12),
          Text('Rp ${(value/1000000).toStringAsFixed(1)}M', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}
