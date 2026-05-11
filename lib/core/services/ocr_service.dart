import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class ReceiptData {
  final String merchantName;
  final double totalAmount;
  final DateTime? date;
  final String rawText;

  const ReceiptData({
    required this.merchantName,
    required this.totalAmount,
    this.date,
    required this.rawText,
  });
}

class OcrService {
  static final OcrService _instance = OcrService._internal();
  factory OcrService() => _instance;
  OcrService._internal();

  static OcrService get instance => _instance;

  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<File?> pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  Future<ReceiptData?> scanReceipt(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final rawText = recognizedText.text;

      final merchantName = _extractMerchantName(recognizedText);
      final totalAmount = _extractTotalAmount(recognizedText);
      final date = _extractDate(rawText);

      return ReceiptData(
        merchantName: merchantName,
        totalAmount: totalAmount,
        date: date,
        rawText: rawText,
      );
    } catch (e) {
      debugPrint('[OcrService] Error scanning receipt: $e');
      return null;
    }
  }

  String _extractMerchantName(RecognizedText recognizedText) {
    for (final block in recognizedText.blocks) {
      final text = block.text.trim();
      if (text.length > 2 && text.length < 40 && !RegExp(r'[0-9]{2,}').hasMatch(text)) {
        if (!text.toLowerCase().contains('total') &&
            !text.toLowerCase().contains('tax') &&
            !text.toLowerCase().contains('subtotal') &&
            !text.toLowerCase().contains('amount')) {
          return text;
        }
      }
    }
    return 'Unknown Merchant';
  }

  double _extractTotalAmount(RecognizedText recognizedText) {
    double maxAmount = 0.0;
    for (final block in recognizedText.blocks) {
      final text = block.text;
      final matches = RegExp(r'[\d,]+\.\d{2}').allMatches(text);
      for (final match in matches) {
        final amountStr = match.group(0)?.replaceAll(',', '') ?? '0';
        final amount = double.tryParse(amountStr) ?? 0.0;
        if (amount > maxAmount) maxAmount = amount;
      }
    }
    return maxAmount;
  }

  DateTime? _extractDate(String text) {
    final patterns = [
      RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{2,4})'),
      RegExp(r'(\d{4})[/\-](\d{1,2})[/\-](\d{1,2})'),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          final parts = match.group(0)!.split(RegExp(r'[/\-]'));
          if (parts.length == 3) {
            if (parts[0].length == 4) {
              return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
            } else {
              final year = int.parse(parts[2].length == 2 ? '20${parts[2]}' : parts[2]);
              return DateTime(year, int.parse(parts[0]), int.parse(parts[1]));
            }
          }
        } catch (_) {}
      }
    }
    return null;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
