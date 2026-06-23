import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../models/transaction_model.dart';
import '../../models/activity_category_data.dart';
import '../../utils/debouncer.dart';

class ActivityViewModel extends ChangeNotifier {
  // State variables
  final List<TransactionModel> _transactions = [];

  late final Debouncer _debouncer;
  List<TransactionModel> get transactions => _transactions;

  String _selectedFilter = 'All';
  String get selectedFilter => _selectedFilter;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasError = false;
  bool get hasError => _hasError;

  bool _isFetchingMore = false;
  bool get isFetchingMore => _isFetchingMore;

  bool _hasMoreData = true;
  bool get hasMoreData => _hasMoreData;

  DocumentSnapshot? _lastVisibleDoc;

  List<TransactionModel> _filteredTransactions = [];
  List<TransactionModel> get filteredTransactions => _filteredTransactions;

  double _totalIncome = 0.0;
  double get totalIncome => _totalIncome;

  double _totalExpense = 0.0;
  double get totalExpense => _totalExpense;

  List<double> _weeklySpending = List.filled(7, 0.0);
  List<double> get weeklySpending => _weeklySpending;

  List<ActivityCategoryData> _categories = [];
  List<ActivityCategoryData> get categories => List.unmodifiable(_categories);

  final List<String> _filters = [
    'All',
    'Shopping',
    'Food',
    'Bills',
    'Transfer',
  ];
  List<String> get filters => _filters;

  final List<String> _weekDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  List<String> get weekDays => _weekDays;

  // Date filter state
  DateTime? _startDate;
  DateTime? get startDate => _startDate;

  DateTime? _endDate;
  DateTime? get endDate => _endDate;

  // Category breakdown for analytics
  Map<String, double> get categoryBreakdown {
    final Map<String, double> breakdown = {};
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return breakdown;

    final String currentUid = user.uid;

    for (final t in _filteredTransactions) {
      final double amountVal = t.amountValue;
      final bool isExpense = t.senderUid == currentUid;

      if (isExpense) {
        final String cat = t.category.isEmpty ? 'Other' : t.category;
        breakdown[cat] = (breakdown[cat] ?? 0.0) + amountVal;
      }
    }

    return breakdown;
  }

  // Total income from filtered transactions
  double get filteredTotalIncome {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0.0;
    final String currentUid = user.uid;

    return _filteredTransactions
        .where((t) => t.recipientUid == currentUid)
        .fold(0.0, (sum, t) => sum + t.amountValue);
  }

  // Total expense from filtered transactions
  double get filteredTotalExpense {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0.0;
    final String currentUid = user.uid;

    return _filteredTransactions
        .where((t) => t.senderUid == currentUid)
        .fold(0.0, (sum, t) => sum + t.amountValue);
  }

  ActivityViewModel() {
    _debouncer = Debouncer(
      delay: const Duration(milliseconds: 500),
      onSearch: (query) {
        _searchQuery = query;
        _applyFiltersAndSearch();
      },
    );
  }

  /// Group filtered transactions by date for date-separator display
  Map<String, List<TransactionModel>> get groupedTransactions {
    final Map<String, List<TransactionModel>> groups = {};
    final now = DateTime.now();
    for (final t in _filteredTransactions) {
      String label;
      if (t.timestamp == null) {
        label = 'Unknown';
      } else {
        final diff = now.difference(t.timestamp!).inDays;
        if (diff == 0) {
          label = 'Today';
        } else if (diff == 1) {
          label = 'Yesterday';
        } else {
          label = DateFormat('d MMM').format(t.timestamp!);
        }
      }
      groups.putIfAbsent(label, () => []);
      groups[label]!.add(t);
    }
    return groups;
  }

