import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import './security_view_model.dart';

class ResetPinScreen extends StatelessWidget {
  const ResetPinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SecurityViewModel(),
      child: const _ResetPinScreenContent(),
    );
  }
}

class _ResetPinScreenContent extends StatelessWidget {
  const _ResetPinScreenContent();

  @override
  Widget build(BuildContext context) {
    return const _ResetPinScreenBody();
  }
}

class _ResetPinScreenBody extends StatefulWidget {
  const _ResetPinScreenBody();

  @override
  State<_ResetPinScreenBody> createState() => _ResetPinScreenBodyState();
}

class _ResetPinScreenBodyState extends State<_ResetPinScreenBody> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<SecurityViewModel>(context);

    void handleReset() async {
      if (!_emailController.text.contains('@')) {
        vm.setError('Enter a valid email');
        return;
      }

      // Simulate OTP send
      vm.clearPin();
      vm.setOtpSent(true);
    }

    void handleVerifyOtp() async {
      if (_otpController.text == '123456') {
        Navigator.pop(context, true);
      } else {
        vm.setError('Invalid OTP. Try 123456');
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Reset PIN',
          style: GoogleFonts.inter(color: AppTheme.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!vm.otpSent) ...[
              Text(
                'Enter your email to receive a reset code',
                style: GoogleFonts.inter(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'Email',
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: handleReset,
                child: const Text('Send Reset Code'),
              ),
            ] else ...[
              Text(
                'Enter the 6-digit code sent to your email',
                style: GoogleFonts.inter(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: 'OTP Code',
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: handleVerifyOtp,
                child: const Text('Verify & Reset'),
              ),
            ],
            if (vm.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  vm.errorMessage!,
                  style: GoogleFonts.inter(color: AppTheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
