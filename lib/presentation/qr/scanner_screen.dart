import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/hive_cache_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _isProcessing = false;
  bool _isFetchingRecipient = false;
  Map<String, dynamic>? _recipientData;
  String? _recipientUid;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing || capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    if (barcode.rawValue == null) return;

    final scannedUid = barcode.rawValue!;

    // Validate it looks like a Firebase UID (28 chars alphanumeric)
    if (scannedUid.length < 10) return;

    setState(() {
      _isProcessing = true;
      _isFetchingRecipient = true;
    });

    // Stop scanner while processing
    await _controller.stop();

    try {
      // Fetch recipient data from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(scannedUid)
          .get();

      if (!doc.exists) {
        _showError('User tidak ditemukan');
        return;
      }

      final data = doc.data()!;
      final currentUid = FirebaseAuth.instance.currentUser?.uid;

      if (scannedUid == currentUid) {
        _showError('Tidak bisa transfer ke diri sendiri');
        return;
      }

      setState(() {
        _recipientData = data;
        _recipientUid = scannedUid;
        _isFetchingRecipient = false;
      });

      // Show amount input dialog
      _showAmountInputDialog();
    } catch (e) {
      _showError('Gagal mengambil data penerima: $e');
      setState(() {
        _isProcessing = false;
        _isFetchingRecipient = false;
      });
      await _controller.start();
    }
  }

  void _showAmountInputDialog() {
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text('Transfer ke ${_recipientData?['name'] ?? 'User'}',
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              Text('Masukkan nominal transfer',
                  style: GoogleFonts.inter(
                      fontSize: 14, color: AppTheme.textSecondary)),
              const SizedBox(height: 24),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: GoogleFonts.inter(
                    fontSize: 24, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  prefixStyle: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary),
                  hintText: '0',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppTheme.glassBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _resetScanner();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text('Batal',
                          style: GoogleFonts.inter(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final amount = double.tryParse(amountController.text.replaceAll('.', '').replaceAll(',', ''));
                        if (amount == null || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nominal tidak valid'), backgroundColor: Colors.red),
                          );
                          return;
                        }
                        Navigator.pop(ctx);
                        _processTransfer(amount);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text('Kirim',
                          style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processTransfer(double amount) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || _recipientUid == null) {
      _showError('User tidak terautentikasi');
      return;
    }

    setState(() => _isProcessing = true);

    // Show processing dialog with SpinKit
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
              const SpinKitFadingCircle(color: AppTheme.primary, size: 40),
              const SizedBox(height: 16),
              Text('Memproses transfer...',
                  style: GoogleFonts.inter(
                      fontSize: 14, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      ),
    );

    try {
      // ATOMIC WRITE BATCH - The "Real" Transfer
      final WriteBatch batch = FirebaseFirestore.instance.batch();

      // Action 1: Deduct from sender
      final senderRef = FirebaseFirestore.instance.collection('users').doc(currentUid);
      batch.update(senderRef, {'balance': FieldValue.increment(-amount)});

      // Action 2: Add to recipient
      final recipientRef = FirebaseFirestore.instance.collection('users').doc(_recipientUid!);
      batch.update(recipientRef, {'balance': FieldValue.increment(amount)});

      // Action 3: Create transaction log
      final trxRef = FirebaseFirestore.instance.collection('transactions').doc();
      batch.set(trxRef, {
        'senderUid': currentUid,
        'recipientUid': _recipientUid,
        'recipientName': _recipientData?['name'] ?? 'User',
        'senderName': FirebaseAuth.instance.currentUser?.displayName ?? 'User',
        'amount': amount,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'p2p_transfer',
        'status': 'success',
      });

      // Execute atomic batch
      await batch.commit();

      // Update Hive cache for instant UI refresh
      final currentBalance = (HiveCacheService.getCachedBalance()) ?? 0.0;
      await HiveCacheService.setCachedBalance(currentBalance - amount);

      if (mounted) Navigator.pop(context); // Close processing dialog

      // Show success
      final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Transfer ${formatter.format(amount)} ke ${_recipientData?['name']} berhasil!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      if (mounted) Navigator.pop(context); // Return to previous screen
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close processing dialog
      _showError('Transfer gagal: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _resetScanner() async {
    setState(() {
      _isProcessing = false;
      _isFetchingRecipient = false;
      _recipientData = null;
      _recipientUid = null;
    });
    await _controller.start();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ $message'), backgroundColor: Colors.red),
    );
    _resetScanner();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Scan QR',
            style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () async {
            await _controller.dispose();
            if (mounted) Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              _controller.torchEnabled ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            onPressed: () async {
              await _controller.toggleTorch();
              setState(() {});
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcode,
          ),
          // Scan overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primary, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Corner decorations
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppTheme.primary, width: 3),
                          left: BorderSide(color: AppTheme.primary, width: 3),
                        ),
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(20)),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppTheme.primary, width: 3),
                          right: BorderSide(color: AppTheme.primary, width: 3),
                        ),
                        borderRadius: BorderRadius.only(topRight: Radius.circular(20)),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppTheme.primary, width: 3),
                          left: BorderSide(color: AppTheme.primary, width: 3),
                        ),
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20)),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppTheme.primary, width: 3),
                          right: BorderSide(color: AppTheme.primary, width: 3),
                        ),
                        borderRadius: BorderRadius.only(bottomRight: Radius.circular(20)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Text(
              'Arahkan kamera ke QR Code',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  shadows: [const Shadow(color: Colors.black, blurRadius: 10)]),
            ),
          ),
          // Loading overlay
          if (_isFetchingRecipient)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SpinKitFadingCircle(color: AppTheme.primary, size: 50),
                    const SizedBox(height: 16),
                    Text('Mencari penerima...',
                        style: GoogleFonts.inter(
                            fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}