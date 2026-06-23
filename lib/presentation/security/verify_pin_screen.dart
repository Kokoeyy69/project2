import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../transfer_screen/widgets/numeric_keypad_widget.dart';
import './security_view_model.dart';

class VerifyPinScreen extends StatelessWidget {
  final String title;

  const VerifyPinScreen({super.key, this.title = 'Masukkan PIN Transaksi'});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SecurityViewModel(),
      child: _VerifyPinScreenContent(title: title),
    );
  }
}

class _VerifyPinScreenContent extends StatefulWidget {
  final String title;

  const _VerifyPinScreenContent({required this.title});

  @override
  State<_VerifyPinScreenContent> createState() =>
      _VerifyPinScreenContentState();
}

class _VerifyPinScreenContentState extends State<_VerifyPinScreenContent> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<SecurityViewModel>(context);

    Future<void> handlePinEntry(String digit) async {
      if (_isProcessing) return;

      if (viewModel.pin.length < 6) {
        viewModel.appendDigit(digit);
        if (viewModel.pin.length == 6) {
          setState(() => _isProcessing = true);
          try {
            final success = await viewModel.verifyPin(viewModel.pin);
            if (success && context.mounted) {
              if (Navigator.canPop(context)) {
                Navigator.pop(context, true);
              } else {
                Navigator.pushReplacementNamed(context, AppRoutes.homeScreen);
              }
            } else if (context.mounted) {
              viewModel.clearPin();
            }
          } finally {
            if (mounted) setState(() => _isProcessing = false);
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              widget.title,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Masukkan 6 digit PIN transaksi Anda',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 48),
            _buildPinDots(viewModel.pin),
            const Spacer(),
            if (viewModel.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  viewModel.errorMessage!,
                  style: GoogleFonts.inter(
                    color: AppTheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (viewModel.isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: CircularProgressIndicator(),
              ),
            NumericKeypadWidget(
              displayAmount: '',
              onKeyTap: handlePinEntry,
              onBackspace: () => viewModel.removeLastDigit(),
              onClear: () => viewModel.clearPin(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPinDots(String currentPin) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        bool isFilled = index < currentPin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 12),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? AppTheme.primary : Colors.transparent,
            border: Border.all(
              color: isFilled ? AppTheme.primary : AppTheme.textMuted,
              width: 2,
            ),
          ),
        );
      }),
    );
  }
}
