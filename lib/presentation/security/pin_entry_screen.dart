import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../transfer_screen/widgets/numeric_keypad_widget.dart';
import './security_view_model.dart';

class PinEntryScreen extends StatelessWidget {
  final bool isSetup;
  final String title;

  const PinEntryScreen({
    super.key,
    this.isSetup = false,
    this.title = 'Enter PIN',
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SecurityViewModel(),
      child: _PinEntryScreenContent(isSetup: isSetup, title: title),
    );
  }
}

class _PinEntryScreenContent extends StatefulWidget {
  final bool isSetup;
  final String title;

  const _PinEntryScreenContent({required this.isSetup, required this.title});

  @override
  State<_PinEntryScreenContent> createState() => _PinEntryScreenContentState();
}

class _PinEntryScreenContentState extends State<_PinEntryScreenContent> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<SecurityViewModel>(context);

    Future<void> handlePinEntry(String digit) async {
      if (_isProcessing) return;

      viewModel.appendDigit(digit);
      if (viewModel.pin.length == 6) {
        setState(() => _isProcessing = true);
        try {
          if (widget.isSetup) {
            if (viewModel.isConfirming &&
                viewModel.pin == viewModel.confirmPin) {
              if (Navigator.canPop(context)) {
                Navigator.pop(context, true);
              } else {
                Navigator.pushReplacementNamed(context, AppRoutes.homeScreen);
              }
            }
          } else {
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
          }
        } finally {
          if (mounted) setState(() => _isProcessing = false);
        }
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            const Icon(
              Icons.lock_outline_rounded,
              size: 64,
              color: AppTheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              widget.title,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
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