  // Methods
  Future<void> fetchTransactions({bool isRefresh = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String currentUid = user.uid;

    if (isRefresh) {
      _isLoading = true;
      _transactions.clear();
      _lastVisibleDoc = null;
      _hasMoreData = true;
    } else {
      _isFetchingMore = true;
    }
    notifyListeners();

    try {
      QuerySnapshot outgoingSnapshot;
      QuerySnapshot incomingSnapshot;

      if (isRefresh || _lastVisibleDoc == null) {
        outgoingSnapshot = await FirebaseFirestore.instance
            .collection('transactions')
            .where('sender_uid', isEqualTo: currentUid)
            .orderBy('timestamp', descending: true)
            .limit(15)
            .get();

        incomingSnapshot = await FirebaseFirestore.instance
            .collection('transactions')
            .where('recipient_uid', isEqualTo: currentUid)
            .orderBy('timestamp', descending: true)
            .limit(15)
            .get();
      } else {
        outgoingSnapshot = await FirebaseFirestore.instance
            .collection('transactions')
            .where('sender_uid', isEqualTo: currentUid)
            .orderBy('timestamp', descending: true)
            .startAfterDocument(_lastVisibleDoc!)
            .limit(15)
            .get();

        incomingSnapshot = await FirebaseFirestore.instance
            .collection('transactions')
            .where('recipient_uid', isEqualTo: currentUid)
            .orderBy('timestamp', descending: true)
            .startAfterDocument(_lastVisibleDoc!)
            .limit(15)
            .get();
      }

      final combinedDocs = [...outgoingSnapshot.docs, ...incomingSnapshot.docs];
      final seenIds = <String>{};
      final uniqueDocs = combinedDocs
          .where((doc) => seenIds.add(doc.id))
          .toList();

      uniqueDocs.sort((a, b) {
        final aData = (a.data() ?? {}) as Map<String, dynamic>;
        final bData = (b.data() ?? {}) as Map<String, dynamic>;
        final aTime =
            (aData['timestamp'] as Timestamp?)?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bTime =
            (bData['timestamp'] as Timestamp?)?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      if (uniqueDocs.isEmpty) {
        _hasMoreData = false;
      } else {
        _lastVisibleDoc = uniqueDocs.last;

        final existingIds = _transactions.map((t) => t.id).toSet();
        for (var doc in uniqueDocs) {
          if (!existingIds.contains(doc.id)) {
            final data = doc.data() as Map<String, dynamic>;
            final transaction = TransactionModel.fromMap(data);
            _transactions.add(transaction);
          }
        }
      }

      _applyFiltersAndSearch(); // Apply filters and search after new data is added

      _isLoading = false;
      _isFetchingMore = false;
      _hasError = false;
    } catch (e, stackTrace) {
      debugPrint('ActivityViewModel: Error fetching transactions: $e');
      debugPrint('ActivityViewModel: Stack trace: $stackTrace');
      _isLoading = false;
      _isFetchingMore = false;
      _hasError = true;
    }
    notifyListeners();
  }

  void _calculateStats() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String currentUid = user.uid;
    double tempIncome = 0.0;
    double tempExpense = 0.0;
    List<double> tempWeekly = List.filled(7, 0.0);
    Map<String, double> catTotals = {};
    double totalCatExpense = 0.0;

    // Use filtered transactions for stats when filters are active
    final statsTransactions = _filteredTransactions;

    for (var t in statsTransactions) {
      final double amountVal = t.amountValue;

      final bool isExpense = t.senderUid == currentUid;
      final bool isIncome = t.recipientUid == currentUid;

      if (isExpense) {
        tempExpense += amountVal;
        final String cat = t.category.isEmpty ? 'Other' : t.category;
        catTotals[cat] = (catTotals[cat] ?? 0.0) + amountVal;
        totalCatExpense += amountVal;

        if (t.timestamp != null) {
          // Adjust weekday indexing (Flutter: 1=Mon, 7=Sun)
          final int dayIndex = t.timestamp!.weekday - 1;
          if (dayIndex >= 0 && dayIndex < 7) {
            tempWeekly[dayIndex] += amountVal;
          }
        }
      } else if (isIncome) {
        tempIncome += amountVal;
      }
    }

    List<ActivityCategoryData> tempCategories = [];
    List<Color> catColors = [
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF3B82F6),
    ];
    int colorIdx = 0;

    catTotals.forEach((key, value) {
      int percentage = totalCatExpense > 0
          ? ((value / totalCatExpense) * 100).round()
          : 0;
      if (percentage > 0) {
        tempCategories.add(
          ActivityCategoryData(
            key,
            percentage,
            catColors[colorIdx % catColors.length],
          ),
        );
        colorIdx++;
      }
    });
    tempCategories.sort((a, b) => b.percentage.compareTo(a.percentage));

    _totalIncome = tempIncome;
    _totalExpense = tempExpense;
    _weeklySpending = tempWeekly;
    _categories = tempCategories;
  }

  void setSelectedFilter(String filter) {
    _selectedFilter = filter;
    _applyFiltersAndSearch();
  }

  void onSearchQueryChanged(String query) {
    _debouncer.call(query);
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    _applyFiltersAndSearch();
  }

  void _applyFiltersAndSearch() {
    List<TransactionModel> tempTransactions = _transactions;

    // Apply filter
    if (_selectedFilter != 'All') {
      tempTransactions = tempTransactions
          .where((t) => t.category == _selectedFilter)
          .toList();
    }

    // Apply date range filter
    if (_startDate != null && _endDate != null) {
      // Normalize dates to start and end of day
      final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
      final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);

      tempTransactions = tempTransactions.where((t) {
        if (t.timestamp == null) return false;
        return t.timestamp!.isAfter(start.subtract(const Duration(seconds: 1))) &&
               t.timestamp!.isBefore(end.add(const Duration(seconds: 1)));
      }).toList();
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      final queryLower = _searchQuery.toLowerCase();
      tempTransactions = tempTransactions.where((t) {
        final amountString = t.amount.toLowerCase();
        final referenceId = t.id.toLowerCase();
        final merchantName = t.merchantName.toLowerCase();
        final recipientNote = t.recipientNote?.toLowerCase() ?? '';

        return merchantName.contains(queryLower) ||
            recipientNote.contains(queryLower) ||
            referenceId.contains(queryLower) ||
            amountString.contains(queryLower);
      }).toList();
    }

    _filteredTransactions = tempTransactions;
    _calculateStats(); // Recalculate stats whenever filters change
    notifyListeners();
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    await fetchTransactions(isRefresh: true);
  }

