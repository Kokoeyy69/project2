import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../routes/app_routes.dart';

class ConfirmTransferButtonWidget extends StatefulWidget {
  final double amount;
  final String recipientId;
  final int walletIndex;

  const ConfirmTransferButtonWidget({
    super.key,
    required this.amount,
    required this.recipientId,
    required this.walletIndex,
  });

  @override
  State<ConfirmTransferButtonWidget> createState() =>
      _ConfirmTransferButtonWidgetState();
}

class _ConfirmTransferButtonWidgetState
    extends State<ConfirmTransferButtonWidget>
    with SingleTickerProviderStateMixin {
  // TODO: Replace with Riverpod/Bloc for production
  bool _isLoading = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  bool get _canSubmit => widget.amount > 0 && widget.recipientId.isNotEmpty;

  Future<void> _confirm() async {
    if (!_canSubmit) {
      _showValidationSheet();
      return;
    }

    _showConfirmationDialog();
  }

  void _showValidationSheet() {
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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(
              Icons.info_outline_rounded,
              color: AppTheme.warning,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'Complete Transfer Details',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.recipientId.isEmpty
                  ? 'Please select a recipient before continuing.'
                  : 'Please enter a transfer amount before continuing.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showConfirmationDialog() {
    final currencies = ['IDR', 'USD', 'CNY'];
    final symbols = ['Rp', '\$', '¥'];
    final currency = currencies[widget.walletIndex];
    final symbol = symbols[widget.walletIndex];

    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(179),
      builder: (context) => Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.accent],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Confirm Transfer',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You are about to send\n$symbol ${widget.amount.toStringAsFixed(2)} $currency',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningMuted,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.warning.withAlpha(77),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppTheme.warning,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This action cannot be undone once confirmed.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.warning,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
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
                        'Cancel',
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
                      onPressed: () async {
                        Navigator.pop(context);
                        setState(() => _isLoading = true);
                        
                        // --- KODE FIREBASE UNTUK TRANSFER ASLI ---
                        // --- KODE FIREBASE UNTUK TRANSFER ASLI & POTONG SALDO ---
                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            final db = FirebaseFirestore.instance;
                            // Referensi ke dokumen user dan dokumen transaksi baru
                            final userRef = db.collection('users').doc(user.uid);
                            final newTxRef = db.collection('transactions').doc(); 

                            // Jalankan Firestore Transaction (All-or-Nothing)
                            await db.runTransaction((transaction) async {
                              // 1. Baca data user saat ini
                              final userSnapshot = await transaction.get(userRef);
                              if (!userSnapshot.exists) {
                                throw Exception("User_Not_Found");
                              }

                              final currentBalance = (userSnapshot.data()?['balance'] as num?)?.toDouble() ?? 0.0;

                              // 2. Validasi: Saldo cukup nggak?
                              if (currentBalance < widget.amount) {
                                throw Exception("Insufficient_Balance");
                              }

                              // 3. Potong saldo utama di tabel users
                              transaction.update(userRef, {
                                'balance': currentBalance - widget.amount,
                              });

                              // 4. Catat riwayat di tabel transactions
                              transaction.set(newTxRef, {
                                'userId': user.uid,
                                'recipientName': widget.recipientId, 
                                'amount': widget.amount,
                                'currency': currency,
                                'type': 'transfer_out',
                                'status': 'completed',
                                'timestamp': FieldValue.serverTimestamp(),
                              });
                            });
                          }
                        } catch (e) {
                          debugPrint("Gagal transfer: $e");
                          if (!mounted) return;
                          
                          // Matikan loading animasi muter-muter
                          setState(() => _isLoading = false);
                          
                          // Munculkan notifikasi error ke user pakai SnackBar
                          String errorMsg = 'Transfer failed. Please try again.';
                          if (e.toString().contains('Insufficient_Balance')) {
                            errorMsg = 'Saldo kamu tidak cukup, Bos!';
                          }
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                errorMsg,
                                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                              backgroundColor: AppTheme.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return; // STOP! Jangan pindah ke halaman Home kalau gagal
                        }
                        // -----------------------------------------
                        // -----------------------------------------

                        if (!mounted) return;
                        setState(() => _isLoading = false);
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.homeScreen,
                          (_) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Confirm',
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // KITA UBAH BIAR SELALU BISA DIKLIK (Nggak pakai ngecek _canSubmit lagi di sini)
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        _confirm(); // Fungsi _confirm nanti yang nentuin lanjut atau nolak
      },
      onTapCancel: () => _scaleController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          decoration: BoxDecoration(
            gradient: _canSubmit
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [AppTheme.primary, AppTheme.accent],
                  )
                : null,
            color: _canSubmit ? null : AppTheme.glassBackground,
            borderRadius: BorderRadius.circular(18),
            boxShadow: _canSubmit
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withAlpha(89),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
            border: _canSubmit
                ? null
                : Border.all(color: AppTheme.glassBorder, width: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isLoading) ...[
                Icon(
                  Icons.lock_rounded,
                  size: 18,
                  color: _canSubmit ? Colors.white : AppTheme.textMuted,
                ),
                const SizedBox(width: 10),
              ],
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isLoading
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        key: const ValueKey('label'),
                        _canSubmit
                            ? 'Confirm & Send'
                            : 'Select recipient & enter amount',
                        style: GoogleFonts.inter(
                          fontSize: _canSubmit ? 15 : 13,
                          fontWeight: FontWeight.w600,
                          color: _canSubmit ? Colors.white : AppTheme.textMuted,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

