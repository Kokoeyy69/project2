import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/services/ocr_service.dart';

class OCRViewModel extends ChangeNotifier {
  final OcrService _ocrService = OcrService.instance;

  File? _imageFile;
  File? get imageFile => _imageFile;

  ReceiptData? _receiptData;
  ReceiptData? get receiptData => _receiptData;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  Future<void> captureReceipt() async {
    final file = await _ocrService.pickImage();
    if (file == null) return;

    _imageFile = file;
    _receiptData = null;
    _isProcessing = true;
    notifyListeners();

    final data = await _ocrService.scanReceipt(file);

    _receiptData = data;
    _isProcessing = false;
    notifyListeners();
  }

  void reset() {
    _imageFile = null;
    _receiptData = null;
    _isProcessing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }
}
