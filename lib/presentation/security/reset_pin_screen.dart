import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class ResetPinScreen extends StatefulWidget {
  const ResetPinScreen({super.key});

  @override
  State<ResetPinScreen> createState() => _ResetPinScreenState();
}

class _ResetPinScreenState extends State<ResetPinScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _verified = false;
  String? _error;

  void _sendOtp() {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      setState(() => _error = 'Enter a valid email');
      return;
    }
    setState(() {
      _otpSent = true;
      _error = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP sent! Use 123456 for demo'), backgroundColor: AppTheme.success),
    );
  }

  void _verifyOtp() {
    if (_otpController.text == '123456') {
      setState(() {
        _verified = true;
        _error = null;
      });
    } else {
      setState(() => _error = 'Invalid OTP. Try 123456');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Reset PIN', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Forgot your PIN?',
              style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'We\'ll send a one-time code to your email to verify your identity.',
              style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 32),
            if (!_verified) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: TextField(
                    controller: _emailController,
                    enabled: !_otpSent,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.inter(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Email address',
                      hintStyle: const TextStyle(color: AppTheme.textMuted),
                      filled: true,
                      fillColor: AppTheme.glassBackground,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                  ),
                ),
              ),
              if (_otpSent) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      style: GoogleFonts.inter(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Enter OTP',
                        hintStyle: const TextStyle(color: AppTheme.textMuted),
                        filled: true,
                        fillColor: AppTheme.glassBackground,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        counterText: '',
                      ),
                    ),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: GoogleFonts.inter(color: AppTheme.error, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _otpSent ? _verifyOtp : _sendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    _otpSent ? 'Verify OTP' : 'Send OTP',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
            ] else ...[
              Text(
                'Create a new PIN',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 16),
              Navigator(
                onGenerateRoute: (_) => MaterialPageRoute(
                  builder: (_) => _buildPinSetup(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPinSetup() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              backgroundColor: AppTheme.surface,
              title: Text('Reset Complete', style: GoogleFonts.inter(color: AppTheme.textPrimary)),
              content: Text('Your PIN has been reset. Please set a new PIN.', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/pin-setup');
                  },
                  child: const Text('Continue', style: TextStyle(color: AppTheme.primary)),
                ),
              ],
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text('Continue to PIN Setup', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }
}
