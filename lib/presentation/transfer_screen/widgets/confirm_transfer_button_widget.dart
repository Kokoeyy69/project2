// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import '../../../services/api_service.dart';
import '../../../core/services/security_service.dart';
import '../../security/create_pin_screen.dart';
import '../../security/verify_pin_screen.dart';

class ConfirmTransferButtonWidget extends StatefulWidget {
  final double amount;
  final String recipientId;
  final String recipientName;
  final int walletIndex;

  const ConfirmTransferButtonWidget({
    super.key,
    required this.amount,
    required this.recipientId,
    required this.recipientName,
    required this.walletIndex,
  });

  @override
  State<ConfirmTransferButtonWidget> createState() => _ConfirmTransferButtonWidgetState();
}

/// Fee configs matching TransferFeeBreakdownWidget
class _TransferFeeConfig {
  final double feeRate;
  final double minFee;
  final double maxFee;

  const _TransferFeeConfig({
    required this.feeRate,
    required this.minFee,
    required this.maxFee,
  });
}

const List<_TransferFeeConfig> _feeConfigs = [
  _TransferFeeConfig(feeRate: 0.005, minFee: 2500, maxFee: 25000), // IDR
  _TransferFeeConfig(feeRate: 0.008, minFee: 0.5, maxFee: 15), // USD
  _TransferFeeConfig(feeRate: 0.006, minFee: 3, maxFee: 80), // CNY
];

const List<String> _currencies = ['IDR', 'USD', 'CNY'];
const List<String> _symbols = ['Rp', r'$', '¥'];
const List<String> _balanceFields = ['balance', 'balance_usd', 'balance_cny'];

