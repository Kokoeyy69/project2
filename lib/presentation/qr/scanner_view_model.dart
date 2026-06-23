import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/hive_cache_service.dart';

class ScannerViewModel extends ChangeNotifier {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _isProcessing = false;
  bool _isFetchingRecipient = false;
  Map<String, dynamic>? _recipientData;
  String? _recipientUid;
  String? _errorMessage;
  bool _isFlashOn = false;

  // Getters
  bool get isProcessing => _isProcessing;
  bool get isFetchingRecipient => _isFetchingRecipient;
  Map<String, dynamic>? get recipientData => _recipientData;
  String? get recipientUid => _recipientUid;
  String? get errorMessage => _errorMessage;
  bool get isFlashOn => _isFlashOn;

  Future<void> handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing || capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    if (barcode.rawValue == null) return;

    final scannedUid = barcode.rawValue!;
    if (scannedUid.length < 10) return;

    _isProcessing = true;
    _isFetchingRecipient = true;
    _errorMessage = null;
    notifyListeners();

    await controller.stop();

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(scannedUid)
          .get();

      if (!doc.exists) {
        _setError('User tidak ditemukan');
        return;
      }

      final data = doc.data()!;
      final currentUid = FirebaseAuth.instance.currentUser?.uid;

      if (scannedUid == currentUid) {
        _setError('Tidak bisa transfer ke diri sendiri');
        return;
      }

      _recipientData = data;
      _recipientUid = scannedUid;
      _isFetchingRecipient = false;
      notifyListeners();
    } catch (e) {
      _setError('Gagal mengambil data penerima: $e');
    }
  }

  void _setError(String message) {
    _errorMessage = message;
    _isProcessing = false;
    _isFetchingRecipient = false;
    notifyListeners();
  }

  Future<void> toggleFlash() async {
    await controller.toggleTorch();
    _isFlashOn = controller.torchEnabled;
    notifyListeners();
  }

  Future<void> resetScanner() async {
    _isProcessing = false;
    _isFetchingRecipient = false;
    _recipientData = null;
    _recipientUid = null;
    _errorMessage = null;
    notifyListeners();
    await controller.start();
  }

  Future<bool> processTransfer(double amount) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || _recipientUid == null) {
      _setError('User tidak terautentikasi');
      return false;
    }

    _isProcessing = true;
    notifyListeners();

    try {
      // ATOMIC WRITE BATCH – prevents race conditions and data corruption
      final WriteBatch batch = FirebaseFirestore.instance.batch();

      // 1) Decrement sender balance
      final senderRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid);
      batch.update(senderRef, {'balance': FieldValue.increment(-amount)});

      // 2) Increment recipient balance
      final recipientRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_recipientUid!);
      batch.update(recipientRef, {'balance': FieldValue.increment(amount)});

      // 3) Create transaction history log
      final trxRef = FirebaseFirestore.instance
          .collection('transactions')
          .doc();
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

      // 4) Commit atomic batch
      await batch.commit();

      // Update Hive cache for instant UI refresh
      final currentBalance = (HiveCacheService.getCachedBalance()) ?? 0.0;
      await HiveCacheService.setCachedBalance(currentBalance - amount);

      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Transfer gagal: $e');
      return false;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
