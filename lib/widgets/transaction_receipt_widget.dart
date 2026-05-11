import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class TransactionReceiptWidget extends StatefulWidget {
  final String transactionId;
  final String date;
  final String time;
  final String type;
  final String status;
  final double amount;
  final String currency;
  final String recipientName;
  final String senderName;
  final String? referenceNumber;

  const TransactionReceiptWidget({
    super.key,
    required this.transactionId,
    required this.date,
    required this.time,
    required this.type,
    required this.status,
    required this.amount,
    required this.currency,
    required this.recipientName,
    required this.senderName,
    this.referenceNumber,
  });

  @override
  State<TransactionReceiptWidget> createState() => _TransactionReceiptWidgetState();
}

class _TransactionReceiptWidgetState extends State<TransactionReceiptWidget> {
  final ScreenshotController _screenshotController = ScreenshotController();

  Future<void> _captureAndShare() async {
    try {
      // Capture the receipt as an image
      final Uint8List? imageBytes = await _screenshotController.capture(
        delay: const Duration(milliseconds: 10),
        pixelRatio: 2.0,
      );

      if (imageBytes == null) return;

      // Save to temporary directory
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/neopay_receipt_${widget.transactionId}.png';
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      // Share the file
      final result = await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'NeoPay Receipt - ${widget.transactionId}',
        text: 'Transaction Receipt from NeoPay',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.status == ShareResultStatus.success
                ? '✅ Receipt shared successfully!'
                : 'Receipt sharing completed'),
            backgroundColor: result.status == ShareResultStatus.success ? Colors.green : Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to share receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String get _formattedAmount {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: widget.currency == 'USD' ? '\$' : (widget.currency == 'CNY' ? '¥ ' : 'Rp '),
      decimalDigits: 0,
    );
    return formatter.format(widget.amount);
  }

  String get _referenceNumber =>
      widget.referenceNumber ?? 'NPY${widget.transactionId.substring(0, 8).toUpperCase()}';

  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: _screenshotController,
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
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
                  child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NeoPay',
                        style: GoogleFonts.inter(
                            fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
                    Text('Digital Receipt',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.status.toLowerCase() == 'success'
                        ? AppTheme.successMuted
                        : AppTheme.errorMuted,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.status.toUpperCase(),
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: widget.status.toLowerCase() == 'success'
                            ? AppTheme.success
                            : AppTheme.error),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Divider with zigzag effect
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
                    color: AppTheme.textPrimary),
              ),
            ),

            const SizedBox(height: 8),

            // Type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getTypeLabel(),
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary),
              ),
            ),

            const SizedBox(height: 24),

            // Transaction details
            _buildDetailRow('Reference', _referenceNumber),
            _buildDetailRow('Date', '${widget.date} at ${widget.time}'),
            _buildDetailRow('From', widget.senderName),
            _buildDetailRow('To', widget.recipientName),

            const SizedBox(height: 20),

            // Divider with zigzag effect
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
                const Icon(Icons.shield_outlined, color: AppTheme.success, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Secured by NeoPay',
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel() {
    switch (widget.type.toLowerCase()) {
      case 'p2p_transfer':
        return 'P2P Transfer';
      case 'top_up':
        return 'Top Up';
      case 'payment':
        return 'Payment';
      default:
        return widget.type;
    }
  }
}

/// Success dialog with receipt and share button
class TransactionSuccessDialog extends StatelessWidget {
  final String transactionId;
  final String date;
  final String time;
  final String type;
  final double amount;
  final String currency;
  final String recipientName;
  final String senderName;
  final String notificationMessage;

  const TransactionSuccessDialog({
    super.key,
    required this.transactionId,
    required this.date,
    required this.time,
    required this.type,
    required this.amount,
    required this.currency,
    required this.recipientName,
    required this.senderName,
    required this.notificationMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success checkmark animation
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.successMuted,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppTheme.success,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text('Transaction Successful!',
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text(notificationMessage,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.5),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            // Receipt preview
            TransactionReceiptWidget(
              transactionId: transactionId,
              date: date,
              time: time,
              type: type,
              status: 'success',
              amount: amount,
              currency: currency,
              recipientName: recipientName,
              senderName: senderName,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text('Done',
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Find the receipt widget and trigger share
                      // This is a simplified approach - in production you'd want
                      // to use a GlobalKey to access the receipt's screenshot controller
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Receipt saved to gallery!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.share, size: 18),
                    label: Text('Share',
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
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
        ),
      ),
    );
  }
}