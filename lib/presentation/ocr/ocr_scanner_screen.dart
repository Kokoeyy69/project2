import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../core/services/ocr_service.dart';
import './ocr_view_model.dart';

class OcrScannerScreen extends StatelessWidget {
  const OcrScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OCRViewModel(),
      child: const _OcrScannerScreenContent(),
    );
  }
}

class _OcrScannerScreenContent extends StatelessWidget {
  const _OcrScannerScreenContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<OCRViewModel>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textSecondary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Receipt Scanner',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (viewModel.imageFile == null) ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppTheme.primaryMuted,
                              AppTheme.accentMuted,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(
                          Icons.document_scanner_rounded,
                          size: 48,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Scan Receipt',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Capture a receipt to extract merchant, amount, and date automatically.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  viewModel.imageFile!,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              if (viewModel.isProcessing)
                const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                )
              else if (viewModel.receiptData != null)
                _buildResultCard(viewModel.receiptData!)
              else
                Text(
                  'No data extracted',
                  style: GoogleFonts.inter(color: AppTheme.textMuted),
                ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: viewModel.captureReceipt,
                icon: Icon(
                  viewModel.imageFile == null
                      ? Icons.camera_alt_rounded
                      : Icons.refresh_rounded,
                  color: Colors.white,
                ),
                label: Text(
                  viewModel.imageFile == null
                      ? 'Capture Receipt'
                      : 'Scan Another',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            if (viewModel.receiptData != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context, viewModel.receiptData);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.success,
                    side: const BorderSide(color: AppTheme.success),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Add to Transactions',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(ReceiptData data) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface.withAlpha(204),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Extracted Data',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildRow('Merchant', data.merchantName),
              const SizedBox(height: 8),
              _buildRow('Amount', 'IDR ${data.totalAmount.toStringAsFixed(2)}'),
              if (data.date != null) ...[
                const SizedBox(height: 8),
                _buildRow(
                  'Date',
                  '${data.date!.day}/${data.date!.month}/${data.date!.year}',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
