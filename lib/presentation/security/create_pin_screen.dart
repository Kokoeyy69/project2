import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../transfer_screen/widgets/numeric_keypad_widget.dart';
import './security_view_model.dart';

class CreatePinScreen extends StatelessWidget {
  const CreatePinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SecurityViewModel(),
      child: const _CreatePinScreenContent(),
    );
  }
}

class _CreatePinScreenContent extends StatelessWidget {
  const _CreatePinScreenContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<SecurityViewModel>(context);

    // Watch for successful PIN creation
    if (viewModel.pin.length == 6 &&
        viewModel.confirmPin.length == 6 &&
        viewModel.pin == viewModel.confirmPin &&
        !viewModel.isLoading &&
        viewModel.errorMessage == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        }
      });
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
              viewModel.isConfirming
                  ? 'Konfirmasi PIN Baru'
                  : 'Buat PIN Transaksi',
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
                viewModel.isConfirming
                    ? 'Masukkan kembali 6 digit PIN Anda untuk konfirmasi'
                    : 'PIN ini akan digunakan untuk setiap transaksi demi keamanan Anda',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 48),
            _buildPinDots(
              viewModel.isConfirming ? viewModel.confirmPin : viewModel.pin,
            ),
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
              displayAmount: '', // Not used for PIN
              onKeyTap: (key) => viewModel.appendDigit(key),
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
