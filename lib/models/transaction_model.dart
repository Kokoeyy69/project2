import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/status_badge_widget.dart';

/// Central TransactionModel used across the app.
/// Handles both snake_case and CamelCase field names from Firestore
/// and resolves display names based on current user's role.
class TransactionModel {
  final String id;
  final String merchantName;
  final String category;
  final String amount;
  final double amountValue; // Numeric amount for calculations
  final String currency;
  final String time;
  final DateTime? timestamp; // For chart grouping
  final bool isDebit;
  final TransactionStatus status;
  final IconData categoryIcon;
  final Color categoryColor;
  final String? recipientNote;
  final String senderName;
  final String recipientName;
  final String senderUid;
  final String recipientUid;

  const TransactionModel({
    required this.id,
    required this.merchantName,
    required this.category,
    required this.amount,
    this.amountValue = 0.0,
    required this.currency,
    required this.time,
    this.timestamp,
    required this.isDebit,
    required this.status,
    required this.categoryIcon,
    required this.categoryColor,
    this.recipientNote,
    this.senderName = 'Unknown',
    this.recipientName = 'Unknown',
    this.senderUid = '',
    this.recipientUid = '',
  });

  /// Factory constructor that extracts data from a Firestore DocumentSnapshot.
  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final map = Map<String, dynamic>.from(data);
    if (!map.containsKey('id')) {
      map['id'] = doc.id;
    }
    return TransactionModel.fromMap(map);
  }

  /// Factory constructor that extracts data from a Firestore document map.
  /// Safely handles both snake_case and CamelCase field names.
  /// Dynamically resolves the display name based on current user's role:
  /// - If current user is sender, show recipient name
  /// - If current user is recipient, show sender name
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    // Get current user's UID
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Safely extract names and UIDs (handle both snake_case and CamelCase)
    final String senderName =
        (map['senderName'] ?? map['sender_name'] ?? 'Unknown').toString();
    final String recipientName =
        (map['recipientName'] ?? map['recipient_name'] ?? 'Unknown').toString();
    final String senderUid = (map['sender_uid'] ?? map['senderUid'] ?? '')
        .toString();
    final String recipientUid =
        (map['recipient_uid'] ?? map['recipientUid'] ?? '').toString();

    // Parse numeric amount for calculations
    final double numericAmount = _parseNumericAmount(map['amount']);

    // Determine dynamic display name based on current user's role
    // If user is sender, show recipient; if user is recipient, show sender
    final String resolvedMerchantName = (currentUid == senderUid)
        ? recipientName
        : senderName;

    // Extract timestamp if available
    DateTime? extractedTimestamp;
    final timestampField = map['timestamp'];
    if (timestampField is Timestamp) {
      extractedTimestamp = timestampField.toDate();
    } else if (timestampField is int) {
      extractedTimestamp = DateTime.fromMillisecondsSinceEpoch(timestampField);
    }

    return TransactionModel(
      id: (map['id'] as String?) ?? '',
      merchantName: resolvedMerchantName,
      category: (map['category'] as String?) ?? 'Transaction',
      amount: _safeParseAmount(map['amount']),
      amountValue: numericAmount,
      currency: (map['currency'] as String?) ?? 'IDR',
      time: (map['time'] as String?) ?? 'Just now',
      timestamp: extractedTimestamp,
      isDebit: (map['isDebit'] as bool?) ?? true,
      status: statusFromString(map['status'] as String?),
      categoryIcon: iconFromString(map['categoryIcon'] as String?),
      categoryColor: Color(
        (map['categoryColor'] as num?)?.toInt() ?? 0xFF3B82F6,
      ),
      recipientNote: map['recipientNote'] as String?,
      senderName: senderName,
      recipientName: recipientName,
      senderUid: senderUid,
      recipientUid: recipientUid,
    );
  }

  /// Convert model to JSON for caching
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'merchantName': merchantName,
      'category': category,
      'amount': amount,
      'currency': currency,
      'time': time,
      'isDebit': isDebit,
      'status': statusToString(status),
      'categoryIconCodePoint': categoryIcon.codePoint,
      'categoryColor': categoryColor.toARGB32(),
      'recipientNote': recipientNote,
    };
  }

  /// Create model from cached JSON
  static TransactionModel fromJson(Map<String, dynamic> json) {
    final iconCode = json['categoryIconCodePoint'] as int?;
    // Remove explicit IconData type to avoid non-const warning if linter is confused
    final IconData icon;
    if (iconCode != null) {
      // ignore: non_const_argument_for_const_parameter
      icon = IconData(iconCode);
    } else {
      icon = Icons.receipt_outlined;
    }

    // Get current user's UID
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Safely extract names and UIDs (handle both snake_case and CamelCase)
    final String senderName =
        (json['senderName'] ?? json['sender_name'] ?? 'Unknown').toString();
    final String recipientName =
        (json['recipientName'] ?? json['recipient_name'] ?? 'Unknown')
            .toString();
    final String senderUid = (json['sender_uid'] ?? json['senderUid'] ?? '')
        .toString();
    final String recipientUid =
        (json['recipient_uid'] ?? json['recipientUid'] ?? '').toString();

    // Determine dynamic display name based on current user's role
    final String resolvedMerchantName = (currentUid == senderUid)
        ? recipientName
        : senderName;

    return TransactionModel(
      id: (json['id'] as String?) ?? '',
      merchantName: resolvedMerchantName,
      category: (json['category'] as String?) ?? 'Transaction',
      amount: _safeParseAmount(json['amount']),
      currency: (json['currency'] as String?) ?? 'IDR',
      time: (json['time'] as String?) ?? 'Just now',
      isDebit: (json['isDebit'] as bool?) ?? true,
      status: statusFromString(json['status'] as String?),
      categoryIcon: icon,
      categoryColor: Color(
        (json['categoryColor'] as num?)?.toInt() ?? 0xFF3B82F6,
      ),
      recipientNote: json['recipientNote'] as String?,
      senderName: senderName,
      recipientName: recipientName,
      senderUid: senderUid,
      recipientUid: recipientUid,
    );
  }

  static TransactionStatus statusFromString(String? v) {
    switch (v) {
      case 'completed':
        return TransactionStatus.completed;
      case 'pending':
        return TransactionStatus.pending;
      case 'processing':
        return TransactionStatus.processing;
      case 'failed':
        return TransactionStatus.failed;
      case 'refunded':
        return TransactionStatus.refunded;
      default:
        return TransactionStatus.completed;
    }
  }

  static String statusToString(TransactionStatus s) {
    switch (s) {
      case TransactionStatus.completed:
        return 'completed';
      case TransactionStatus.pending:
        return 'pending';
      case TransactionStatus.processing:
        return 'processing';
      case TransactionStatus.failed:
        return 'failed';
      case TransactionStatus.refunded:
        return 'refunded';
    }
  }

  /// Safely parse amount from various types (String, int, double, num)
  static String _safeParseAmount(dynamic value) {
    if (value == null) return 'Rp 0';
    if (value is String) return value;
    if (value is num) {
      final amountVal = value.toDouble();
      return amountVal
          .toStringAsFixed(0)
          .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]}.',
          );
    }
    return 'Rp 0';
  }

  /// Parse numeric amount from various types for calculations
  static double _parseNumericAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      // Remove formatting (dots for thousands, currency symbols)
      final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  static IconData iconFromString(String? v) {
    switch (v) {
      case 'shopping_bag':
        return Icons.shopping_bag_outlined;
      case 'restaurant':
        return Icons.restaurant_outlined;
      case 'swap_horiz':
        return Icons.swap_horiz_rounded;
      case 'phone_android':
        return Icons.phone_android_outlined;
      case 'flight':
        return Icons.flight_outlined;
      default:
        return Icons.receipt_outlined;
    }
  }
}
