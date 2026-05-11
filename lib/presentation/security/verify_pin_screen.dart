import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../core/services/security_service.dart';

class VerifyPinScreen extends StatefulWidget {
  final String? title;
  final VoidCallback? onSuccess;

  const VerifyPinScreen({
    super.key,
    this.title,
    this.onSuccess,
  });

  @override
  State<VerifyPinScreen> createState() => _VerifyPinScreenState();
}

class _VerifyPinScreenState extends State<VerifyPinScreen> {
  String _pin = '';
  bool _isLoading = false;
  String? _error;
  int _lockoutSeconds = 0;

  @override
  void initState() {
    super.initState();
    _checkLockout();
  }

  Future<void> _checkLockout() async {
    if (await SecurityService().isLockedOut()) {
      final seconds = await SecurityService().getRemainingLockoutSeconds();
      setState(() {
        _lockoutSeconds = seconds;
      });
    }
  }

  void _onDigitPressed(String digit) {
    if (_isLoading || _lockoutSeconds > 0) return;

    setState(() {
      _error = null;
      if (_pin.length < 6) {
        _pin += digit;
      }
    });

    if (_pin.length == 6) {
      _verifyPin();
    }
  }

  void _onBackspacePressed() {
    if (_isLoading || _lockoutSeconds > 0) return;

    setState(() {
      _error = null;
      if (_pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
      }
    });
  }

  Future<void> _verifyPin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await SecurityService().authenticateWithPin(_pin);

      if (!mounted) return;

      if (result.success) {
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else {
          Navigator.pop(context, true);
        }
      } else {
        setState(() {
          _error = result.error ?? 'PIN salah';
          _isLoading = false;
          _pin = '';
        });

        // Check if now locked out
        if (await SecurityService().isLockedOut()) {
          final seconds = await SecurityService().getRemainingLockoutSeconds();
          setState(() {
            _lockoutSeconds = seconds;
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Terjadi kesalahan. Silakan coba lagi.';
        _isLoading = false;
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          widget.title ?? 'Verifikasi PIN',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _lockoutSeconds > 0
                      ? AppTheme.errorMuted
                      : AppTheme.primaryMuted,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _lockoutSeconds > 0
                      ? Icons.lock_outline
                      : Icons.fingerprint,
                  size: 40,
                  color: _lockoutSeconds > 0
                      ? AppTheme.error
                      : AppTheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              // Title
              Text(
                _lockoutSeconds > 0
                    ? 'Terlalu Banyak Percobaan'
                    : 'Masukkan PIN Transaksi',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _lockoutSeconds > 0
                    ? 'Coba lagi dalam $_lockoutSeconds detik'
                    : 'Konfirmasikan PIN Anda untuk melanjutkan',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.errorMuted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  final isFilled = index < _pin.length;
                  final isCurrent = index == _pin.length;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isFilled
                          ? AppTheme.primary
                          : isCurrent
                              ? AppTheme.primary.withAlpha(40)
                              : AppTheme.glassBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrent
                            ? AppTheme.primary
                            : AppTheme.glassBorder,
                        width: isCurrent ? 2 : 0.5,
                      ),
                    ),
                    child: Center(
                      child: isFilled
                          ? Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 40),
              // Keypad
              Expanded(
                child: Column(
                  children: [
                    for (var row = 0; row < 3; row++)
                      Expanded(
                        child: Row(
                          children: [
                            for (var col = 0; col < 3; col++)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: _buildKeypadButton(
                                    '${row * 3 + col + 1}',
                                    () => _onDigitPressed('${row * 3 + col + 1}'),
                                    enabled: _lockoutSeconds == 0,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    // Bottom row: empty, 0, backspace
                    Expanded(
                      child: Row(
                        children: [
                          const Expanded(child: SizedBox()),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: _buildKeypadButton(
                                '0',
                                () => _onDigitPressed('0'),
                                enabled: _lockoutSeconds == 0,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: _buildKeypadButton(
                                null,
                                _onBackspacePressed,
                                icon: Icons.backspace_outlined,
                                enabled: _lockoutSeconds == 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadButton(
    String? label,
    VoidCallback onPressed, {
    IconData? icon,
    bool enabled = true,
  }) {
    return Material(
      color: enabled ? AppTheme.glassBackground : AppTheme.glassBackground.withAlpha(100),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? onPressed : null,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.glassBorder, width: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: label != null
                ? Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: enabled ? AppTheme.textPrimary : AppTheme.textMuted,
                    ),
                  )
                : Icon(
                    icon,
                    size: 28,
                    color: enabled ? AppTheme.textPrimary : AppTheme.textMuted,
                  ),
          ),
        ),
      ),
    );
  }
}