  void loadMore() {
    if (!_isFetchingMore && _hasMoreData) {
      fetchTransactions(isRefresh: false);
    }
  }

  Future<List<TransactionModel>> getTransactionsForDateRange(DateTime start, DateTime end) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      final String currentUid = user.uid;

      // Normalize dates to start and end of day
      final normalizedStart = DateTime(start.year, start.month, start.day);
      final normalizedEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);

      final outgoingSnapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('sender_uid', isEqualTo: currentUid)
          .where('timestamp', isGreaterThanOrEqualTo: normalizedStart)
          .where('timestamp', isLessThanOrEqualTo: normalizedEnd)
          .orderBy('timestamp', descending: true)
          .get();

      final incomingSnapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('recipient_uid', isEqualTo: currentUid)
          .where('timestamp', isGreaterThanOrEqualTo: normalizedStart)
          .where('timestamp', isLessThanOrEqualTo: normalizedEnd)
          .orderBy('timestamp', descending: true)
          .get();

      final combinedDocs = [...outgoingSnapshot.docs, ...incomingSnapshot.docs];
      final seenIds = <String>{};
      final uniqueDocs = combinedDocs
          .where((doc) => seenIds.add(doc.id))
          .toList();

      uniqueDocs.sort((a, b) {
        final aData = (a.data() ?? {});
        final bData = (b.data() ?? {});
        final aTime =
            (aData['timestamp'] as Timestamp?)?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bTime =
            (bData['timestamp'] as Timestamp?)?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      return uniqueDocs.map((doc) {
        final data = doc.data();
        return TransactionModel.fromMap(data);
      }).toList();
    } catch (e, stackTrace) {
      debugPrint('ActivityViewModel: Error fetching transactions for date range: $e');
      debugPrint('ActivityViewModel: Stack trace: $stackTrace');
      return [];
    }
  }
}