class _ConfirmTransferButtonWidgetState extends State<ConfirmTransferButtonWidget>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _pinVerified = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  bool get _canSubmit => widget.amount > 0 && widget.recipientId.isNotEmpty;

  double get _calculatedFee {
    final config = _feeConfigs[widget.walletIndex];
    return (widget.amount * config.feeRate).clamp(config.minFee, config.maxFee);
  }

  String get _currency => _currencies[widget.walletIndex];
  String get _symbol => _symbols[widget.walletIndex];
  String get _balanceField => _balanceFields[widget.walletIndex];

  Future<void> _confirm() async {
    if (!_canSubmit) {
      _showValidationSheet();
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && widget.recipientId == currentUser.uid) {
      _showSelfTransferError();
      return;
    }

    // PIN verification gate - must pass before any Firestore or API call
    final pinVerified = await _verifyPinGate();
    if (!pinVerified) return;

    // Pre-check balance (read-only) before showing confirmation dialog
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (!userDoc.exists) {
        _showBalanceCheckError('User profile not found.');
        return;
      }

      final senderBalance = (userDoc.data()?[_balanceField] as num?)?.toDouble() ?? 0.0;
      final fee = _calculatedFee;
      final totalDebit = widget.amount + fee;

      if (senderBalance < totalDebit) {
        _showInsufficientBalanceSheet(senderBalance, totalDebit, fee);
        return;
      }
    } catch (e) {
      debugPrint('Balance pre-check error: $e');
    }

    _showConfirmationDialog();
  }

  Future<bool> _verifyPinGate() async {
    final securityService = SecurityService();
    final hasPin = await securityService.hasTransactionPin();

    if (!hasPin) {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => const CreatePinScreen()),
      );

      if (result != true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'PIN harus diatur untuk melakukan transfer',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              backgroundColor: AppTheme.warning,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return false;
      }
    } else {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => const VerifyPinScreen(
            title: 'Verifikasi PIN Transaksi',
          ),
        ),
      );

      if (result != true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Verifikasi PIN gagal',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return false;
      }
    }

    _pinVerified = true;
    return true;
  }

  void _showInsufficientBalanceSheet(double senderBalance, double totalDebit, double fee) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.glassBorder, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.error, size: 40),
            const SizedBox(height: 12),
            Text('Insufficient Balance', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text(
              'Your $_currency balance ($_symbol${senderBalance.toStringAsFixed(0)}) is not enough to cover the transfer amount of $_symbol${widget.amount.toStringAsFixed(0)} plus a fee of $_symbol${fee.toStringAsFixed(0)}.',
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Got it'))),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showBalanceCheckError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: GoogleFonts.inter(color: Colors.white)), backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating),
    );
  }

  void _showSelfTransferError() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.glassBorder, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Icon(Icons.swap_horiz_rounded, color: AppTheme.warning, size: 40),
          const SizedBox(height: 12),
          Text('Cannot Transfer to Yourself', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text('Please select a different recipient to transfer to.', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary, height: 1.5), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Got it'))),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _showValidationSheet() {
    final isAmountZero = widget.amount <= 0;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.glassBorder, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Icon(isAmountZero ? Icons.money_off_rounded : Icons.info_outline_rounded, color: AppTheme.warning, size: 40),
          const SizedBox(height: 12),
          Text(isAmountZero ? 'Invalid Amount' : 'Complete Transfer Details', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text(
            isAmountZero
                ? 'Transfer amount cannot be Rp0. Please enter a valid amount.'
                : (widget.recipientId.isEmpty ? 'Please select a recipient before continuing.' : 'Please enter a transfer amount before continuing.'),
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Got it'))),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _showConfirmationDialog() {
    final currency = _currency;
    final symbol = _symbol;
    final fee = _calculatedFee;
    final totalDebit = widget.amount + fee;

    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(179),
      builder: (context) => Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 56, height: 56, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.accent]), borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.lock_rounded, color: Colors.white, size: 26)),
            const SizedBox(height: 16),
            Text('Confirm Transfer', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text('You are about to send\n$symbol ${widget.amount.toStringAsFixed(2)} $currency', style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary, height: 1.5), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.surfaceVariant, borderRadius: BorderRadius.circular(12)), child: Column(children: [
              _buildFeeRow('Transfer Fee', '$symbol ${_fmtAmount(fee)}'),
              const SizedBox(height: 6),
              Container(height: 0.5, color: AppTheme.separator),
              const SizedBox(height: 6),
              _buildFeeRow('Total Debit', '$symbol ${_fmtAmount(totalDebit)}', bold: true),
            ])),
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.warningMuted, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.warning.withAlpha(77), width: 0.5)), child: Row(children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('This action cannot be undone once confirmed.', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.warning, fontWeight: FontWeight.w500))),
            ])),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(foregroundColor: AppTheme.textSecondary, side: const BorderSide(color: AppTheme.glassBorder, width: 0.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 14)), child: Text('Cancel', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: () async {
                Navigator.pop(context);

                // Extra safety: ensure PIN verified before making API call
                if (!_pinVerified) {
                  final ok = await _verifyPinGate();
                  if (!ok) return;
                }

                setState(() => _isLoading = true);

                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    final transferReq = TransferRequest(
                      senderUid: user.uid,
                      recipientUid: widget.recipientId,
                      amount: widget.amount,
                      recipientName: widget.recipientName,
                      senderName: user.displayName ?? 'User',
                    );

                    final res = await ApiService.instance.processTransfer(transferReq);
                    if (!res.success) {
                      final errorMsg = res.error ?? res.message ?? 'Transfer failed. Please try again.';
                      if (!mounted) return;
                      setState(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)), backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating));
                      return;
                    }
                  }
                } catch (e) {
                  debugPrint('Transfer failed: $e');
                  if (!mounted) return;
                  setState(() => _isLoading = false);
                  String errorMsg = 'Transfer failed. Please try again.';
                  if (e.toString().contains('Insufficient_Balance')) {
                    errorMsg = 'Insufficient balance to cover amount + fee.';
                  }
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)), backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating));
                  return;
                }

                if (!mounted) return;
                setState(() => _isLoading = false);

                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.transferSuccessScreen, (_) => false, arguments: {
                  'recipientName': widget.recipientName,
                  'amountSent': widget.amount.toStringAsFixed(2),
                  'sourceCurrency': currency,
                  'exchangeRate': '1.00',
                  'amountReceived': widget.amount.toStringAsFixed(2),
                  'targetCurrency': currency,
                });

              }, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 14)), child: Text('Confirm', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white))))
            ])
          ]),
        ),
      ),
    );
  }

  Widget _buildFeeRow(String label, String value, {bool bold = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary, fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
      Text(value, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary, fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
    ]);
  }

  String _fmtAmount(double value) {
    if (_currency == 'IDR') {
      if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(2)} Jt';
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        _confirm();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(scale: _scaleAnimation.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          decoration: BoxDecoration(
            gradient: _canSubmit ? const LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [AppTheme.primary, AppTheme.accent]) : null,
            color: _canSubmit ? null : AppTheme.glassBackground,
            borderRadius: BorderRadius.circular(18),
            boxShadow: _canSubmit ? [BoxShadow(color: AppTheme.primary.withAlpha(89), blurRadius: 20, offset: const Offset(0, 6))] : null,
            border: _canSubmit ? null : Border.all(color: AppTheme.glassBorder, width: 0.5),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (!_isLoading) ...[
              Icon(Icons.lock_rounded, size: 18, color: _canSubmit ? Colors.white : AppTheme.textMuted),
              const SizedBox(width: 10),
            ],
            AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: _isLoading ? const SizedBox(key: ValueKey('loading'), width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white))) : Text(key: const ValueKey('label'), _canSubmit ? 'Confirm & Send' : 'Select recipient & enter amount', style: GoogleFonts.inter(fontSize: _canSubmit ? 15 : 13, fontWeight: FontWeight.w600, color: _canSubmit ? Colors.white : AppTheme.textMuted))),
          ]),
        ),
      ),
    );
  }
}
