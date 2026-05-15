import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
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
  bool _isFetchingMore = false;
  bool _hasMoreData = true;
  DocumentSnapshot? _lastVisibleDoc;

  final List<String> _filters = ['All', 'Shopping', 'Food', 'Bills', 'Transfer'];
  List<double> _weeklySpending = List.filled(7, 0.0);
  final List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  List<_CategoryData> _categories = [];
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  List<Map<String, dynamic>> _transactions = [];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchTransactions(isRefresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isFetchingMore &&
        _hasMoreData) {
      _fetchTransactions(isRefresh: false);
    }
  }

  Future<void> _fetchTransactions({bool isRefresh = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String currentUid = user.uid;

    if (isRefresh) {
      setState(() {
        _isLoading = true;
        _transactions.clear();
        _lastVisibleDoc = null;
        _hasMoreData = true;
      });
    } else {
      setState(() => _isFetchingMore = true);
    }

    try {
      QuerySnapshot snapshot;

      if (isRefresh || _lastVisibleDoc == null) {
        snapshot = await FirebaseFirestore.instance
            .collection('transactions')
            .where(Filter.or(
              Filter('sender_uid', isEqualTo: currentUid),
              Filter('recipient_uid', isEqualTo: currentUid),
            ))
            .orderBy('timestamp', descending: true)
            .limit(15)
            .get();
      } else {
        snapshot = await FirebaseFirestore.instance
            .collection('transactions')
            .where(Filter.or(
              Filter('sender_uid', isEqualTo: currentUid),
              Filter('recipient_uid', isEqualTo: currentUid),
            ))
            .orderBy('timestamp', descending: true)
            .startAfterDocument(_lastVisibleDoc!)
            .limit(15)
            .get();
      }

      if (snapshot.docs.isEmpty) {
        setState(() => _hasMoreData = false);
      } else {
        _lastVisibleDoc = snapshot.docs.last;

        // Process and add new transactions (avoid duplicates)
        final existingIds = _transactions.map((t) => t['id'] as String).toSet();
        for (var doc in snapshot.docs) {
          if (!existingIds.contains(doc.id)) {
            final data = doc.data() as Map<String, dynamic>;
            
            // Extract names and UIDs safely
            final String senderName = (data['senderName'] ?? data['sender_name'] ?? 'Pengguna').toString();
            final String recipientName = (data['recipientName'] ?? data['recipient_name'] ?? 'Pengguna').toString();
            final String senderUid = (data['sender_uid'] ?? data['senderUid'] ?? '').toString();
            
            // Determine display name based on current user's role
            final String displayName = (currentUid == senderUid) ? recipientName : senderName;
            
            final bool isExpense = data['senderUid'] == currentUid || data['sender_uid'] == currentUid;
            final double amountVal = (data['amount'] as num?)?.toDouble() ?? 0.0;
            final String currency = data['currency'] ?? 'IDR';
            final Timestamp? ts = data['timestamp'] as Timestamp?;
            final DateTime dt = ts != null ? ts.toDate() : DateTime.now();

            String amountStr = amountVal
                .toStringAsFixed(0)
                .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
            String currencyPrefix = currency == 'USD' ? '\$' : (currency == 'CNY' ? '¥ ' : 'Rp ');

            _transactions.add({
              'id': doc.id,
              'date': DateFormat('MMM d').format(dt),
              'name': isExpense
                  ? 'Transfer ke $recipientName'
                  : 'Terima dari $senderName',
              'category': 'Transfer',
              'amount': '${isExpense ? '-' : '+'} $currencyPrefix$amountStr',
              'amountSign': isExpense ? -1 : 1,
              'currency': currency,
              'icon': isExpense ? Icons.arrow_upward : Icons.arrow_downward,
              'color': isExpense ? AppTheme.error : AppTheme.success,
              'time': DateFormat('HH:mm').format(dt),
              'status': data['status'] ?? 'completed',
            });
          }
        }
      }

      // Recalculate stats
      _calculateStats();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isFetchingMore = false;
          _hasError = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('ActivityScreen: Error fetching transactions: $e');
      debugPrint('ActivityScreen: Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isFetchingMore = false;
          _hasError = true;
        });
        _showFirestoreIndexErrorModal(e.toString());
      }
    }
  }

  void _calculateStats() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    double tempIncome = 0.0;
    double tempExpense = 0.0;
    List<double> tempWeekly = List.filled(7, 0.0);
    Map<String, double> catTotals = {};
    double totalCatExpense = 0.0;

    DateTime now = DateTime.now();

    for (var t in _transactions) {
      final bool isExpense = t['amountSign'] == -1;
      final amountStr = t['amount'] as String;
      // Extract numeric value from formatted string
      final numericStr = amountStr.replaceAll(RegExp(r'[^0-9.]'), '');
      final amountVal = double.tryParse(numericStr) ?? 0.0;

      if (isExpense) {
        tempExpense += amountVal;
        catTotals['Transfer'] = (catTotals['Transfer'] ?? 0.0) + amountVal;
        totalCatExpense += amountVal;

        // Simple approximation for weekly chart
        final dayIndex = (now.difference(DateTime(now.year, now.month, 1)).inDays) % 7;
        if (dayIndex >= 0 && dayIndex < 7) {
          tempWeekly[dayIndex] += amountVal;
        }
      } else {
        tempIncome += amountVal;
      }
    }

    // Calculate percentages
    List<_CategoryData> tempCategories = [];
    List<Color> catColors = [
      const Color(0xFF8B5CF6),
      AppTheme.warning,
      AppTheme.error,
      const Color(0xFF3B82F6),
    ];
    int colorIdx = 0;

    catTotals.forEach((key, value) {
      int percentage = totalCatExpense > 0 ? ((value / totalCatExpense) * 100).round() : 0;
      if (percentage > 0) {
        tempCategories.add(_CategoryData(key, percentage, catColors[colorIdx % catColors.length]));
        colorIdx++;
      }
    });
    tempCategories.sort((a, b) => b.percentage.compareTo(a.percentage));

    setState(() {
      _totalIncome = tempIncome;
      _totalExpense = tempExpense;
      _weeklySpending = tempWeekly;
      _categories = tempCategories;
    });
  }

  Future<void> _handleRefresh() async {
    await _fetchTransactions(isRefresh: true);
  }

  void _onNavTap(int index) {
    setState(() => _currentNavIndex = index);
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.homeScreen, (_) => false);
    } else if (index == 1) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.transferKeypadScreen, (_) => false);
    } else if (index == 3) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.profileScreen, (_) => false);
    }
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    if (_selectedFilter == 'All') return _transactions;
    return _transactions.where((t) => t['category'] == _selectedFilter).toList();
  }

  List<String> get _groupedDates {
    final dates = <String>[];
    for (final t in _filteredTransactions) {
      if (!dates.contains(t['date'])) dates.add(t['date'] as String);
    }
    return dates;
  }

  void _showFirestoreIndexErrorModal(String errorMessage) {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                  border: Border.all(color: Colors.orange.withAlpha(80), width: 0.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(40),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.orange.withAlpha(80), width: 1),
                      ),
                      child: const Icon(Icons.settings_suggest, color: Colors.orange, size: 28),
                    ),
                    const SizedBox(height: 20),
                    Text('Menyiapkan Database...',
                        style: GoogleFonts.inter(
                            fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    const SizedBox(height: 8),
                    Text(
                        'Sistem NeoPay sedang mengonfigurasi indeks untuk riwayat dua arah. Silakan klik link di terminal dan klik "Create Index". Tunggu sebentar lalu refresh.',
                        style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary, height: 1.6),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withAlpha(60)),
                      ),
                      child: Text(
                        errorMessage.length > 200 ? '${errorMessage.substring(0, 200)}...' : errorMessage,
                        style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontFamily: 'monospace'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _handleRefresh();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      ),
                      child: Text('Refresh',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
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
              child: Builder(
                builder: (context) {
                  if (_isLoading && _transactions.isEmpty) {
                    return _buildShimmerLoading();
                  }
                  if (_hasError && _transactions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Failed to load activity',
                              style: GoogleFonts.inter(color: AppTheme.textSecondary)),
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: _handleRefresh, child: const Text('Retry')),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: AppTheme.primary,
                    child: ListView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(0, 4, 0, 100),
                      children: [
                        _buildSpendingAnalysis(),
                        _buildSummaryRow(),
                        _buildFilterChips(),
                        const SizedBox(height: 8),
                        if (_filteredTransactions.isEmpty && !_isLoading)
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
                        if (_isFetchingMore) _buildLoadingMoreIndicator(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppNavigation(currentIndex: _currentNavIndex, onTap: _onNavTap),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 260,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(8, (_) => _buildTransactionShimmer()),
      ],
    );
  }

  Widget _buildTransactionShimmer() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 68,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(height: 12, width: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                    const SizedBox(height: 6),
                    Container(height: 10, width: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                  ],
                ),
              ),
              Container(height: 12, width: 60, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SpinKitThreeBounce(
          color: AppTheme.primary,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Text('Activity',
              style: GoogleFonts.inter(
                  fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const Spacer(),
          GestureDetector(
            onTap: () => _showFirestoreIndexErrorModal('Manual trigger'),
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
                  child: const Icon(Icons.tune_rounded, color: AppTheme.textSecondary, size: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
                Row(
                  children: [
                    Text('Spending Analysis',
                        style: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.successMuted,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('This Week',
                          style: GoogleFonts.inter(
                              fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.success)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildLineChart(),
                const SizedBox(height: 20),
                Container(height: 0.5, color: AppTheme.separator),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Category Breakdown',
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
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
            getDrawingHorizontalLine: (value) => FlLine(color: AppTheme.separator, strokeWidth: 0.5),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= _weekDays.length) return const SizedBox.shrink();
                  return Text(_weekDays[idx],
                      style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w500));
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
              spots: List.generate(_weeklySpending.length, (i) => FlSpot(i.toDouble(), _weeklySpending[i])),
              isCurved: true,
              curveSmoothness: 0.35,
              gradient: const LinearGradient(colors: [AppTheme.success, Color(0xFF34D399)]),
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
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
                  colors: [AppTheme.success.withAlpha(60), AppTheme.success.withAlpha(0)],
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
        SizedBox(
          width: 80,
          height: 80,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 24,
              sections: _categories
                  .map((c) => PieChartSectionData(
                        value: c.percentage.toDouble(),
                        color: c.color,
                        radius: 16,
                        showTitle: false,
                      ))
                  .toList(),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            children: _categories
                .map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: c.color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(c.name,
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                          const Spacer(),
                          Text('${c.percentage}%',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: c.color)),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow() {
    final NumberFormat currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard('Income', currencyFormat.format(_totalIncome), AppTheme.success,
                Icons.arrow_downward_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard('Expenses', currencyFormat.format(_totalExpense), AppTheme.error,
                Icons.arrow_upward_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String amount, Color color, IconData icon) {
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
                    Text(label,
                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(amount,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
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
                    color: isSelected ? AppTheme.primary : AppTheme.glassBorder, width: 0.5),
              ),
              child: Text(filter,
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppTheme.textSecondary)),
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
          Text(date,
              style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.5)),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 0.5, color: AppTheme.separator)),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final isPositive = (transaction['amountSign'] as int) > 0;
    final amountColor = transaction['color'] as Color? ??
        (isPositive ? AppTheme.success : AppTheme.error);

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
                    color: amountColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: amountColor.withAlpha(60), width: 0.5),
                  ),
                  child: Icon(transaction['icon'] as IconData, color: amountColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(transaction['name'] as String,
                          style: GoogleFonts.inter(
                              fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: amountColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(transaction['category'] as String,
                                style: GoogleFonts.inter(
                                    fontSize: 10, fontWeight: FontWeight.w600, color: amountColor)),
                          ),
                          const SizedBox(width: 6),
                          Text(transaction['time'] as String,
                              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(transaction['amount'] as String,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: amountColor)),
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
                  const Icon(Icons.receipt_long_rounded, color: AppTheme.textMuted, size: 32),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('No Transactions Yet',
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text(
                'Your transaction history will appear here\nonce you make your first transfer.',
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary, height: 1.6),
                textAlign: TextAlign.center),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => Navigator.pushNamedAndRemoveUntil(
                  context, AppRoutes.transferKeypadScreen, (_) => false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.accent],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight),
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
                    const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text('Make First Transfer',
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
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

class _CategoryData {
  final String name;
  final int percentage;
  final Color color;
  const _CategoryData(this.name, this.percentage, this.color);
}