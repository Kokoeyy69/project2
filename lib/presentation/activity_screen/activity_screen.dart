import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart'; // Import share_plus
import '../../core/services/pdf_service.dart'; // Import pdf_service.dart

import '../../theme/app_theme.dart';
import '../../widgets/app_navigation.dart';
import '../../routes/app_routes.dart';
import '../../models/transaction_model.dart';
import './activity_view_model.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ActivityViewModel()..fetchTransactions(isRefresh: true),
      child: const _ActivityScreenContent(),
    );
  }
}

class _ActivityScreenContent extends StatelessWidget {
  const _ActivityScreenContent();

  void _onNavTap(BuildContext context, int index) {
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          extendBody: true,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildAppBar(context, viewModel),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (viewModel.isLoading &&
                          viewModel.transactions.isEmpty) {
                        return _buildShimmerLoading();
                      }
                      if (viewModel.hasError &&
                          viewModel.transactions.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Failed to load activity',
                                style: GoogleFonts.inter(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => viewModel.refresh(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      return NotificationListener<ScrollEndNotification>(
                        onNotification: (notification) {
                          final metrics = notification.metrics;
                          if (metrics.pixels >= metrics.maxScrollExtent * 0.9 &&
                              !viewModel.isFetchingMore &&
                              viewModel.hasMoreData) {
                            viewModel.loadMore();
                          }
                          return false;
                        },
                        child: RefreshIndicator(
                          onRefresh: () => viewModel.refresh(),
                          color: AppTheme.primary,
                          child: ListView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(0, 4, 0, 100),
                            children: [
                              _buildSpendingAnalysis(viewModel),
                              _buildSummaryRow(viewModel),
                              _buildFilterChips(viewModel),
                              const SizedBox(height: 8),
                              if (viewModel.filteredTransactions.isEmpty &&
                                  !viewModel.isLoading)
                                _buildEmptyState()
                              else
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: Column(
                                    children: [
                                      for (final entry
                                          in viewModel
                                              .groupedTransactions
                                              .entries) ...[
                                        _buildDateSeparator(entry.key),
                                        for (final t in entry.value)
                                          _buildTransactionCard(context, t),
                                      ],
                                    ],
                                  ),
                                ),
                              if (viewModel.isFetchingMore)
                                _buildLoadingMoreIndicator(),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: AppNavigation(
            currentIndex: 2,
            onTap: (index) => _onNavTap(context, index),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, ActivityViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Activity',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (viewModel.startDate != null && viewModel.endDate != null)
                Text(
                  '${DateFormat('d MMM').format(viewModel.startDate!)} - ${DateFormat('d MMM').format(viewModel.endDate!)}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2023),
                lastDate: DateTime.now().add(const Duration(days: 1)),
                initialDateRange: viewModel.startDate != null &&
                        viewModel.endDate != null
                    ? DateTimeRange(
                        start: viewModel.startDate!,
                        end: viewModel.endDate!,
                      )
                    : null,
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: AppTheme.primary,
                        onPrimary: Colors.white,
                        onSurface: AppTheme.textPrimary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (!context.mounted) return;
              if (range != null) {
                viewModel.setDateRange(range.start, range.end);
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: viewModel.startDate != null
                        ? AppTheme.primary.withAlpha(40)
                        : AppTheme.glassBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: viewModel.startDate != null
                          ? AppTheme.primary
                          : AppTheme.glassBorder,
                      width: 0.5,
                    ),
                  ),
                  child: Icon(
                    viewModel.startDate != null
                        ? Icons.filter_alt_rounded
                        : Icons.tune_rounded,
                    color: viewModel.startDate != null
                        ? AppTheme.primary
                        : AppTheme.textSecondary,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
          if (viewModel.startDate != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => viewModel.setDateRange(null, null),
              child: Icon(
                Icons.close_rounded,
                color: AppTheme.error,
                size: 20,
              ),
            ),
          ],
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showEStatementDialog(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.glassBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.glassBorder,
                      width: 0.5,
                    ),
                  ),
                  child: Icon(
                    Icons.picture_as_pdf_rounded,
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

  Future<void> _showEStatementDialog(BuildContext context) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (range != null && context.mounted) {
      final viewModel = Provider.of<ActivityViewModel>(context, listen: false);

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );

      try {
        final transactions = await viewModel.getTransactionsForDateRange(
          range.start,
          range.end,
        );

        final List<TransactionRecord> pdfTransactions = transactions.map((t) {
          return TransactionRecord(
            id: t.id,
            merchant: t.merchantName,
            amount: t.amountValue,
            currency: t.currency,
            date: t.timestamp ?? DateTime.now(), // Default to now if timestamp is null
            category: t.category,
          );
        }).toList();

        final pdfPath = await PdfService.instance.generateMonthlyReport(
          year: range.start.year,
          month: range.start.month,
          transactions: pdfTransactions,
        );

        // Close loading dialog
        if (context.mounted) {
          Navigator.pop(context);
        }

        await Share.shareXFiles(
          [XFile(pdfPath)],
          text: 'E-Statement Report',
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('E-Statement generated and shared successfully!'),
            ),
          );
        }
      } catch (e) {
        // Close loading dialog on error
        if (context.mounted) {
          Navigator.pop(context);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to generate or share E-Statement: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  Widget _buildSpendingAnalysis(ActivityViewModel viewModel) {
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
                        viewModel.startDate != null ? 'Filtered' : 'All Time',
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
                _buildLineChart(viewModel),
                const SizedBox(height: 20),
                Container(height: 0.5, color: AppTheme.separator),
                const SizedBox(height: 16),
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
                _buildCategoryBreakdown(viewModel),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart(ActivityViewModel viewModel) {
    final maxVal = viewModel.weeklySpending.isNotEmpty
        ? viewModel.weeklySpending.reduce((a, b) => a > b ? a : b)
        : 0.0;
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
                  if (idx < 0 || idx >= viewModel.weekDays.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    viewModel.weekDays[idx],
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
                viewModel.weeklySpending.length,
                (i) => FlSpot(i.toDouble(), viewModel.weeklySpending[i]),
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

  Widget _buildCategoryBreakdown(ActivityViewModel viewModel) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 24,
              sections: viewModel.categories
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
        Expanded(
          child: Column(
            children: viewModel.categories
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

  Widget _buildSummaryRow(ActivityViewModel viewModel) {
    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Income',
              currencyFormat.format(viewModel.totalIncome),
              AppTheme.success,
              Icons.arrow_downward_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Expenses',
              currencyFormat.format(viewModel.totalExpense),
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

  Widget _buildFilterChips(ActivityViewModel viewModel) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        itemCount: viewModel.filters.length,
        itemBuilder: (context, index) {
          final filter = viewModel.filters[index];
          final isSelected = viewModel.selectedFilter == filter;
          return GestureDetector(
            onTap: () => viewModel.setSelectedFilter(filter),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : Colors.transparent,
                    width: 1,
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, TransactionModel transaction) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.transactionDetailScreen,
          arguments: transaction,
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.separator, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryMuted,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      transaction.merchantName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      transaction.timestamp?.toString().split('.')[0] ?? 'N/A',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                transaction.amount,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_rounded, size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            Text(
              'No transactions',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
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
                    Container(
                      height: 12,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
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
        child: SpinKitThreeBounce(color: AppTheme.primary, size: 20),
      ),
    );
  }
}