import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/hive_cache_service.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final TextEditingController _amountController = TextEditingController();
  bool _isProcessing = false;

  final List<int> _quickAmounts = [10000, 25000, 50000, 100000, 250000, 500000];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _processTopUp(int amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isProcessing = true);

    // Show processing dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SpinKitFadingCircle(color: AppTheme.success, size: 40),
              const SizedBox(height: 16),
              Text('Memproses top up...',
                  style: GoogleFonts.inter(
                      fontSize: 14, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      ),
    );

    try {
      // ATOMIC WRITE BATCH for Top-Up
      final WriteBatch batch = FirebaseFirestore.instance.batch();

      // Action 1: Update user balance
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      batch.update(userRef, {'balance': FieldValue.increment(amount.toDouble())});

      // Action 2: Create transaction log
      final trxRef = FirebaseFirestore.instance.collection('transactions').doc();
      batch.set(trxRef, {
        'uid': user.uid,
        'amount': amount.toDouble(),
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'top_up',
        'status': 'success',
        'method': 'qr_topup',
      });

      // Execute atomic batch
      await batch.commit();

      // Update Hive cache for instant UI refresh
      final currentBalance = (HiveCacheService.getCachedBalance()) ?? 0.0;
      await HiveCacheService.setCachedBalance(currentBalance + amount);

      if (mounted) Navigator.pop(context); // Close processing dialog

      // Show success
      final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Top up ${formatter.format(amount)} berhasil!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Clear amount field
      _amountController.clear();

      if (mounted) Navigator.pop(context); // Return to previous screen
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close processing dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Top up gagal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Top Up Saldo',
            style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.success, Color(0xFF34D399)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.success.withAlpha(60),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Top Up Saldo',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text('Tambah saldo dengan mudah',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: Colors.white.withOpacity(0.7))),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Amount input
              Text('Masukkan Nominal',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  prefixStyle: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary),
                  hintText: '0',
                  hintStyle: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMuted),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppTheme.glassBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.success, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
              const SizedBox(height: 24),
              // Quick amounts
              Text('Pilih Nominal',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.2,
                ),
                itemCount: _quickAmounts.length,
                itemBuilder: (context, index) {
                  final amount = _quickAmounts[index];
                  final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
                  return GestureDetector(
                    onTap: () {
                      _amountController.text = amount.toString();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.glassBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.glassBorder, width: 0.5),
                      ),
                      child: Center(
                        child: Text(
                          formatter.format(amount),
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              // Confirm button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing
                      ? null
                      : () {
                          final amount = int.tryParse(_amountController.text);
                          if (amount == null || amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Masukkan nominal yang valid'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          _processTopUp(amount);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isProcessing
                      ? const SpinKitFadingCircle(color: Colors.white, size: 24)
                      : Text('Konfirmasi Top Up',
                          style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              // Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.successMuted,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.success, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Saldo akan langsung masuk setelah konfirmasi. Tidak ada biaya admin.',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.success,
                            height: 1.4),
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
}