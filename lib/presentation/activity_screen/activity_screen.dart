import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation.dart';
import '../../routes/app_routes.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  int _currentNavIndex = 2;
  String _selectedFilter = 'All';
  bool _isLoading = false;
  bool _hasError = false;

  final List<String> _filters = [
    'All',
    'Shopping',
    'Food',
    'Bills',
    'Transfer',
  ];

  // Weekly spending data (Mon-Sun)
  // Weekly spending data (Mon-Sun)
  List<double> _weeklySpending = List.filled(7, 0.0); // Diisi 0 semua dari Senin-Minggu
  final List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // Category breakdown & Summary
  List<_CategoryData> _categories = [];
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;

  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchFirebaseTransactions();
  }

  void _fetchFirebaseTransactions() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      
      final List<Map<String, dynamic>> liveData = [];
      
      // Variabel penampung hitungan sementara
      double tempIncome = 0.0;
      double tempExpense = 0.0;
      List<double> tempWeekly = List.filled(7, 0.0);
      Map<String, double> catTotals = {};
      double totalCatExpense = 0.0;

      // Cari rentang tanggal minggu ini (Senin - Minggu)
      DateTime now = DateTime.now();
      int currentWeekday = now.weekday; 
      DateTime startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: currentWeekday - 1));
      DateTime endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final amountVal = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final currency = data['currency'] ?? 'IDR';
        
        final isExpense = data['type'] == 'transfer_out'; 
        final category = isExpense ? 'Transfer' : 'Shopping'; 
        
        String amountStr = amountVal.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
        String prefix = currency == 'USD' ? '\$' : (currency == 'CNY' ? '¥ ' : 'Rp ');
        
        Timestamp? ts = data['timestamp'] as Timestamp?;
        DateTime dt = ts != null ? ts.toDate() : DateTime.now();
        
        // --- PROSES HITUNG MATEMATIKA ---
        if (isExpense) {
          tempExpense += amountVal;
          catTotals[category] = (catTotals[category] ?? 0.0) + amountVal;
          totalCatExpense += amountVal;

          if (dt.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && 
              dt.isBefore(endOfWeek.add(const Duration(seconds: 1)))) {
            int dayIndex = dt.weekday - 1; 
            tempWeekly[dayIndex] += amountVal;
          }
        } else {
          tempIncome += amountVal;
        }

        liveData.add({
          'id': doc.id,
          'date': DateFormat('MMM d').format(dt),
          'name': data['recipientName'] ?? 'Unknown Merchant',
          'category': category,
          'amount': isExpense ? '-$prefix$amountStr' : '+$prefix$amountStr', 
          'amountSign': isExpense ? -1 : 1,
          'currency': currency,
          'icon': Icons.swap_horiz_rounded,
          'color': const Color(0xFF3B82F6),
          'time': DateFormat('HH:mm').format(dt),
          'status': data['status'] ?? 'completed',
        });
      }

      // Olah persentase Category Breakdown
      List<_CategoryData> tempCategories = [];
      List<Color> catColors = [const Color(0xFF8B5CF6), AppTheme.warning, AppTheme.error, const Color(0xFF3B82F6)];
      int colorIdx = 0;
      
      catTotals.forEach((key, value) {
        int percentage = totalCatExpense > 0 ? ((value / totalCatExpense) * 100).round() : 0;
        if (percentage > 0) {
          tempCategories.add(_CategoryData(key, percentage, catColors[colorIdx % catColors.length]));
          colorIdx++;
        }
      });
      tempCategories.sort((a, b) => b.percentage.compareTo(a.percentage));

      if (mounted) {
        setState(() {
          _transactions = liveData;
          _totalIncome = tempIncome;
          _totalExpense = tempExpense;
          _weeklySpending = tempWeekly;
          _categories = tempCategories;
          _isLoading = false;
        });
      }
    }, onError: (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        _showConnectionErrorModal();
      }
    });
  }
  void _onNavTap(int index) {
    setState(() => _currentNavIndex = index);
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.homeScreen,
        (_) => false,
      );
    } else if (index == 1) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.transferKeypadScreen,
        (_) => false,
      );
    } else if (index == 3) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.profileScreen,
        (_) => false,
      );
    }
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    if (_selectedFilter == 'All') return _transactions;
    return _transactions
        .where((t) => t['category'] == _selectedFilter)
        .toList();
  }

  List<String> get _groupedDates {
    final dates = <String>[];
    for (final t in _filteredTransactions) {
      if (!dates.contains(t['date'])) dates.add(t['date'] as String);
    }
    return dates;
  }

  void _showConnectionErrorModal() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(160),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.error.withAlpha(80),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Error icon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppTheme.errorMuted,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.error.withAlpha(80),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.wifi_off_rounded,
                        color: AppTheme.error,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Connection Lost',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Unable to reach the server. Please check your internet connection and try again.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.errorMuted,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.error.withAlpha(60),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: AppTheme.error,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Error code: NET_ERR_CONNECTION_REFUSED',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: AppTheme.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textSecondary,
                              side: const BorderSide(
                                color: AppTheme.glassBorder,
                                width: 0.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              'Dismiss',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              setState(() {
                                _hasError = false;
                                _isLoading = true;
                              });
                              Future.delayed(
                                const Duration(milliseconds: 1500),
                                () {
                                  if (mounted) {
                                    setState(() => _isLoading = false);
                                  }
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.error,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              'Try Again',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: _isLoading
                  ? _buildShimmerState()
                  : ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(0, 4, 0, 100),
                      children: [
                        _buildSpendingAnalysis(),
                        _buildSummaryRow(),
                        _buildFilterChips(),
                        const SizedBox(height: 8),
                        if (_filteredTransactions.isEmpty)
                          _buildEmptyState()
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                for (final date in _groupedDates) ...[
                                  _buildDateSeparator(date),
                                  ..._filteredTransactions
                                      .where((t) => t['date'] == date)
                                      .map((t) => _buildTransactionCard(t)),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppNavigation(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Text(
            'Activity',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _showConnectionErrorModal,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.glassBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.glassBorder, width: 0.5),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: AppTheme.textSecondary,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Spending Analysis Section ─────────────────────────────────────────────

  Widget _buildSpendingAnalysis() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.glassBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.glassBorder, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      'Spending Analysis',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.successMuted,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'This Week',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Line chart
                _buildLineChart(),
                const SizedBox(height: 20),
                Container(height: 0.5, color: AppTheme.separator),
                const SizedBox(height: 16),
                // Category breakdown
                Row(
                  children: [
                    Text(
                      'Category Breakdown',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildCategoryBreakdown(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    final maxVal = _weeklySpending.reduce((a, b) => a > b ? a : b);
    final interval = maxVal > 0 ? maxVal / 3 : 1.0;
    return SizedBox(
      height: 120,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: AppTheme.separator, strokeWidth: 0.5),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= _weekDays.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    _weekDays[idx],
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 6,
          minY: 0,
          maxY: maxVal > 0 ? maxVal * 1.2 : 100.0,
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                _weeklySpending.length,
                (i) => FlSpot(i.toDouble(), _weeklySpending[i]),
              ),
              isCurved: true,
              curveSmoothness: 0.35,
              gradient: const LinearGradient(
                colors: [AppTheme.success, Color(0xFF34D399)],
              ),
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                      radius: 3,
                      color: AppTheme.success,
                      strokeWidth: 1.5,
                      strokeColor: AppTheme.background,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.success.withAlpha(60),
                    AppTheme.success.withAlpha(0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    return Row(
      children: [
        // Donut chart
        SizedBox(
          width: 80,
          height: 80,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 24,
              sections: _categories
                  .map(
                    (c) => PieChartSectionData(
                      value: c.percentage.toDouble(),
                      color: c.color,
                      radius: 16,
                      showTitle: false,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        const SizedBox(width: 20),
        // Legend
        Expanded(
          child: Column(
            children: _categories
                .map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: c.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          c.name,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${c.percentage}%',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: c.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  // ── Shimmer Loading State ─────────────────────────────────────────────────

  Widget _buildShimmerState() {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      children: [
        _buildShimmerCard(height: 260),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildShimmerCard(height: 64)),
            const SizedBox(width: 12),
            Expanded(child: _buildShimmerCard(height: 64)),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(5, (_) => _buildShimmerTransaction()),
      ],
    );
  }

  Widget _buildShimmerCard({required double height}) {
    return _ShimmerWidget(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildShimmerTransaction() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _ShimmerWidget(
        child: Container(
          height: 68,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 12,
                      width: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 12,
                width: 60,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Summary Row ───────────────────────────────────────────────────────────

  Widget _buildSummaryRow() {
    final NumberFormat currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Income',
              currencyFormat.format(_totalIncome),
              AppTheme.success,
              Icons.arrow_downward_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Expenses',
              currencyFormat.format(_totalExpense),
              AppTheme.error,
              Icons.arrow_upward_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String amount,
    Color color,
    IconData icon,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withAlpha(60), width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                    ),
                  ),
                  FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        amount,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                    ),
                  ),
                ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : AppTheme.glassBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : AppTheme.glassBorder,
                  width: 0.5,
                ),
              ),
              child: Text(
                filter,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateSeparator(String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(
            date,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 0.5, color: AppTheme.separator)),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final isPositive = (transaction['amountSign'] as int) > 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.glassBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.glassBorder, width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (transaction['color'] as Color).withAlpha(30),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: (transaction['color'] as Color).withAlpha(60),
                      width: 0.5,
                    ),
                  ),
                  child: Icon(
                    transaction['icon'] as IconData,
                    color: transaction['color'] as Color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction['name'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: (transaction['color'] as Color).withAlpha(
                                25,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              transaction['category'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: transaction['color'] as Color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            transaction['time'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  transaction['amount'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isPositive ? AppTheme.success : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Minimalist illustration container
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.glassBackground,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.glassBorder, width: 0.5),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 18,
                    left: 18,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryMuted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 18,
                    right: 18,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppTheme.accentMuted,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.receipt_long_rounded,
                    color: AppTheme.textMuted,
                    size: 32,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Transactions Yet',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your transaction history will appear here\nonce you make your first transfer.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.transferKeypadScreen,
                (_) => false,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.accent],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withAlpha(80),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Make First Transfer',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Helper Widgets & Models ───────────────────────────────────────────────────

class _CategoryData {
  final String name;
  final int percentage;
  final Color color;
  const _CategoryData(this.name, this.percentage, this.color);
}

class _ShimmerWidget extends StatefulWidget {
  final Widget child;
  const _ShimmerWidget({required this.child});

  @override
  State<_ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<_ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _animation = Tween<double>(
      begin: -1.5,
      end: 2.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: [
            (_animation.value - 0.5).clamp(0.0, 1.0),
            _animation.value.clamp(0.0, 1.0),
            (_animation.value + 0.5).clamp(0.0, 1.0),
          ],
          colors: [
            AppTheme.surfaceVariant,
            AppTheme.surfaceElevated,
            AppTheme.surfaceVariant,
          ],
        ).createShader(bounds),
        child: widget.child,
      ),
    );
  }
}
