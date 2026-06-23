import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../models/transaction_model.dart';

/// A shareable receipt widget that can capture itself as an image and share it.
/// Uses RepaintBoundary and RenderRepaintBoundary.toImage() for capture.
class ShareableReceiptWidget extends StatefulWidget {
  final String? transactionId;
  final String? date;
  final String? time;
  final String? type;
  final String? status;
  final double? amount;
  final String? currency;
  final String? recipientName;
  final String? senderName;
  final String? referenceNumber;
  final TransactionModel? transaction;

  const ShareableReceiptWidget({
    super.key,
    this.transactionId,
    this.date,
    this.time,
    this.type,
    this.status,
    this.amount,
    this.currency,
    this.recipientName,
    this.senderName,
    this.referenceNumber,
    this.transaction,
  });

  @override
  State<ShareableReceiptWidget> createState() => _ShareableReceiptWidgetState();
}

class _ShareableReceiptWidgetState extends State<ShareableReceiptWidget> {
  final GlobalKey _receiptKey = GlobalKey();
  bool _isCapturing = false;

  String get _transactionId =>
      widget.transaction?.id ?? widget.transactionId ?? '';
  String get _date => widget.transaction != null
      ? (widget.transaction!.timestamp != null
            ? DateFormat('yyyy-MM-dd').format(widget.transaction!.timestamp!)
            : widget.transaction!.time)
      : (widget.date ?? '');
  String get _statusStr => widget.transaction != null
      ? TransactionModel.statusToString(widget.transaction!.status)
      : (widget.status ?? 'Success');
  double get _amount => widget.transaction != null
      ? widget.transaction!.amountValue
      : (widget.amount ?? 0.0);
  String get _currency =>
      widget.transaction?.currency ?? widget.currency ?? 'IDR';
  String get _recipientName =>
      widget.transaction?.recipientName ?? widget.recipientName ?? 'Unknown';
  String get _senderName =>
      widget.transaction?.senderName ?? widget.senderName ?? 'Unknown';

  String get _formattedAmount {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: _currency == 'USD' ? '\$' : (_currency == 'CNY' ? '¥ ' : 'Rp '),
      decimalDigits: 0,
    );
    return formatter.format(_amount);
  }

  /// Captures the receipt as a PNG image and shares it
  Future<void> _captureAndSharePng() async {
    if (_isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      // Find the RenderRepaintBoundary
      final boundary =
          _receiptKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        _showError('Unable to capture receipt');
        return;
      }

      // Capture at 3x pixel ratio for high quality
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes == null) {
        _showError('Failed to capture image');
        return;
      }

      // Save to temporary directory
      final tempDir = await getTemporaryDirectory();
      final file = await File(
        '${tempDir.path}/neopay_receipt_$_transactionId.png',
      ).writeAsBytes(pngBytes);

      // Share the file
      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'NeoPay Receipt - $_transactionId');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt shared successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error capturing receipt: $e');
      if (mounted) {
        _showError('Failed to share receipt');
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Receipt UI wrapped in RepaintBoundary
        RepaintBoundary(
          key: _receiptKey,
          child: Container(
            width: 340,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.glassBorder, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(80),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with logo
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.accent],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NeoPay',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Digital Receipt',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _statusStr.toLowerCase() == 'success'
                            ? AppTheme.successMuted
                            : AppTheme.errorMuted,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusStr.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _statusStr.toLowerCase() == 'success'
                              ? AppTheme.success
                              : AppTheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Divider
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppTheme.separator,
                        width: 1,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Amount
                Center(
                  child: Text(
                    _formattedAmount,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getTypeLabel(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Details Card container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.glassBorder, width: 0.5),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        'Reference ID',
                        widget.transactionId ??
                            widget.transaction?.id ??
                            _transactionId,
                      ),
                      _buildDetailRow(
                        'Sender',
                        widget.senderName ?? _senderName,
                      ),
                      _buildDetailRow(
                        'Recipient',
                        widget.recipientName ?? _recipientName,
                      ),
                      _buildDetailRow(
                        'Date',
                        _date.isNotEmpty ? _date : 'Today',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Divider
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppTheme.separator,
                        width: 1,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Footer
                Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: AppTheme.success,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Secured by NeoPay',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Action buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isCapturing ? null : _captureAndSharePng,
                icon: _isCapturing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.share, size: 18),
                label: Text(_isCapturing ? '...' : 'Share'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isCapturing ? null : _saveToGallery,
                icon: _isCapturing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download, size: 18),
                label: Text(_isCapturing ? '...' : 'Download'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _saveToGallery() async {
    try {
      RenderRepaintBoundary boundary =
          _receiptKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      await Gal.requestAccess();
      await Gal.putImageBytes(
        pngBytes,
        name: 'NeoPay_Receipt_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt Saved to Gallery!')),
        );
      }
    } catch (e) {
      debugPrint("Save error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel() {
    switch ((widget.type ?? '').toLowerCase()) {
      case 'p2p_transfer':
        return 'P2P Transfer';
      case 'top_up':
        return 'Top Up';
      case 'payment':
        return 'Payment';
      default:
        return widget.type ?? 'Unknown';
    }
  }
}
